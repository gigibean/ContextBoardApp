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

    var state: FetchState = .idle
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
        guard !ticketKey.isEmpty else {
            state = .error("티켓 키를 입력해주세요.")
            return
        }

        state = .fetching
        fetchedItems = []

        do {
            let result = try await mcpService.fetchContext(ticketKey: ticketKey)
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
