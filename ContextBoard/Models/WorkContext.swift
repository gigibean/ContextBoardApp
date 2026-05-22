import Foundation
import SwiftData
import CoreGraphics

/// 티켓/태스크 기반 작업 컨텍스트를 나타내는 핵심 모델입니다.
/// 각 WorkContext는 하나의 "스티커"로 보드에 표시됩니다.
@Model
final class WorkContext {
    var id: UUID
    var ticketKey: String
    var title: String
    var iconType: IconType
    var customIconData: Data?
    var defaultIconName: String?
    var accentColorHex: String
    var positionX: Double
    var positionY: Double
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    var tags: [String]
    var notes: String?

    @Relationship(deleteRule: .cascade)
    var items: [ContextItem] = []

    init(
        id: UUID = UUID(),
        ticketKey: String = "",
        title: String = "",
        iconType: IconType = .sfSymbol,
        customIconData: Data? = nil,
        defaultIconName: String? = "ticket.fill",
        accentColorHex: String = "#FFB6C1",
        positionX: Double = 100,
        positionY: Double = 100,
        isActive: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tags: [String] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.ticketKey = ticketKey
        self.title = title
        self.iconType = iconType
        self.customIconData = customIconData
        self.defaultIconName = defaultIconName
        self.accentColorHex = accentColorHex
        self.positionX = positionX
        self.positionY = positionY
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
        self.notes = notes
    }

    /// CGPoint로 변환된 보드 위치
    var position: CGPoint {
        get { CGPoint(x: positionX, y: positionY) }
        set {
            positionX = newValue.x
            positionY = newValue.y
        }
    }

    /// 활성화된 아이템만 필터링
    var enabledItems: [ContextItem] {
        items.filter(\.isEnabled).sorted { $0.sortOrder < $1.sortOrder }
    }

    /// 표시용 짧은 라벨 (제목 우선, 없으면 티켓 키)
    var displayLabel: String {
        title.isEmpty ? ticketKey : title
    }
}
