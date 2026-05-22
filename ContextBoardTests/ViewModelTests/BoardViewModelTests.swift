import Testing
import Foundation
@testable import ContextBoard

@Suite("BoardViewModel 테스트")
struct BoardViewModelTests {

    @Test("초기 상태 확인")
    @MainActor
    func testInitialState() {
        let vm = BoardViewModel()

        #expect(vm.editingContext == nil)
        #expect(!vm.isShowingCreateSheet)
        #expect(!vm.isShowingSettings)
        #expect(vm.errorMessage == nil)
        #expect(vm.draggingContextId == nil)
    }

    @Test("스티커 위치 업데이트")
    @MainActor
    func testUpdatePosition() {
        let vm = BoardViewModel()
        let context = WorkContext(ticketKey: "TEST-001", positionX: 100, positionY: 100)

        let newPoint = CGPoint(x: 300, y: 250)
        vm.updatePosition(context, to: newPoint)

        #expect(context.positionX == 300)
        #expect(context.positionY == 250)
    }

    @Test("에러 메시지 닫기")
    @MainActor
    func testDismissError() {
        let vm = BoardViewModel()
        vm.errorMessage = "테스트 에러"

        vm.dismissError()
        #expect(vm.errorMessage == nil)
    }
}
