import SwiftUI

/// MCP (Claude CLI) 가져오기 상태를 관리하는 ViewModel입니다.
@MainActor
@Observable
final class MCPViewModel {

    // MARK: - State

    enum FetchState: Equatable {
        case idle
        case fetching
        case success(itemCount: Int)
        case error(String)
    }

    enum ConnectionState: Equatable {
        case untested
        case testing
        case connected(displayName: String?, detectedSiteURL: String?)
        case failed(String)
    }

    var state: FetchState = .idle
    var connectionState: ConnectionState = .untested
    var fetchedItems: [ContextEditorViewModel.EditableItem] = []
    var ticketSummary: String = ""
    var ticketStatus: String = ""
    var ticketAssignee: String?

    // MARK: - Properties

    private var mcpService: MCPService { MCPService(jiraSiteURL: jiraSiteURL) }
    var jiraSiteURL: String = ""

    /// Claude CLI가 사용 가능한지 확인합니다.
    var isCLIAvailable: Bool {
        get async {
            await mcpService.isCLIAvailable
        }
    }

    // MARK: - Actions

    /// 티켓 키로 Jira에서 컨텍스트를 가져옵니다.
    func fetch(ticketKey: String) async {
        let trimmed = ticketKey.trimmingCharacters(in: .whitespaces).uppercased()
        guard !trimmed.isEmpty else {
            state = .error("티켓 키를 입력해주세요.")
            return
        }
        guard trimmed.range(of: #"^[A-Z][A-Z0-9]+-\d+$"#, options: .regularExpression) != nil else {
            state = .error("올바른 티켓 키 형식이 아닙니다. 예: PROJ-1234")
            return
        }

        state = .fetching
        fetchedItems = []

        do {
            let result = try await mcpService.fetchContext(ticketKey: trimmed)
            let contextItems = await mcpService.convertToContextItems(result)

            ticketSummary = result.summary
            ticketStatus = result.status
            ticketAssignee = result.assignee

            fetchedItems = contextItems.map { item in
                ContextEditorViewModel.EditableItem(
                    id: item.id,
                    type: item.type,
                    label: item.label,
                    value: item.urlString ?? item.bundleIdentifier ?? item.filePath ?? "",
                    isEnabled: true
                )
            }

            state = .success(itemCount: fetchedItems.count)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Bulk Fetch

    var bulkTickets: [MCPService.BulkFetchResult.TicketSummary] = []

    /// 현재 사용자에게 할당된 미완료 티켓을 일괄 가져옵니다.
    func fetchMyTickets() async {
        state = .fetching
        bulkTickets = []

        do {
            let result = try await mcpService.fetchMyTickets()
            bulkTickets = result.tickets
            state = .success(itemCount: result.tickets.count)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    // MARK: - Connection Test

    /// Claude CLI + Atlassian Rovo MCP 연결을 테스트하고, Jira 사이트 URL을 자동 감지합니다.
    /// - Returns: 감지된 Jira 사이트 URL (없으면 nil)
    @discardableResult
    func testConnection() async -> String? {
        connectionState = .testing
        let service = MCPService(jiraSiteURL: jiraSiteURL)

        do {
            let result = try await service.testMCPConnection()
            connectionState = .connected(
                displayName: result.displayName,
                detectedSiteURL: result.jiraSiteURL
            )
            return result.jiraSiteURL
        } catch {
            connectionState = .failed(error.localizedDescription)
            return nil
        }
    }

    /// 상태를 초기화합니다.
    func reset() {
        state = .idle
        fetchedItems = []
        bulkTickets = []
        ticketSummary = ""
        ticketStatus = ""
        ticketAssignee = nil
    }
}
