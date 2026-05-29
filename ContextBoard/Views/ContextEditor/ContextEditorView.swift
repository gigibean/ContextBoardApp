import SwiftUI
import SwiftData

/// 컨텍스트를 생성하거나 편집하는 시트 뷰입니다.
struct ContextEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [BoardSettings]

    let context: WorkContext?
    let onSave: (WorkContext) -> Void
    let onCancel: () -> Void

    @State private var viewModel = ContextEditorViewModel()
    @State private var mcpViewModel = MCPViewModel()

    private var jiraSiteURL: String { allSettings.first?.jiraSiteURL ?? "" }
    @State private var isShowingMCPFetch = false
    @State private var isShowingIconPicker = false
    @State private var saveError: String?

    private var isEditing: Bool { context != nil }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Divider()

            // 폼 콘텐츠
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 기본 정보
                    basicInfoSection

                    Divider()

                    // 아이콘 & 색상
                    appearanceSection

                    Divider()

                    // 아이템 목록
                    itemsSection

                    // 메모
                    notesSection
                }
                .padding(20)
            }

            Divider()

            // 하단 버튼
            footer
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .frame(width: 520, height: 600)
        .onAppear {
            if let context {
                viewModel.load(from: context)
            }
            mcpViewModel.jiraSiteURL = jiraSiteURL
        }
        .sheet(isPresented: $isShowingMCPFetch) {
            MCPFetchView(
                ticketKey: viewModel.ticketKey,
                mcpViewModel: mcpViewModel,
                onConfirm: { items in
                    viewModel.items.append(contentsOf: items)
                    if viewModel.title.isEmpty {
                        viewModel.title = mcpViewModel.ticketSummary
                    }
                    isShowingMCPFetch = false
                },
                onCancel: {
                    isShowingMCPFetch = false
                }
            )
        }
        .sheet(isPresented: $isShowingIconPicker) {
            IconPickerView(
                selectedIconType: $viewModel.iconType,
                selectedSFSymbol: $viewModel.selectedSFSymbol,
                customIconData: $viewModel.customIconData,
                onDone: {
                    isShowingIconPicker = false
                }
            )
        }
        .alert("저장 오류", isPresented: .init(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("확인") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(isEditing ? "컨텍스트 편집" : "새 컨텍스트")
                .font(.system(size: 16, weight: .bold, design: .rounded))

            Spacer()

            if !viewModel.ticketKey.isEmpty {
                PastelButton("Jira에서 가져오기", icon: "arrow.down.circle", color: "#98FF98") {
                    isShowingMCPFetch = true
                }
            }
        }
    }

    // MARK: - Basic Info

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("기본 정보")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("티켓 키")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("예: PROJ-1234", text: $viewModel.ticketKey)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("제목")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("티켓 제목 또는 설명", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("태그 (쉼표 구분)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("예: 항공, 예약, UX", text: $viewModel.tags)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("외관")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                // 아이콘 미리보기
                Button {
                    isShowingIconPicker = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(hex: viewModel.accentColorHex).opacity(0.3))
                            .frame(width: 56, height: 56)

                        Image(systemName: viewModel.selectedSFSymbol)
                            .font(.system(size: 24))
                            .foregroundStyle(Color(hex: viewModel.accentColorHex))
                    }
                }
                .buttonStyle(.plain)
                .help("아이콘 변경")

                // 색상 선택
                VStack(alignment: .leading, spacing: 6) {
                    Text("액센트 색상")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(PastelColors.presets, id: \.hex) { preset in
                                Circle()
                                    .fill(Color(hex: preset.hex))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                viewModel.accentColorHex == preset.hex
                                                    ? Color.primary
                                                    : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .onTapGesture {
                                        viewModel.accentColorHex = preset.hex
                                    }
                                    .help(preset.name)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Items

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("컨텍스트 아이템")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                PastelButton("추가", icon: "plus", color: "#E6E6FA") {
                    viewModel.addItem()
                }
            }

            if viewModel.items.isEmpty {
                Text("아직 아이템이 없습니다. '추가' 버튼이나 'Jira에서 가져오기'로 추가하세요.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach($viewModel.items) { $item in
                    ContextItemRow(item: $item) {
                        if let index = viewModel.items.firstIndex(where: { $0.id == item.id }) {
                            viewModel.items.remove(at: index)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("메모")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            TextEditor(text: $viewModel.notes)
                .font(.system(size: 12))
                .frame(height: 60)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.05))
                        .stroke(Color.gray.opacity(0.2))
                )
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Button("취소") { onCancel() }
                .keyboardShortcut(.escape)

            Spacer()

            PastelButton("저장", icon: "checkmark", color: "#98FF98") {
                save()
            }
            .keyboardShortcut(.return)
            .disabled(!viewModel.isValid)
        }
    }

    // MARK: - Actions

    private func save() {
        let targetContext: WorkContext
        if let existing = context {
            targetContext = existing
        } else {
            targetContext = WorkContext()
            // 기본 위치 랜덤 설정
            targetContext.positionX = Double.random(in: 80...400)
            targetContext.positionY = Double.random(in: 80...350)
            modelContext.insert(targetContext)
        }

        viewModel.save(to: targetContext, in: modelContext)

        do {
            try modelContext.save()
            onSave(targetContext)
        } catch {
            saveError = "저장 실패: \(error.localizedDescription)"
        }
    }
}
