import SwiftUI
import AppKit

/// Hex 문자열과 SwiftUI Color 간 변환 유틸리티
extension Color {
    /// Hex 문자열로부터 Color를 생성합니다.
    /// - Parameter hex: "#RRGGBB" 또는 "#RRGGBBAA" 형식의 문자열
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // RGBA
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 200, 180, 190) // 기본 파스텔 핑크
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Color를 Hex 문자열로 변환합니다.
    var hexString: String {
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else {
            return "#FFB6C1"
        }
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

/// 파스텔 색상 프리셋
enum PastelColors {
    static let presets: [(name: String, hex: String)] = [
        ("핑크", "#FFB6C1"),
        ("라벤더", "#E6E6FA"),
        ("민트", "#98FF98"),
        ("피치", "#FFDAB9"),
        ("스카이", "#87CEEB"),
        ("레몬", "#FFFACD"),
        ("라일락", "#DDA0DD"),
        ("코랄", "#F08080"),
        ("아쿠아", "#7FFFD4"),
        ("로즈", "#FFE4E1"),
        ("바이올렛", "#EE82EE"),
        ("샴페인", "#F7E7CE"),
    ]

    static let defaultAccent = "#FFB6C1"
}
