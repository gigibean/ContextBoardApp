import AppKit
import SwiftUI

/// NSApplicationDelegate — 플로팅 패널 생명주기를 관리합니다.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var panel: NSPanel?
    private var panelHostingView: NSHostingView<AnyView>?

    /// 패널 표시/숨기기 토글 콜백
    var onTogglePanel: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 앱이 Dock에 표시되지 않도록 확인
        NSApp.setActivationPolicy(.accessory)
    }

    /// 플로팅 패널을 생성합니다.
    func createPanel<Content: View>(content: Content) -> NSPanel {
        if let existingPanel = panel {
            return existingPanel
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
            styleMask: [.titled, .closable, .resizable, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )

        panel.title = "ContextBoard"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear

        // 화면 중앙에 배치
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = panel.frame
            let x = screenFrame.midX - panelFrame.width / 2
            let y = screenFrame.midY - panelFrame.height / 2
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        let hostingView = NSHostingView(rootView: AnyView(content))
        panel.contentView = hostingView

        self.panel = panel
        self.panelHostingView = hostingView

        return panel
    }

    /// 패널 표시/숨기기를 토글합니다.
    func togglePanel() {
        guard let panel else { return }

        if panel.isVisible {
            panel.orderOut(nil)
        } else {
            panel.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    /// 패널이 현재 표시 중인지 확인합니다.
    var isPanelVisible: Bool {
        panel?.isVisible ?? false
    }
}
