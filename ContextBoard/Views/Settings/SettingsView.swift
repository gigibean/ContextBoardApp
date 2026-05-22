import SwiftUI
import SwiftData
import ServiceManagement

/// 앱 설정 뷰입니다.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allSettings: [BoardSettings]

    @State private var launchAtLogin = false
    @State private var gridSnap = false
    @State private var hotkey = "Cmd+Shift+B"
    @State private var jiraSiteURL = ""

    private var settings: BoardSettings? { allSettings.first }

    var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("일반", systemImage: "gearshape")
                }

            backgroundTab
                .tabItem {
                    Label("배경", systemImage: "paintpalette")
                }

            aboutTab
                .tabItem {
                    Label("정보", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 350)
        .onAppear {
            loadSettings()
        }
    }

    // MARK: - General Tab

    private var generalTab: some View {
        Form {
            Section("동작") {
                Toggle("로그인 시 자동 실행", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        updateLaunchAtLogin(newValue)
                    }

                Toggle("그리드 스냅", isOn: $gridSnap)
                    .onChange(of: gridSnap) { _, newValue in
                        updateSetting { $0.gridSnapEnabled = newValue }
                    }
                    .help("스티커를 드래그할 때 그리드에 맞춰 정렬합니다")
            }

            Section("단축키") {
                HStack {
                    Text("보드 토글")
                    Spacer()
                    Text(hotkey)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.gray.opacity(0.1))
                        )
                        .font(.system(size: 12, design: .monospaced))
                }
            }

            Section("Jira 연동") {
                HStack {
                    Text("Jira 사이트 URL")
                    Spacer()
                    TextField("예: myteam.atlassian.net", text: $jiraSiteURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)
                        .onSubmit {
                            updateSetting { $0.jiraSiteURL = jiraSiteURL }
                        }
                        .onChange(of: jiraSiteURL) { _, newValue in
                            updateSetting { $0.jiraSiteURL = newValue }
                        }
                }
                Text("Jira MCP 연동에 사용됩니다. 예: myteam.atlassian.net")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Section("Claude CLI") {
                HStack {
                    Text("CLI 경로")
                    Spacer()
                    if FileManager.default.fileExists(atPath: "/usr/local/bin/claude") {
                        Label("설치됨", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    } else {
                        Label("미설치", systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Background Tab

    private var backgroundTab: some View {
        BackgroundSettingsView()
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "#FFB6C1"), Color(hex: "#E6E6FA")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("ContextBoard")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Text("작업 컨텍스트 스위칭을 위한 macOS 미니 앱")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("v1.0.0")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding(30)
    }

    // MARK: - Helpers

    private func loadSettings() {
        guard let settings else { return }
        launchAtLogin = settings.launchAtLogin
        gridSnap = settings.gridSnapEnabled
        hotkey = settings.globalHotkey ?? "Cmd+Shift+B"
        jiraSiteURL = settings.jiraSiteURL
    }

    private func updateSetting(_ update: (BoardSettings) -> Void) {
        do {
            let s = try BoardSettings.getOrCreate(in: modelContext)
            update(s)
            try modelContext.save()
        } catch {
            print("[Settings] 설정 저장 실패: \(error.localizedDescription)")
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            updateSetting { $0.launchAtLogin = enabled }
        } catch {
            print("[Settings] 로그인 시 실행 설정 실패: \(error.localizedDescription)")
            launchAtLogin = !enabled // 롤백
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [BoardSettings.self], inMemory: true)
}
