import Testing
import Foundation
@testable import ContextBoard

@Suite("ContextLauncher 서비스 테스트")
struct ContextLauncherTests {

    @Test("비어있는 컨텍스트 토글 시 에러 없음")
    @MainActor
    func testToggleEmptyContext() async throws {
        let launcher = ContextLauncher()
        let context = WorkContext(ticketKey: "TEST-001", title: "빈 컨텍스트")

        // 아이템이 없는 컨텍스트 토글 — 에러 없이 처리되어야 함
        try await launcher.toggleContext(context)
        #expect(context.isActive)
    }

    @Test("컨텍스트 숨기기 후 비활성 상태")
    @MainActor
    func testHideContextSetsInactive() {
        let launcher = ContextLauncher()
        let context = WorkContext(ticketKey: "TEST-002", isActive: true)

        launcher.hideContext(context)
        #expect(!context.isActive)
    }
}
