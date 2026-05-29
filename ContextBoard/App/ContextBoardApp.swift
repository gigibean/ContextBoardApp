import SwiftUI
import SwiftData

/// ContextBoard 앱 진입점
/// 메뉴 바에 아이콘을 표시하고, 클릭 시 플로팅 스티커 보드를 토글합니다.
@main
struct ContextBoardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let modelContainer: ModelContainer

    @State private var isPanelVisible = false

    init() {
        do {
            let schema = Schema([
                WorkContext.self,
                ContextItem.self,
                BoardSettings.self,
            ])
            let config = ModelConfiguration(
                "ContextBoard",
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            print("[ContextBoard] ModelContainer 초기화 성공")
        } catch {
            fatalError("[ContextBoard] SwiftData ModelContainer 생성 실패: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        // 메뉴 바 아이콘
        MenuBarExtra("ContextBoard", systemImage: "cube.fill") {
            menuBarContent
        }
    }

    // MARK: - Menu Bar Content

    @ViewBuilder
    private var menuBarContent: some View {
        Button {
            toggleBoard()
        } label: {
            Label(
                isPanelVisible ? "보드 숨기기" : "보드 열기",
                systemImage: isPanelVisible ? "eye.slash" : "eye"
            )
        }
        .keyboardShortcut("b", modifiers: [.command, .shift])

        Divider()

        // 빠른 컨텍스트 토글 (최근 5개)
        quickContextSection

        Divider()

        Button("설정...") {
            appDelegate.openSettings(modelContainer: modelContainer)
        }
        .keyboardShortcut(",")

        Button("종료") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    @ViewBuilder
    private var quickContextSection: some View {
        let fetchDescriptor = FetchDescriptor<WorkContext>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        if let contexts = try? modelContainer.mainContext.fetch(fetchDescriptor) {
            if contexts.isEmpty {
                Text("컨텍스트 없음")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(contexts.prefix(5)) { context in
                    Button {
                        Task { @MainActor in
                            let launcher = ContextLauncher()
                            try? await launcher.toggleContext(context)
                        }
                    } label: {
                        HStack {
                            Image(systemName: context.isActive ? "circle.fill" : "circle")
                                .font(.system(size: 8))
                                .foregroundStyle(context.isActive ? .green : .gray)
                            Text(context.displayLabel)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Panel Toggle

    private func toggleBoard() {
        if appDelegate.isPanelVisible {
            appDelegate.togglePanel()
            isPanelVisible = false
        } else {
            let boardView = StickerBoardView()
                .modelContainer(modelContainer)

            let _ = appDelegate.createPanel(content: boardView)
            appDelegate.togglePanel()
            isPanelVisible = true
        }
    }
}
