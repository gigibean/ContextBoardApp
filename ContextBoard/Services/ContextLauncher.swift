import AppKit
import Foundation

/// 컨텍스트에 포함된 앱/URL을 열고, 숨기고, 활성화하는 서비스입니다.
@MainActor
final class ContextLauncher: ObservableObject {

    enum LauncherError: LocalizedError {
        case invalidURL(String)
        case applicationNotFound(String)
        case openFailed(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL(let url):
                return "유효하지 않은 URL입니다: \(url)"
            case .applicationNotFound(let bundleId):
                return "애플리케이션을 찾을 수 없습니다: \(bundleId)"
            case .openFailed(let detail):
                return "열기 실패: \(detail)"
            }
        }
    }

    /// 컨텍스트별로 실행된 앱을 추적합니다.
    private var trackedApps: [UUID: Set<pid_t>] = [:]

    /// 워크스페이스 알림 관찰 토큰
    private var terminationObserver: NSObjectProtocol?

    init() {
        setupTerminationObserver()
    }

    deinit {
        if let observer = terminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    // MARK: - Public API

    /// 컨텍스트의 모든 활성 아이템을 엽니다.
    func openContext(_ context: WorkContext) async throws {
        var pids = Set<pid_t>()

        for item in context.enabledItems {
            do {
                if let pid = try await openItem(item) {
                    pids.insert(pid)
                }
            } catch {
                // 개별 아이템 실패는 로깅하고 계속 진행
                print("[ContextLauncher] 아이템 열기 실패 (\(item.label)): \(error.localizedDescription)")
            }
        }

        trackedApps[context.id] = pids
        context.isActive = true
        context.updatedAt = Date()
    }

    /// 컨텍스트에 연결된 앱들을 숨깁니다.
    func hideContext(_ context: WorkContext) {
        if let pids = trackedApps[context.id] {
            let runningApps = NSWorkspace.shared.runningApplications
            for pid in pids {
                if let app = runningApps.first(where: { $0.processIdentifier == pid }) {
                    app.hide()
                }
            }
        }

        // PID 추적 여부와 관계없이 항상 상태 업데이트
        context.isActive = false
        context.updatedAt = Date()
    }

    /// 컨텍스트에 연결된 앱들을 다시 표시합니다.
    func unhideContext(_ context: WorkContext) {
        if let pids = trackedApps[context.id] {
            let runningApps = NSWorkspace.shared.runningApplications
            for pid in pids {
                if let app = runningApps.first(where: { $0.processIdentifier == pid }) {
                    app.unhide()
                    app.activate()
                }
            }
        }

        context.isActive = true
        context.updatedAt = Date()
    }

    /// 컨텍스트 열기/숨기기를 토글합니다.
    func toggleContext(_ context: WorkContext) async throws {
        if context.isActive {
            hideContext(context)
        } else {
            // 추적된 앱이 있으면 unhide, 없으면 새로 열기
            if let pids = trackedApps[context.id], !pids.isEmpty {
                let runningApps = NSWorkspace.shared.runningApplications
                let stillRunning = pids.contains { pid in
                    runningApps.contains { $0.processIdentifier == pid }
                }
                if stillRunning {
                    unhideContext(context)
                } else {
                    try await openContext(context)
                }
            } else {
                try await openContext(context)
            }
        }
    }

    /// 컨텍스트에 연결된 앱들을 강제 종료합니다.
    func terminateContext(_ context: WorkContext) {
        if let pids = trackedApps[context.id] {
            let runningApps = NSWorkspace.shared.runningApplications
            for pid in pids {
                if let app = runningApps.first(where: { $0.processIdentifier == pid }) {
                    app.terminate()
                }
            }
            trackedApps.removeValue(forKey: context.id)
        }

        context.isActive = false
        context.updatedAt = Date()
    }

    // MARK: - Private

    /// 개별 아이템을 열고 프로세스 ID를 반환합니다.
    private func openItem(_ item: ContextItem) async throws -> pid_t? {
        switch item.type {
        case .webURL, .deepLink:
            guard let urlString = item.urlString,
                  let url = URL(string: urlString) else {
                throw LauncherError.invalidURL(item.urlString ?? "(빈 URL)")
            }
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            let app = try await NSWorkspace.shared.open(url, configuration: config)
            return app.processIdentifier

        case .application:
            guard let bundleId = item.bundleIdentifier,
                  let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
                throw LauncherError.applicationNotFound(item.bundleIdentifier ?? "(빈 번들 ID)")
            }
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true

            // 프로젝트 폴더가 지정되어 있으면 해당 폴더를 앱으로 열기
            if let projectPath = item.filePath, !projectPath.isEmpty {
                let folderURL = URL(fileURLWithPath: projectPath)
                let app = try await NSWorkspace.shared.open([folderURL], withApplicationAt: appURL, configuration: config)
                return app.processIdentifier
            } else {
                let app = try await NSWorkspace.shared.openApplication(at: appURL, configuration: config)
                return app.processIdentifier
            }

        case .file, .directory:
            guard let filePath = item.filePath else {
                throw LauncherError.invalidURL(item.filePath ?? "(빈 경로)")
            }
            let fileURL = URL(fileURLWithPath: filePath)
            let success = NSWorkspace.shared.open(fileURL)
            guard success else {
                throw LauncherError.openFailed(filePath)
            }
            return nil
        }
    }

    /// 앱 종료 알림을 감시하여 추적 목록을 정리합니다.
    private func setupTerminationObserver() {
        terminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            let pid = app.processIdentifier
            Task { @MainActor [weak self] in
                self?.removeTrackedPID(pid)
            }
        }
    }

    /// 종료된 앱의 PID를 추적 목록에서 제거합니다.
    private func removeTrackedPID(_ pid: pid_t) {
        for (contextId, var pids) in trackedApps {
            if pids.remove(pid) != nil {
                trackedApps[contextId] = pids
            }
        }
    }
}
