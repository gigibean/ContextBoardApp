import Foundation

/// 보드 배경 스타일을 정의합니다.
enum BackgroundStyle: String, Codable, CaseIterable {
    /// 단일 색상
    case solidColor
    /// 그라데이션
    case gradient
    /// 커스텀 이미지
    case image
    /// 기본 카와이 배경
    case defaultKawaii

    var displayName: String {
        switch self {
        case .solidColor: return "단색"
        case .gradient: return "그라데이션"
        case .image: return "이미지"
        case .defaultKawaii: return "기본 배경"
        }
    }
}
