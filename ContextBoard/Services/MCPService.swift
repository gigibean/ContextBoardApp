import Foundation

/// Claude CLI를 통해 MCP (Jira 등)에서 티켓 컨텍스트를 가져오는 서비스입니다.
actor MCPService {

    // MARK: - Types

    struct FetchResult: Codable {
        let ticketKey: String
        let summary: String
        let status: String
        let assignee: String?
        let relatedURLs: [RelatedURL]

        struct RelatedURL: Codable {
            let label: String
            let url: String
            let type: String
        }
    }

    enum MCPError: LocalizedError {
        case cliNotFound
        case fetchFailed(String)
        case parseFailed(String)
        case timeout

        var errorDescription: String? {
            switch self {
            case .cliNotFound:
                return "Claude CLI를 찾을 수 없습니다. /usr/local/bin/claude 경로를 확인하세요."
            case .fetchFailed(let detail):
                return "Jira 데이터 가져오기 실패: \(detail)"
            case .parseFailed(let detail):
                return "응답 파싱 실패: \(detail)"
            case .timeout:
                return "요청이 시간 초과되었습니다. 다시 시도해주세요."
            }
        }
    }

    // MARK: - Properties

    private let claudePath: String
    private let processRunner = ProcessRunner()

    /// JSON 스키마 — Claude CLI가 구조화된 응답을 반환하도록 강제합니다.
    private let jsonSchema = #"{"type":"object","properties":{"ticketKey":{"type":"string"},"summary":{"type":"string"},"status":{"type":"string"},"assignee":{"type":["string","null"]},"relatedURLs":{"type":"array","items":{"type":"object","properties":{"label":{"type":"string"},"url":{"type":"string"},"type":{"type":"string","enum":["jira","pr","figma","confluence","other"]}},"required":["label","url","type"]}}},"required":["ticketKey","summary","status","relatedURLs"]}"#

    // MARK: - Init

    private let jiraSiteURL: String

    init(claudePath: String = "/usr/local/bin/claude", jiraSiteURL: String = "") {
        self.claudePath = claudePath
        self.jiraSiteURL = jiraSiteURL
    }

    // MARK: - Public API

    /// Claude CLI가 설치되어 있는지 확인합니다.
    var isCLIAvailable: Bool {
        FileManager.default.fileExists(atPath: claudePath)
    }

    /// 티켓 키로 Jira에서 컨텍스트를 가져옵니다.
    /// - Parameter ticketKey: Jira 티켓 키 (예: "AIR-1234")
    /// - Returns: 가져온 컨텍스트 정보
    func fetchContext(ticketKey: String) async throws -> FetchResult {
        guard isCLIAvailable else {
            throw MCPError.cliNotFound
        }

        let prompt = buildPrompt(for: ticketKey)

        let output: String
        do {
            output = try await processRunner.run(
                executable: claudePath,
                arguments: [
                    "--print",
                    "--model", "claude-haiku-4-5-20251001",
                    "--max-budget-usd", "1.00",
                    "--allowedTools", "mcp__claude_ai_Atlassian_Rovo__getJiraIssue", "mcp__claude_ai_Atlassian_Rovo__searchJiraIssuesUsingJql", "mcp__claude_ai_Atlassian_Rovo__search", "mcp__claude_ai_Atlassian_Rovo__atlassianUserInfo", "mcp__claude_ai_Atlassian_Rovo__lookupJiraAccountId",
                    "-p", prompt
                ],
                timeout: 90
            )
        } catch let error as ProcessRunner.ProcessError {
            switch error {
            case .timeout:
                throw MCPError.timeout
            default:
                throw MCPError.fetchFailed(error.localizedDescription)
            }
        }

        return try parseResponse(output)
    }

    // MARK: - Bulk Fetch

    struct BulkFetchResult: Codable {
        let tickets: [TicketSummary]

        struct TicketSummary: Codable {
            let ticketKey: String
            let summary: String
            let status: String
            let assignee: String?
            let labels: [String]
        }
    }

    /// 현재 사용자에게 할당된 미완료 티켓을 일괄 가져옵니다.
    func fetchMyTickets() async throws -> BulkFetchResult {
        guard isCLIAvailable else {
            throw MCPError.cliNotFound
        }

        let prompt = buildBulkPrompt()

        let output: String
        do {
            output = try await processRunner.run(
                executable: claudePath,
                arguments: [
                    "--print",
                    "--model", "claude-haiku-4-5-20251001",
                    "--max-budget-usd", "1.00",
                    "--allowedTools", "mcp__claude_ai_Atlassian_Rovo__getJiraIssue", "mcp__claude_ai_Atlassian_Rovo__searchJiraIssuesUsingJql", "mcp__claude_ai_Atlassian_Rovo__search", "mcp__claude_ai_Atlassian_Rovo__atlassianUserInfo", "mcp__claude_ai_Atlassian_Rovo__lookupJiraAccountId",
                    "-p", prompt
                ],
                timeout: 120
            )
        } catch let error as ProcessRunner.ProcessError {
            switch error {
            case .timeout:
                throw MCPError.timeout
            default:
                throw MCPError.fetchFailed(error.localizedDescription)
            }
        }

        return try parseBulkResponse(output)
    }

    private func buildBulkPrompt() -> String {
        """
        Jira에서 나에게 할당된 미완료 티켓을 모두 검색해서 아래 JSON 형식으로만 응답해. 설명이나 마크다운 없이 순수 JSON만 출력해.

        {"tickets":[{"ticketKey":"키","summary":"요약","status":"상태","assignee":"담당자","labels":["라벨1","라벨2"]}]}

        규칙:
        - Jira 사이트: \(jiraSiteURL)
        - JQL: assignee = currentUser() AND status NOT IN (Done, Closed, 완료) ORDER BY updated DESC
        - 각 티켓의 labels 필드를 그대로 포함 (없으면 빈 배열)
        - 최대 20개까지만
        - 출력은 반드시 { 로 시작하고 } 로 끝나야 함
        """
    }

    private func parseBulkResponse(_ output: String) throws -> BulkFetchResult {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

        let jsonString: String
        if let jsonStart = trimmed.range(of: "{"),
           let jsonEnd = trimmed.range(of: "}", options: .backwards) {
            jsonString = String(trimmed[jsonStart.lowerBound...jsonEnd.upperBound])
        } else {
            jsonString = trimmed
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw MCPError.parseFailed("UTF-8 인코딩 실패")
        }

        do {
            return try JSONDecoder().decode(BulkFetchResult.self, from: data)
        } catch {
            let preview = String(jsonString.prefix(300))
            throw MCPError.parseFailed("JSON 디코딩 실패: \(error.localizedDescription)\n응답: \(preview)")
        }
    }

    /// FetchResult를 ContextItem 배열로 변환합니다.
    func convertToContextItems(_ result: FetchResult) -> [ContextItem] {
        var items: [ContextItem] = []

        // Jira 티켓 자체를 첫 번째 아이템으로 추가
        let jiraItem = ContextItem(
            type: .webURL,
            label: "\(result.ticketKey) - \(result.summary)",
            urlString: jiraSiteURL.isEmpty ? nil : "https://\(jiraSiteURL)/browse/\(result.ticketKey)",
            sortOrder: 0
        )
        items.append(jiraItem)

        // 관련 URL들을 아이템으로 변환
        for (index, relatedURL) in result.relatedURLs.enumerated() {
            let itemType: ContextItemType = relatedURL.url.contains("figma.com") ? .deepLink : .webURL
            let item = ContextItem(
                type: itemType,
                label: relatedURL.label,
                urlString: relatedURL.url,
                sortOrder: index + 1
            )
            items.append(item)
        }

        return items
    }

    // MARK: - Private

    private func buildPrompt(for ticketKey: String) -> String {
        """
        Jira 티켓 \(ticketKey)를 검색해서 아래 JSON 형식으로만 응답해. 설명이나 마크다운 없이 순수 JSON만 출력해.

        {"ticketKey":"티켓키","summary":"요약","status":"상태","assignee":"담당자 또는 null","relatedURLs":[{"label":"설명","url":"전체URL","type":"jira|pr|figma|confluence|other"}]}

        규칙:
        - Jira 사이트: \(jiraSiteURL)
        - relatedURLs에 티켓 자체 URL도 포함 (type: "jira")
        - 설명/댓글에서 GitHub PR, Figma, Confluence 링크를 찾아서 포함
        - URL은 반드시 https://로 시작하는 전체 URL
        - 출력은 반드시 { 로 시작하고 } 로 끝나야 함
        """
    }

    private func parseResponse(_ output: String) throws -> FetchResult {
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)

        // --json-schema 사용 시 출력은 순수 JSON
        // 혹시 텍스트가 섞여있으면 JSON 객체 부분만 추출
        let jsonString: String
        if let jsonStart = trimmed.range(of: "{"),
           let jsonEnd = trimmed.range(of: "}", options: .backwards) {
            jsonString = String(trimmed[jsonStart.lowerBound...jsonEnd.upperBound])
        } else {
            jsonString = trimmed
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw MCPError.parseFailed("UTF-8 인코딩 실패")
        }

        do {
            return try JSONDecoder().decode(FetchResult.self, from: data)
        } catch {
            let preview = String(jsonString.prefix(300))
            throw MCPError.parseFailed("JSON 디코딩 실패: \(error.localizedDescription)\n응답: \(preview)")
        }
    }
}
