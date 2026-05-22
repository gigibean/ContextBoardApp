import SwiftUI

/// 스티커에 바운스/흔들림 애니메이션을 추가하는 ViewModifier입니다.
struct BounceModifier: ViewModifier {
    let isActive: Bool

    @State private var isBouncing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBouncing ? 1.05 : 1.0)
            .animation(
                isActive
                    ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                    : .default,
                value: isBouncing
            )
            .onChange(of: isActive) { _, newValue in
                isBouncing = newValue
            }
            .onAppear {
                isBouncing = isActive
            }
    }
}

/// 스티커에 미세한 흔들림 효과를 추가하는 ViewModifier입니다.
struct WiggleModifier: ViewModifier {
    let isWiggling: Bool
    let intensity: Double

    @State private var angle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(angle))
            .animation(
                isWiggling
                    ? .easeInOut(duration: 0.15).repeatForever(autoreverses: true)
                    : .default,
                value: angle
            )
            .onChange(of: isWiggling) { _, newValue in
                angle = newValue ? intensity : 0
            }
    }
}

extension View {
    /// 활성 상태일 때 바운스 애니메이션을 적용합니다.
    func bounceEffect(isActive: Bool) -> some View {
        modifier(BounceModifier(isActive: isActive))
    }

    /// 편집 모드에서 흔들림 효과를 적용합니다.
    func wiggleEffect(isWiggling: Bool, intensity: Double = 2) -> some View {
        modifier(WiggleModifier(isWiggling: isWiggling, intensity: intensity))
    }
}

#Preview {
    HStack(spacing: 30) {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "#FFB6C1"))
            .frame(width: 80, height: 80)
            .bounceEffect(isActive: true)

        RoundedRectangle(cornerRadius: 12)
            .fill(Color(hex: "#E6E6FA"))
            .frame(width: 80, height: 80)
            .wiggleEffect(isWiggling: true)
    }
    .padding(40)
}
