import Foundation

/// 컨텍스트 아이템의 타입을 정의합니다.
enum ContextItemType: String, Codable, CaseIterable {
    /// 웹 URL (브라우저에서 열기)
    case webURL
    /// macOS 애플리케이션
    case application
    /// 파일
    case file
    /// 디렉토리
    case directory
    /// 딥 링크 (vscode://, figma:// 등)
    case deepLink

    var displayName: String {
        switch self {
        case .webURL: return "웹 URL"
        case .application: return "애플리케이션"
        case .file: return "파일"
        case .directory: return "폴더"
        case .deepLink: return "딥 링크"
        }
    }

    var iconName: String {
        switch self {
        case .webURL: return "globe"
        case .application: return "app.fill"
        case .file: return "doc.fill"
        case .directory: return "folder.fill"
        case .deepLink: return "link"
        }
    }

    var placeholder: String {
        switch self {
        case .webURL: return "https://example.com"
        case .application: return "com.microsoft.VSCode"
        case .file: return "/path/to/file"
        case .directory: return "/path/to/directory"
        case .deepLink: return "vscode://file/path/to/project"
        }
    }
}
