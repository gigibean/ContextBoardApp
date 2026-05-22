import SwiftUI

/// 보드의 배경 레이어를 렌더링하는 뷰입니다.
struct BoardBackgroundView: View {
    let settings: BoardSettings?

    var body: some View {
        Group {
            switch settings?.backgroundStyle ?? .defaultKawaii {
            case .solidColor:
                Color(hex: settings?.solidColorHex ?? "#FFF0F5")

            case .gradient:
                let colors = settings?.gradientColors ?? ["#FFE4E1", "#E6E6FA", "#F0FFF0"]
                LinearGradient(
                    colors: colors.map { Color(hex: $0) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

            case .image:
                if let data = settings?.backgroundImageData,
                   let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    defaultKawaiiBackground
                }

            case .defaultKawaii:
                defaultKawaiiBackground
            }
        }
    }

    /// 기본 카와이 배경 — 부드러운 파스텔 그라데이션에 점 패턴
    private var defaultKawaiiBackground: some View {
        ZStack {
            // 베이스 그라데이션
            LinearGradient(
                colors: [
                    Color(hex: "#FFF0F5"), // Lavender Blush
                    Color(hex: "#F0F8FF"), // Alice Blue
                    Color(hex: "#FFF5EE"), // Seashell
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 점 패턴 오버레이
            Canvas { context, size in
                let dotSize: CGFloat = 2
                let spacing: CGFloat = 24
                let dotColor = Color(hex: "#E8D5E0").opacity(0.5)

                for x in stride(from: spacing, to: size.width, by: spacing) {
                    for y in stride(from: spacing, to: size.height, by: spacing) {
                        let rect = CGRect(
                            x: x - dotSize / 2,
                            y: y - dotSize / 2,
                            width: dotSize,
                            height: dotSize
                        )
                        context.fill(
                            Path(ellipseIn: rect),
                            with: .color(dotColor)
                        )
                    }
                }
            }
        }
    }
}

#Preview {
    BoardBackgroundView(settings: nil)
        .frame(width: 600, height: 450)
}
