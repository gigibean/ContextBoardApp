import SwiftUI

/// MCP에서 가져온 결과를 미리보기하는 뷰입니다.
/// MCPFetchView 내부에서 결과 확인 시 사용됩니다.
struct MCPResultReviewView: View {
    let ticketKey: String
    let summary: String
    let status: String
    let assignee: String?
    let items: [ContextEditorViewModel.EditableItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 티켓 정보 헤더
            GlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "ticket.fill")
                            .foregroundStyle(Color(hex: "#FFB6C1"))
                        Text(ticketKey)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                        Spacer()
                        statusBadge
                    }

                    Text(summary)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)

                    if let assignee {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                            Text(assignee)
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(.tertiary)
                    }
                }
                .padding(12)
            }

            // 아이템 요약
            Text("관련 리소스 (\(items.count)개)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            ForEach(items, id: \.id) { item in
                HStack(spacing: 8) {
                    Image(systemName: iconForURLType(item.value))
                        .font(.system(size: 12))
                        .foregroundStyle(colorForURLType(item.value))
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.label)
                            .font(.system(size: 11, weight: .medium))
                        Text(item.value)
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var statusBadge: some View {
        Text(status)
            .font(.system(size: 10, weight: .medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
            )
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        switch status.lowercased() {
        case let s where s.contains("done") || s.contains("완료"):
            return .green
        case let s where s.contains("progress") || s.contains("진행"):
            return .blue
        case let s where s.contains("review") || s.contains("리뷰"):
            return .orange
        default:
            return .gray
        }
    }

    private func iconForURLType(_ url: String) -> String {
        IconManager.suggestIcon(for: url)
    }

    private func colorForURLType(_ url: String) -> Color {
        let lowered = url.lowercased()
        if lowered.contains("github") { return .purple }
        if lowered.contains("figma") { return .orange }
        if lowered.contains("atlassian") || lowered.contains("jira") { return .blue }
        if lowered.contains("confluence") { return .cyan }
        return .gray
    }
}
