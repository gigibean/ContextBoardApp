import AppKit
import Foundation

/// 실행 중인 앱 상태를 추적하고 컨텍스트와 매칭하는 서비스입니다.
@MainActor
final class AppTracker: ObservableObject {

    /// 현재 실행 중인 앱의 번들 ID 세트
    @Published private(set) var runningBundleIds: Set<String> = []

    private var launchObserver: NSObjectProtocol?
    private var terminationObserver: NSObjectProtocol?

    init() {
        refreshRunningApps()
        setupObservers()
    }

    deinit {
        if let observer = launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = terminationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    /// 실행 중인 앱 목록을 갱신합니다.
    func refreshRunningApps() {
        runningBundleIds = Set(
            NSWorkspace.shared.runningApplications
                .compactMap(\.bundleIdentifier)
        )
    }

    /// 특정 번들 ID의 앱이 실행 중인지 확인합니다.
    func isRunning(bundleIdentifier: String) -> Bool {
        runningBundleIds.contains(bundleIdentifier)
    }

    /// 컨텍스트의 앱 아이템 중 실행 중인 것의 비율을 반환합니다.
    func activeRatio(for context: WorkContext) -> Double {
        let appItems = context.enabledItems.filter { $0.type == .application }
        guard !appItems.isEmpty else { return 0 }

        let runningCount = appItems.filter { item in
            guard let bundleId = item.bundleIdentifier else { return false }
            return isRunning(bundleIdentifier: bundleId)
        }.count

        return Double(runningCount) / Double(appItems.count)
    }

    // MARK: - Private

    private func setupObservers() {
        launchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier else { return }
            Task { @MainActor [weak self] in
                self?.runningBundleIds.insert(bundleId)
            }
        }

        terminationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleId = app.bundleIdentifier else { return }
            Task { @MainActor [weak self] in
                self?.runningBundleIds.remove(bundleId)
            }
        }
    }
}
