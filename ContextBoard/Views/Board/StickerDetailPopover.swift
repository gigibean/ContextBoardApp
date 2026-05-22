import SwiftUI

/// 스티커 상세 정보를 표시하는 팝오버 뷰입니다.
struct StickerDetailPopover: View {
    let context: WorkContext
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 헤더
            HStack {
                Image(systemName: context.defaultIconName ?? "ticket.fill")
                    .font(.title2)
                    .foregroundStyle(Color(hex: context.accentColorHex))

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.ticketKey)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    if !context.title.isEmpty {
                        Text(context.title)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // 상태 뱃지
                Text(context.isActive ? "활성" : "비활성")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(context.isActive ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    )
                    .foregroundStyle(context.isActive ? .green : .secondary)
            }

            Divider()

            // 아이템 목록
            if context.items.isEmpty {
                Text("아이템이 없습니다. 편집하여 추가하세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("포함된 아이템 (\(context.enabledItems.count))")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ForEach(context.enabledItems, id: \.id) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.type.iconName)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .frame(width: 14)

                            Text(item.label.isEmpty ? (item.urlString ?? item.bundleIdentifier ?? "이름 없음") : item.label)
                                .font(.system(size: 11))
                                .lineLimit(1)
                        }
                    }
                }
            }

            Divider()

            // 태그
            if !context.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(context.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: context.accentColorHex).opacity(0.2))
                                )
                        }
                    }
                }
            }

            // 액션 버튼
            HStack(spacing: 8) {
                PastelButton(
                    context.isActive ? "숨기기" : "열기",
                    icon: context.isActive ? "eye.slash" : "arrow.up.right.square",
                    color: context.isActive ? "#F08080" : "#98FF98"
                ) {
                    onToggle()
                }

                PastelButton("편집", icon: "pencil", color: "#E6E6FA") {
                    onEdit()
                }

                PastelButton("삭제", icon: "trash", color: "#F08080") {
                    onDelete()
                }
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}

#Preview {
    let context = WorkContext(
        ticketKey: "AIR-1234",
        title: "항공권 예약 플로우 개선",
        tags: ["항공", "예약", "UX"]
    )
    StickerDetailPopover(
        context: context,
        onEdit: {},
        onDelete: {},
        onToggle: {}
    )
}
