import Testing
import Foundation
@testable import ContextBoard

@Suite("WorkContext 모델 테스트")
struct WorkContextTests {

    @Test("기본 초기화 값 확인")
    func testDefaultInit() {
        let context = WorkContext()

        #expect(!context.id.uuidString.isEmpty)
        #expect(context.ticketKey.isEmpty)
        #expect(context.title.isEmpty)
        #expect(context.iconType == .sfSymbol)
        #expect(context.accentColorHex == "#FFB6C1")
        #expect(!context.isActive)
        #expect(context.items.isEmpty)
        #expect(context.tags.isEmpty)
    }

    @Test("커스텀 초기화")
    func testCustomInit() {
        let context = WorkContext(
            ticketKey: "PROJ-1234",
            title: "예약 플로우 개선",
            accentColorHex: "#E6E6FA",
            isActive: true,
            tags: ["항공", "UX"]
        )

        #expect(context.ticketKey == "PROJ-1234")
        #expect(context.title == "예약 플로우 개선")
        #expect(context.accentColorHex == "#E6E6FA")
        #expect(context.isActive)
        #expect(context.tags == ["항공", "UX"])
    }

    @Test("position CGPoint 변환")
    func testPositionConversion() {
        let context = WorkContext(positionX: 150, positionY: 200)

        #expect(context.position.x == 150)
        #expect(context.position.y == 200)

        context.position = CGPoint(x: 300, y: 400)
        #expect(context.positionX == 300)
        #expect(context.positionY == 400)
    }

    @Test("displayLabel 우선순위")
    func testDisplayLabel() {
        let contextWithKey = WorkContext(ticketKey: "PROJ-1234", title: "테스트 제목")
        #expect(contextWithKey.displayLabel == "PROJ-1234")

        let contextWithoutKey = WorkContext(ticketKey: "", title: "테스트 제목")
        #expect(contextWithoutKey.displayLabel == "테스트 제목")
    }
}
