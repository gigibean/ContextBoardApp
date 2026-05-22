import Foundation
import SwiftData

/// 보드의 전역 설정을 저장하는 싱글톤 모델입니다.
@Model
final class BoardSettings {
    var id: UUID
    var backgroundImageData: Data?
    var backgroundStyle: BackgroundStyle
    var gradientColors: [String]
    var solidColorHex: String
    var gridSnapEnabled: Bool
    var launchAtLogin: Bool
    var globalHotkey: String?
    var boardWidth: Double
    var boardHeight: Double
    var jiraSiteURL: String

    init(
        id: UUID = UUID(),
        backgroundImageData: Data? = nil,
        backgroundStyle: BackgroundStyle = .defaultKawaii,
        gradientColors: [String] = ["#FFE4E1", "#E6E6FA", "#F0FFF0"],
        solidColorHex: String = "#FFF0F5",
        gridSnapEnabled: Bool = false,
        launchAtLogin: Bool = false,
        globalHotkey: String? = "Cmd+Shift+B",
        boardWidth: Double = 600,
        boardHeight: Double = 450,
        jiraSiteURL: String = ""
    ) {
        self.id = id
        self.backgroundImageData = backgroundImageData
        self.backgroundStyle = backgroundStyle
        self.gradientColors = gradientColors
        self.solidColorHex = solidColorHex
        self.gridSnapEnabled = gridSnapEnabled
        self.launchAtLogin = launchAtLogin
        self.globalHotkey = globalHotkey
        self.boardWidth = boardWidth
        self.boardHeight = boardHeight
        self.jiraSiteURL = jiraSiteURL
    }

    /// 기본 설정을 가진 싱글톤 인스턴스를 반환하거나 생성합니다.
    @MainActor
    static func getOrCreate(in context: ModelContext) throws -> BoardSettings {
        let descriptor = FetchDescriptor<BoardSettings>()
        let existing = try context.fetch(descriptor)

        if let settings = existing.first {
            return settings
        }

        let settings = BoardSettings()
        context.insert(settings)
        try context.save()
        return settings
    }
}
