import AppKit
import ApplicationServices

/// AXUIElement API를 사용하여 앱 창을 특정 모니터로 이동하는 헬퍼입니다.
@MainActor
enum WindowMover {

    /// Accessibility 권한이 있는지 확인합니다.
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Accessibility 권한을 요청합니다 (시스템 다이얼로그 표시).
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// 지정된 PID의 앱 창을 특정 모니터로 이동합니다.
    /// - Parameters:
    ///   - pid: 대상 앱의 프로세스 ID
    ///   - screenName: 이동할 모니터의 `NSScreen.localizedName`
    ///   - retryCount: 창이 아직 생성되지 않은 경우 재시도 횟수
    static func moveWindow(pid: pid_t, toScreenNamed screenName: String, retryCount: Int = 5) async {
        guard isTrusted else {
            print("[WindowMover] Accessibility 권한 없음")
            return
        }

        let availableScreens = NSScreen.screens.map { $0.localizedName }
        guard let targetScreen = NSScreen.screens.first(where: { $0.localizedName == screenName }) else {
            print("[WindowMover] 모니터 '\(screenName)' 미발견. 사용 가능: \(availableScreens)")
            return
        }

        // 앱을 먼저 활성화해야 AX에서 창이 보임 (특히 Electron 앱)
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }) {
            app.unhide()
            app.activate(options: [.activateAllWindows])
            print("[WindowMover] PID \(pid) 활성화 요청 (\(app.localizedName ?? "?"))")
        }

        // 활성화 후 창이 나타날 때까지 충분히 대기
        try? await Task.sleep(for: .milliseconds(800))

        for attempt in 0..<retryCount {
            if attempt > 0 {
                try? await Task.sleep(for: .milliseconds(800))
            }

            let appElement = AXUIElementCreateApplication(pid)
            var windowsRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)

            if result != .success {
                print("[WindowMover] 시도 \(attempt + 1)/\(retryCount): PID \(pid) AX 실패 (code: \(result.rawValue))")
                continue
            }

            guard let windowsList = windowsRef as? [AXUIElement] else {
                print("[WindowMover] 시도 \(attempt + 1)/\(retryCount): PID \(pid) windowsRef 캐스팅 실패 (type: \(type(of: windowsRef)))")
                continue
            }

            print("[WindowMover] 시도 \(attempt + 1)/\(retryCount): PID \(pid) 창 \(windowsList.count)개 발견")

            guard let window = windowsList.first else {
                print("[WindowMover] 시도 \(attempt + 1)/\(retryCount): PID \(pid) 창 목록 비어있음")
                continue
            }

            // macOS 좌표계: 메인 스크린 좌상단이 (0,0), y축은 아래로 증가
            // NSScreen.frame은 좌하단 기준이므로 변환 필요
            let mainHeight = NSScreen.main?.frame.height ?? 0
            let frame = targetScreen.frame
            var position = CGPoint(
                x: frame.origin.x + 50,
                y: mainHeight - frame.origin.y - frame.height + 50
            )
            var size = CGSize(
                width: min(frame.width * 0.8, 1400),
                height: min(frame.height * 0.8, 900)
            )

            let posResult: AXError
            let sizeResult: AXError
            if let posValue = AXValueCreate(.cgPoint, &position) {
                posResult = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posValue)
            } else {
                posResult = .failure
            }
            if let sizeValue = AXValueCreate(.cgSize, &size) {
                sizeResult = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
            } else {
                sizeResult = .failure
            }

            print("[WindowMover] PID \(pid) → '\(screenName)' pos=\(position) size=\(size) (pos:\(posResult.rawValue), size:\(sizeResult.rawValue))")
            return
        }
        print("[WindowMover] PID \(pid): \(retryCount)회 시도 후 창 이동 실패")
    }
}
