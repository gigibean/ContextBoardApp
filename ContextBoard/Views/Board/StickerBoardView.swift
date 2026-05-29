import SwiftUI
import SwiftData

/// 메인 스티커 보드 뷰 — 드래그 가능한 스티커들이 배치된 캔버스입니다.
struct StickerBoardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkContext.createdAt) private var contexts: [WorkContext]
    @Query private var allSettings: [BoardSettings]

    @State private var viewModel = BoardViewModel()
    @State private var selectedContextForPopover: WorkContext?
    @State private var showDeleteConfirm = false
    @State private var contextToDelete: WorkContext?
    @State private var contextToTerminate: WorkContext?
    @State private var showTerminateConfirm = false
    @State private var isShowingBulkImport = false
    @State private var searchText = ""

    private var settings: BoardSettings? { allSettings.first }

    private var filteredContexts: [WorkContext] {
        guard !searchText.isEmpty else { return contexts }
        let query = searchText.lowercased()
        return contexts.filter {
            $0.ticketKey.lowercased().contains(query)
            || $0.title.lowercased().contains(query)
            || $0.tags.contains { $0.lowercased().contains(query) }
        }
    }

    var body: some View {
        ZStack {
            // 배경 레이어
            BoardBackgroundView(settings: settings)
                .ignoresSafeArea()

            // 스티커 레이어 (고정된 스티커가 위에 표시)
            ForEach(filteredContexts) { context in
                stickerNode(for: context)
                    .zIndex(context.isPinned == true ? 1 : 0)
            }

            // 빈 상태
            if contexts.isEmpty {
                emptyStateView
            }
        }
        .frame(
            minWidth: 500, idealWidth: 600, maxWidth: .infinity,
            minHeight: 350, idealHeight: 450, maxHeight: .infinity
        )
        .overlay(alignment: .topTrailing) {
            toolbarButtons
        }
        .sheet(isPresented: $viewModel.isShowingCreateSheet) {
            ContextEditorView(
                context: nil,
                onSave: { _ in
                    viewModel.isShowingCreateSheet = false
                },
                onCancel: {
                    viewModel.isShowingCreateSheet = false
                }
            )
        }
        .sheet(item: $viewModel.editingContext) { context in
            ContextEditorView(
                context: context,
                onSave: { _ in
                    viewModel.editingContext = nil
                },
                onCancel: {
                    viewModel.editingContext = nil
                }
            )
        }
        .alert("컨텍스트 삭제", isPresented: $showDeleteConfirm) {
            Button("삭제", role: .destructive) {
                if let context = contextToDelete {
                    viewModel.deleteContext(context, from: modelContext)
                }
                contextToDelete = nil
            }
            Button("취소", role: .cancel) {
                contextToDelete = nil
            }
        } message: {
            Text("'\(contextToDelete?.displayLabel ?? "")'을(를) 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.")
        }
        .alert("관련 앱 종료", isPresented: $showTerminateConfirm) {
            Button("종료", role: .destructive) {
                if let context = contextToTerminate {
                    viewModel.terminateContext(context)
                }
                contextToTerminate = nil
            }
            Button("취소", role: .cancel) {
                contextToTerminate = nil
            }
        } message: {
            Text("'\(contextToTerminate?.displayLabel ?? "")'에 연결된 앱들을 종료하시겠습니까?")
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            VStack(spacing: 0) {
                SettingsView()
                Divider()
                HStack {
                    Spacer()
                    Button("닫기") {
                        viewModel.isShowingSettings = false
                    }
                    .keyboardShortcut(.escape)
                    .padding(12)
                }
            }
            .frame(width: 450, height: 400)
        }
        .sheet(isPresented: $isShowingBulkImport) {
            BulkImportView {
                isShowingBulkImport = false
            }
        }
        .alert("오류", isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.dismissError() } }
        )) {
            Button("확인") { viewModel.dismissError() }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Sticker Node

    @ViewBuilder
    private func stickerNode(for context: WorkContext) -> some View {
        StickerView(
            context: context,
            onTap: {
                viewModel.toggleContext(context)
            },
            onDoubleTap: {
                viewModel.editingContext = context
            }
        )
        .position(x: context.positionX, y: context.positionY)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let pos = clampPosition(value.location)
                    context.positionX = pos.x
                    context.positionY = pos.y
                }
                .onEnded { value in
                    let pos = snapToGrid(clampPosition(value.location))
                    withAnimation(.spring(duration: 0.2)) {
                        viewModel.updatePosition(context, to: pos)
                    }
                    try? modelContext.save()
                }
        )
        .contextMenu {
            Button {
                viewModel.toggleContext(context)
            } label: {
                Label(
                    context.isActive ? "숨기기" : "모두 열기",
                    systemImage: context.isActive ? "eye.slash" : "arrow.up.right.square"
                )
            }

            if context.isActive {
                Button(role: .destructive) {
                    contextToTerminate = context
                    showTerminateConfirm = true
                } label: {
                    Label("관련 앱 종료", systemImage: "xmark.app")
                }
            }

            Divider()

            Button {
                context.isPinned = !(context.isPinned ?? false)
                try? modelContext.save()
            } label: {
                Label(
                    context.isPinned == true ? "고정 해제" : "고정",
                    systemImage: context.isPinned == true ? "pin.slash" : "pin"
                )
            }

            Button {
                viewModel.editingContext = context
            } label: {
                Label("편집", systemImage: "pencil")
            }

            Button {
                viewModel.duplicateContext(context, in: modelContext)
            } label: {
                Label("복제", systemImage: "doc.on.doc")
            }

            Button(role: .destructive) {
                contextToDelete = context
                showDeleteConfirm = true
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
    }

    // MARK: - Position Helpers

    private let stickerPadding: CGFloat = 40
    private let gridSize: CGFloat = 60

    /// 스티커가 보드 밖으로 나가지 않도록 좌표를 제한합니다.
    private func clampPosition(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: max(stickerPadding, point.x),
            y: max(stickerPadding, point.y)
        )
    }

    /// 그리드 스냅이 활성화되어 있으면 가장 가까운 그리드 포인트로 스냅합니다.
    private func snapToGrid(_ point: CGPoint) -> CGPoint {
        guard settings?.gridSnapEnabled == true else { return point }
        return CGPoint(
            x: (point.x / gridSize).rounded() * gridSize,
            y: (point.y / gridSize).rounded() * gridSize
        )
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("컨텍스트가 없습니다")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Text("'+' 버튼을 눌러 첫 번째 작업 컨텍스트를 만들어보세요")
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(.tertiary)

            PastelButton("새 컨텍스트 만들기", icon: "plus", color: "#FFB6C1") {
                viewModel.isShowingCreateSheet = true
            }
        }
    }

    // MARK: - Toolbar

    private var toolbarButtons: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 11))
                TextField("검색", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
            )
            .frame(width: 140)

            PastelButton("", icon: "tray.and.arrow.down", color: "#B0E0E6") {
                isShowingBulkImport = true
            }
            .help("내 티켓 일괄 가져오기")

            PastelButton("", icon: "plus", color: "#FFB6C1") {
                viewModel.isShowingCreateSheet = true
            }

            PastelButton("", icon: "gearshape", color: "#E6E6FA") {
                viewModel.isShowingSettings = true
            }
        }
        .padding(12)
    }
}

#Preview {
    StickerBoardView()
        .modelContainer(for: [WorkContext.self, ContextItem.self, BoardSettings.self], inMemory: true)
}
