import SwiftUI
import SwiftData

/// 컨텍스트 생성/편집 폼의 상태를 관리하는 ViewModel입니다.
@MainActor
@Observable
final class ContextEditorViewModel {

    // MARK: - Form State

    var ticketKey: String = ""
    var title: String = ""
    var iconType: IconType = .sfSymbol
    var selectedSFSymbol: String = "ticket.fill"
    var customIconData: Data?
    var accentColorHex: String = PastelColors.defaultAccent
    var tags: String = "" // 쉼표 구분 문자열
    var notes: String = ""

    /// 편집할 아이템 목록
    var items: [EditableItem] = []

    /// MCP 가져오기 진행 중 여부
    var isFetchingFromMCP = false

    /// 에러 메시지
    var errorMessage: String?

    // MARK: - Types

    struct EditableItem: Identifiable {
        let id: UUID
        var type: ContextItemType
        var label: String
        var value: String // URL, bundleId, 또는 filePath
        var projectPath: String // 애플리케이션 타입일 때 함께 열 프로젝트 폴더 경로
        var isEnabled: Bool

        init(
            id: UUID = UUID(),
            type: ContextItemType = .webURL,
            label: String = "",
            value: String = "",
            projectPath: String = "",
            isEnabled: Bool = true
        ) {
            self.id = id
            self.type = type
            self.label = label
            self.value = value
            self.projectPath = projectPath
            self.isEnabled = isEnabled
        }
    }

    // MARK: - Init from existing context

    /// 기존 컨텍스트로부터 폼을 초기화합니다.
    func load(from context: WorkContext) {
        ticketKey = context.ticketKey
        title = context.title
        iconType = context.iconType
        selectedSFSymbol = context.defaultIconName ?? "ticket.fill"
        customIconData = context.customIconData
        accentColorHex = context.accentColorHex
        tags = context.tags.joined(separator: ", ")
        notes = context.notes ?? ""

        items = context.items
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { item in
                EditableItem(
                    id: item.id,
                    type: item.type,
                    label: item.label,
                    value: item.urlString ?? item.bundleIdentifier ?? item.filePath ?? "",
                    projectPath: item.type == .application ? (item.filePath ?? "") : "",
                    isEnabled: item.isEnabled
                )
            }
    }

    /// 폼 데이터를 WorkContext에 저장합니다.
    func save(to context: WorkContext, in modelContext: ModelContext) {
        context.ticketKey = ticketKey
        context.title = title
        context.iconType = iconType
        context.defaultIconName = selectedSFSymbol
        context.customIconData = customIconData
        context.accentColorHex = accentColorHex
        context.tags = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        context.notes = notes.isEmpty ? nil : notes
        context.updatedAt = Date()

        // 기존 아이템 제거 후 새로 생성
        for existingItem in context.items {
            modelContext.delete(existingItem)
        }

        for (index, editableItem) in items.enumerated() {
            let item = ContextItem(
                id: editableItem.id,
                type: editableItem.type,
                label: editableItem.label,
                sortOrder: index,
                isEnabled: editableItem.isEnabled,
                context: context
            )

            switch editableItem.type {
            case .webURL, .deepLink:
                item.urlString = editableItem.value
            case .application:
                item.bundleIdentifier = editableItem.value
                if !editableItem.projectPath.isEmpty {
                    item.filePath = editableItem.projectPath
                }
            case .file, .directory:
                item.filePath = editableItem.value
            }

            modelContext.insert(item)
        }
    }

    // MARK: - Item Management

    func addItem() {
        items.append(EditableItem())
    }

    func removeItem(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
    }

    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Validation

    var isValid: Bool {
        !ticketKey.isEmpty || !title.isEmpty
    }
}
