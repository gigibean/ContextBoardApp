import SwiftUI
import SwiftData

/// 나에게 할당된 Jira 티켓을 일괄 가져와 스티커로 만드는 뷰입니다.
struct BulkImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkContext.createdAt) private var existingContexts: [WorkContext]

    @Query private var allSettings: [BoardSettings]
    @State private var mcpViewModel = MCPViewModel()
    @State private var selectedKeys: Set<String> = []

    let onDone: () -> Void

    private var jiraSiteURL: String { allSettings.first?.jiraSiteURL ?? "" }

    /// 이미 보드에 존재하는 티켓 키 집합
    private var existingKeys: Set<String> {
        Set(existingContexts.map(\.ticketKey))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Image(systemName: "tray.and.arrow.down.fill")
                    .foregroundStyle(Color(hex: "#B0E0E6"))
                Text("내 티켓 일괄 가져오기")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
            }
            .padding(20)

            Divider()

            // 콘텐츠
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    stateView

                    if !mcpViewModel.bulkTickets.isEmpty {
                        ticketsList
                    }
                }
                .padding(20)
            }

            Divider()

            // 하단 버튼
            HStack {
                Button("닫기") { onDone() }
                    .keyboardShortcut(.escape)

                Spacer()

                if mcpViewModel.state == .idle {
                    PastelButton("내 티켓 검색", icon: "magnifyingglass", color: "#B0E0E6") {
                        Task {
                            mcpViewModel.jiraSiteURL = jiraSiteURL
                            await mcpViewModel.fetchMyTickets()
                            // 이미 보드에 있는 티켓은 제외하고 전체 선택
                            selectedKeys = Set(
                                mcpViewModel.bulkTickets
                                    .map(\.ticketKey)
                                    .filter { !existingKeys.contains($0) }
                            )
                        }
                    }
                }

                if !mcpViewModel.bulkTickets.isEmpty {
                    Text("\(selectedKeys.count)개 선택됨")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    PastelButton("스티커 만들기", icon: "plus.circle", color: "#98FF98") {
                        importSelected()
                    }
                    .disabled(selectedKeys.isEmpty)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 520, height: 500)
    }

    // MARK: - State View

    @ViewBuilder
    private var stateView: some View {
        switch mcpViewModel.state {
        case .idle:
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 32))
                    .foregroundStyle(Color(hex: "#B0E0E6"))
                Text("나에게 할당된 미완료 티켓을 Jira에서 가져옵니다.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                Text("이미 보드에 있는 티켓은 자동으로 제외됩니다.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

        case .fetching:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Jira에서 내 티켓을 검색하는 중...")
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
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("\(count)개의 티켓을 찾았습니다")
                    .font(.system(size: 12, weight: .medium))
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

    // MARK: - Tickets List

    private var ticketsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("티켓 목록")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()

                Button("모두 선택") {
                    selectedKeys = Set(
                        mcpViewModel.bulkTickets
                            .map(\.ticketKey)
                            .filter { !existingKeys.contains($0) }
                    )
                }
                .font(.caption)

                Button("모두 해제") {
                    selectedKeys.removeAll()
                }
                .font(.caption)
            }

            ForEach(mcpViewModel.bulkTickets, id: \.ticketKey) { ticket in
                let alreadyExists = existingKeys.contains(ticket.ticketKey)
                let isSelected = selectedKeys.contains(ticket.ticketKey)

                HStack(spacing: 10) {
                    // 체크박스
                    Image(systemName: alreadyExists
                          ? "checkmark.circle.badge.xmark"
                          : isSelected
                              ? "checkmark.circle.fill"
                              : "circle")
                    .foregroundStyle(
                        alreadyExists ? .orange
                        : isSelected ? .green
                        : .secondary
                    )
                    .onTapGesture {
                        guard !alreadyExists else { return }
                        if isSelected {
                            selectedKeys.remove(ticket.ticketKey)
                        } else {
                            selectedKeys.insert(ticket.ticketKey)
                        }
                    }

                    // 티켓 정보
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(ticket.ticketKey)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.secondary)

                            Text(ticket.summary)
                                .font(.system(size: 12, weight: .medium))
                                .lineLimit(1)
                        }

                        HStack(spacing: 6) {
                            statusBadge(ticket.status)

                            if !ticket.labels.isEmpty {
                                ForEach(ticket.labels.prefix(3), id: \.self) { label in
                                    Text(label)
                                        .font(.system(size: 9))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(
                                            Capsule()
                                                .fill(Color(hex: "#E6E6FA").opacity(0.5))
                                        )
                                }
                            }

                            if alreadyExists {
                                Text("이미 존재")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(alreadyExists
                              ? Color.orange.opacity(0.03)
                              : isSelected
                                  ? Color.green.opacity(0.05)
                                  : Color.gray.opacity(0.03))
                )
                .opacity(alreadyExists ? 0.6 : 1.0)
            }
        }
    }

    private func statusBadge(_ status: String) -> some View {
        Text(status)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )
            .foregroundStyle(.blue)
    }

    // MARK: - Import

    private func importSelected() {
        let ticketsToImport = mcpViewModel.bulkTickets.filter {
            selectedKeys.contains($0.ticketKey)
        }

        for (index, ticket) in ticketsToImport.enumerated() {
            let context = WorkContext(
                ticketKey: ticket.ticketKey,
                title: ticket.summary,
                accentColorHex: PastelColors.presets[index % PastelColors.presets.count].hex,
                positionX: Double.random(in: 80...450),
                positionY: Double.random(in: 80...350),
                tags: ticket.labels
            )
            context.defaultIconName = IconManager.bundledIcons.randomElement()?.sfSymbol ?? "ticket.fill"
            modelContext.insert(context)
        }

        do {
            try modelContext.save()
        } catch {
            print("[BulkImport] 저장 실패: \(error.localizedDescription)")
        }

        onDone()
    }
}
