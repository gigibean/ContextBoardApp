import Foundation

/// 스티커 아이콘의 타입을 정의합니다.
enum IconType: String, Codable, CaseIterable {
    /// SF Symbol 시스템 아이콘
    case sfSymbol
    /// 번들된 카와이 스타일 아이콘
    case bundledKawaii
    /// 사용자 커스텀 이미지
    case customImage

    var displayName: String {
        switch self {
        case .sfSymbol: return "SF Symbol"
        case .bundledKawaii: return "기본 아이콘"
        case .customImage: return "커스텀 이미지"
        }
    }
}
