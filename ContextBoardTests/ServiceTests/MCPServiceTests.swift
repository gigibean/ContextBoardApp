import Testing
import Foundation
@testable import ContextBoard

@Suite("MCPService 테스트")
struct MCPServiceTests {

    @Test("CLI 경로 감지")
    func testCLIAvailability() async {
        // 실제 환경에서 Claude CLI가 설치되어 있는지 확인
        let service = MCPService()
        let available = await service.isCLIAvailable

        // CI 환경에서는 CLI가 없을 수 있으므로 단순 실행 확인만
        // 실제 결과는 환경에 따라 다름
        _ = available // 타입 확인만
    }

    @Test("존재하지 않는 CLI 경로는 에러 발생")
    func testInvalidCLIPath() async {
        let service = MCPService(claudePath: "/nonexistent/path/claude")
        let available = await service.isCLIAvailable
        #expect(!available)

        do {
            _ = try await service.fetchContext(ticketKey: "TEST-001")
            #expect(Bool(false), "에러가 발생해야 합니다")
        } catch {
            // MCPError.cliNotFound가 발생해야 함
            #expect(error is MCPService.MCPError)
        }
    }

    @Test("FetchResult를 ContextItem으로 변환")
    func testConvertToContextItems() async {
        let service = MCPService()
        let result = MCPService.FetchResult(
            ticketKey: "PROJ-1234",
            summary: "예약 플로우 개선",
            status: "In Progress",
            assignee: "miya",
            relatedURLs: [
                .init(label: "PR #123", url: "https://github.com/example-org/example-repo/pull/123", type: "pr"),
                .init(label: "Figma 디자인", url: "https://figma.com/file/abc123", type: "figma"),
            ]
        )

        let items = await service.convertToContextItems(result)

        // Jira 티켓 자체 + 관련 URL 2개 = 3개
        #expect(items.count == 3)
        #expect(items[0].urlString?.contains("PROJ-1234") == true)
        #expect(items[1].urlString?.contains("github.com") == true)
        #expect(items[2].type == .deepLink) // Figma는 deepLink
    }
}
