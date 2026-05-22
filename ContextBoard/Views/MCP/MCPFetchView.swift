import SwiftUI

/// Jira에서 컨텍스트를 가져오는 UI 시트입니다.
struct MCPFetchView: View {
    let ticketKey: String
    @Bindable var mcpViewModel: MCPViewModel
    let onConfirm: ([ContextEditorViewModel.EditableItem]) -> Void
    let onCancel: () -> Void

    @State private var editableTicketKey: String = ""
    @State private var selectedItems: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundStyle(Color(hex: "#98FF98"))
                Text("Jira에서 컨텍스트 가져오기")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
            }
            .padding(20)

            Divider()

            // 콘텐츠
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 티켓 키 입력
                    HStack {
                        TextField("티켓 키 (예: AIR-1234)", text: $editableTicketKey)
                            .textFieldStyle(.roundedBorder)

                        PastelButton("가져오기", icon: "magnifyingglass", color: "#98FF98") {
                            Task {
                                await mcpViewModel.fetch(ticketKey: editableTicketKey)
                                // 모든 아이템 기본 선택
                                selectedItems = Set(mcpViewModel.fetchedItems.map(\.id))
                            }
                        }
                        .disabled(editableTicketKey.isEmpty || mcpViewModel.state == .fetching)
                    }

                    // 상태 표시
                    stateView

                    // 결과 목록
                    if !mcpViewModel.fetchedItems.isEmpty {
                        resultsList
                    }
                }
                .padding(20)
            }

            Divider()

            // 하단 버튼
            HStack {
                Button("취소") { onCancel() }
                    .keyboardShortcut(.escape)

                Spacer()

                if !mcpViewModel.fetchedItems.isEmpty {
                    Text("\(selectedItems.count)개 선택됨")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    PastelButton("선택한 아이템 추가", icon: "plus.circle", color: "#98FF98") {
                        let selectedItemsList = mcpViewModel.fetchedItems.filter {
                            selectedItems.contains($0.id)
                        }
                        onConfirm(selectedItemsList)
                    }
                    .disabled(selectedItems.isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 500, height: 450)
        .onAppear {
            editableTicketKey = ticketKey
        }
    }

    // MARK: - State View

    @ViewBuilder
    private var stateView: some View {
        switch mcpViewModel.state {
        case .idle:
            EmptyView()

        case .fetching:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Claude CLI를 통해 Jira에서 정보를 가져오는 중...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.05))
            )

        case .success(let count):
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("\(count)개의 관련 아이템을 찾았습니다")
                        .font(.system(size: 12, weight: .medium))
                }

                if !mcpViewModel.ticketSummary.isEmpty {
                    Text("요약: \(mcpViewModel.ticketSummary)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !mcpViewModel.ticketStatus.isEmpty {
                    Text("상태: \(mcpViewModel.ticketStatus)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let assignee = mcpViewModel.ticketAssignee {
                    Text("담당자: \(assignee)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.05))
            )

        case .error(let message):
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.orange.opacity(0.05))
            )
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("가져온 아이템")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("모두 선택") {
                    selectedItems = Set(mcpViewModel.fetchedItems.map(\.id))
                }
                .font(.caption)

                Button("모두 해제") {
                    selectedItems.removeAll()
                }
                .font(.caption)
            }

            ForEach(mcpViewModel.fetchedItems, id: \.id) { item in
                HStack(spacing: 8) {
                    // 체크박스
                    Image(systemName: selectedItems.contains(item.id)
                          ? "checkmark.circle.fill"
                          : "circle")
                    .foregroundStyle(selectedItems.contains(item.id) ? .green : .secondary)
                    .onTapGesture {
                        if selectedItems.contains(item.id) {
                            selectedItems.remove(item.id)
                        } else {
                            selectedItems.insert(item.id)
                        }
                    }

                    // 타입 아이콘
                    Image(systemName: item.type.iconName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)

                    // 라벨
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.label)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Text(item.value)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedItems.contains(item.id)
                              ? Color.green.opacity(0.05)
                              : Color.gray.opacity(0.03))
                )
            }
        }
    }
}
