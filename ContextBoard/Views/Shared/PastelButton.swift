import SwiftUI

/// 카와이 스타일의 파스텔 버튼 컴포넌트입니다.
struct PastelButton: View {
    let title: String
    let icon: String?
    let colorHex: String
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        color: String = PastelColors.defaultAccent,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.colorHex = color
        self.action = action
    }

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: colorHex).opacity(isHovered ? 0.9 : 0.7))
            )
            .foregroundStyle(.primary)
            .scaleEffect(isHovered ? 1.03 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        PastelButton("새 컨텍스트", icon: "plus", color: "#FFB6C1") {}
        PastelButton("설정", icon: "gearshape", color: "#E6E6FA") {}
        PastelButton("가져오기", icon: "arrow.down.circle", color: "#98FF98") {}
    }
    .padding()
}
