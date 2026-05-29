import AppKit
import SwiftUI
import SwiftData

/// NSApplicationDelegate — 플로팅 패널 생명주기를 관리합니다.
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var panel: NSPanel?
    private var panelHostingView: NSHostingView<AnyView>?
    private var settingsWindow: NSWindow?

    /// 패널 표시/숨기기 토글 콜백
    var onTogglePanel: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 앱이 Dock에 표시되지 않도록 확인
        NSApp.setActivationPolicy(.accessory)

        // 설정/파인더 등 다른 윈도우가 열리면 패널 레벨을 낮춰서
        // 해당 윈도우가 패널 위에 표시되도록 함
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(otherWindowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(otherWindowWillClose),
            name: NSWindow.willCloseNotification,
            object: nil
        )
    }

    @objc private func otherWindowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window != panel else { return }
        // 다른 윈도우(설정, 파인더 등)가 키 윈도우가 되면 패널 레벨을 낮춤
        panel?.level = .normal
    }

    @objc private func otherWindowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window != panel else { return }
        // 다른 윈도우가 닫히면 패널을 다시 플로팅으로 복원
        panel?.level = .floating
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

    // MARK: - Settings Window

    /// 설정 윈도우를 열거나 포커스합니다.
    func openSettings(modelContainer: ModelContainer) {
        // 이미 열려 있으면 포커스만
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .modelContainer(modelContainer)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 620),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "ContextBoard 설정"
        window.minSize = NSSize(width: 450, height: 500)
        window.center()
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: settingsView)

        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
