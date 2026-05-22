import SwiftUI
import SwiftData

/// 스티커 보드의 전체 상태를 관리하는 ViewModel입니다.
@MainActor
@Observable
final class BoardViewModel {

    // MARK: - Properties

    let contextLauncher = ContextLauncher()
    let appTracker = AppTracker()

    /// 현재 편집 중인 컨텍스트 (nil이면 에디터 닫힘)
    var editingContext: WorkContext?

    /// 새 컨텍스트 생성 시트 표시 여부
    var isShowingCreateSheet = false

    /// 설정 창 표시 여부
    var isShowingSettings = false

    /// 에러 메시지 (nil이면 에러 없음)
    var errorMessage: String?

    /// 드래그 중인 스티커의 ID
    var draggingContextId: UUID?

    // MARK: - Actions

    /// 스티커 클릭 시 컨텍스트 토글
    func toggleContext(_ context: WorkContext) {
        Task {
            do {
                try await contextLauncher.toggleContext(context)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    /// 스티커 위치 업데이트 (드래그 완료 시)
    func updatePosition(_ context: WorkContext, to point: CGPoint) {
        context.positionX = point.x
        context.positionY = point.y
        context.updatedAt = Date()
    }

    /// 새 컨텍스트 생성
    func createContext(in modelContext: ModelContext) -> WorkContext {
        let context = WorkContext()
        // 기본 위치: 보드 중앙 근처에 랜덤 배치
        context.positionX = Double.random(in: 80...400)
        context.positionY = Double.random(in: 80...350)
        // 기본 파스텔 색상 랜덤 선택
        let randomColor = PastelColors.presets.randomElement()?.hex ?? PastelColors.defaultAccent
        context.accentColorHex = randomColor
        // 기본 아이콘 랜덤 선택
        let randomIcon = IconManager.bundledIcons.randomElement()
        context.defaultIconName = randomIcon?.sfSymbol ?? "ticket.fill"

        modelContext.insert(context)
        return context
    }

    /// 컨텍스트 삭제
    func deleteContext(_ context: WorkContext, from modelContext: ModelContext) {
        // 활성 상태면 먼저 숨기기
        if context.isActive {
            contextLauncher.hideContext(context)
        }
        modelContext.delete(context)
    }

    /// 컨텍스트에 연결된 앱들을 종료
    func terminateContext(_ context: WorkContext) {
        contextLauncher.terminateContext(context)
    }

    /// 에러 메시지 닫기
    func dismissError() {
        errorMessage = nil
    }
}
