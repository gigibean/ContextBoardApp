import SwiftUI

/// 프로스티드 글래스 효과의 카드 배경 컴포넌트입니다.
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let content: () -> Content

    init(
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
    }
}

#Preview {
    GlassCard {
        Text("글래스 카드")
            .padding(24)
    }
    .padding()
    .frame(width: 300, height: 200)
    .background(
        LinearGradient(
            colors: [Color(hex: "#FFE4E1"), Color(hex: "#E6E6FA")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
