import AppKit
import Foundation
import SwiftData

/// 개별 컨텍스트 아이템 (URL, 앱, 파일 등)을 나타내는 모델입니다.
@Model
final class ContextItem {
    var id: UUID
    var type: ContextItemType
    var label: String
    var urlString: String?
    var bundleIdentifier: String?
    var filePath: String?
    var sortOrder: Int
    var isEnabled: Bool
    /// 앱을 열 모니터 이름 (nil이면 기본 모니터)
    var preferredScreen: String?

    @Relationship(inverse: \WorkContext.items)
    var context: WorkContext?

    init(
        id: UUID = UUID(),
        type: ContextItemType = .webURL,
        label: String = "",
        urlString: String? = nil,
        bundleIdentifier: String? = nil,
        filePath: String? = nil,
        sortOrder: Int = 0,
        isEnabled: Bool = true,
        preferredScreen: String? = nil,
        context: WorkContext? = nil
    ) {
        self.id = id
        self.type = type
        self.label = label
        self.urlString = urlString
        self.bundleIdentifier = bundleIdentifier
        self.filePath = filePath
        self.sortOrder = sortOrder
        self.isEnabled = isEnabled
        self.preferredScreen = preferredScreen
        self.context = context
    }

    /// 이 아이템을 열기 위한 URL을 반환합니다.
    var resolvedURL: URL? {
        switch type {
        case .webURL, .deepLink:
            guard let urlString else { return nil }
            return URL(string: urlString)
        case .application:
            guard let bundleId = bundleIdentifier else { return nil }
            return NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
        case .file, .directory:
            guard let filePath else { return nil }
            return URL(fileURLWithPath: filePath)
        }
    }
}
