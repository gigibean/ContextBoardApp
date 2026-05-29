import SwiftUI

/// 개별 스티커 뷰 — 보드 위의 하나의 티켓/컨텍스트를 나타냅니다.
struct StickerView: View {
    let context: WorkContext
    let onTap: () -> Void
    let onDoubleTap: () -> Void

    @State private var isHovered = false
    @State private var dragOffset: CGSize = .zero

    /// 스티커별 고유한 기울임 각도 (생성 시 고정)
    private var tiltAngle: Double {
        // UUID 기반 결정적 랜덤 회전 (-3 ~ +3도)
        let hash = context.id.hashValue
        return Double(hash % 7) - 3.0
    }

    var body: some View {
        VStack(spacing: 6) {
            // 아이콘 영역
            iconArea
                .frame(width: 72, height: 72)

            // 라벨 영역
            Text(context.displayLabel)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 110)

            // 상태 표시
            statusIndicator
        }
        .padding(14)
        .background(stickerBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(
            color: context.isActive
                ? Color(hex: context.accentColorHex).opacity(0.5)
                : .black.opacity(0.1),
            radius: context.isActive ? 12 : 6,
            x: 0,
            y: context.isActive ? 0 : 3
        )
        .overlay(alignment: .topTrailing) {
            if context.isPinned == true {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(.orange)
                    .padding(6)
            }
        }
        .rotationEffect(.degrees(tiltAngle))
        .scaleEffect(isHovered ? 1.08 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
        .bounceEffect(isActive: context.isActive)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            onDoubleTap()
        }
        .onTapGesture(count: 1) {
            onTap()
        }
        .help(context.title.isEmpty ? context.ticketKey : "\(context.ticketKey): \(context.title)")
    }

    // MARK: - Subviews

    @ViewBuilder
    private var iconArea: some View {
        ZStack {
            Circle()
                .fill(Color(hex: context.accentColorHex).opacity(0.3))

            switch context.iconType {
            case .sfSymbol:
                Image(systemName: context.defaultIconName ?? "ticket.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Color(hex: context.accentColorHex))

            case .bundledKawaii:
                Image(systemName: context.defaultIconName ?? "star.fill")
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(Color(hex: context.accentColorHex))

            case .customImage:
                if let data = context.customIconData,
                   let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(context.isActive ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 6, height: 6)

            Text(context.isActive ? "활성" : "비활성")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var stickerBackground: some ShapeStyle {
        .ultraThinMaterial
    }
}

#Preview {
    let context = WorkContext(
        ticketKey: "PROJ-1234",
        title: "예약 플로우 개선",
        accentColorHex: "#FFB6C1",
        isActive: true
    )
    StickerView(context: context, onTap: {}, onDoubleTap: {})
        .padding(30)
        .background(Color(hex: "#FFF0F5"))
}
