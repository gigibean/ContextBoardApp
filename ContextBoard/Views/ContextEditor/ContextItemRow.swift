import SwiftUI
import AppKit

/// 컨텍스트 에디터 내에서 개별 아이템을 표시하는 행 뷰입니다.
struct ContextItemRow: View {
    @Binding var item: ContextEditorViewModel.EditableItem
    let onDelete: () -> Void
    /// URL/딥링크 타입에서 모니터 선택이 가능한 첫 번째 아이템인지 여부
    var isFirstURLItem: Bool = true

    /// 파일 피커가 필요한 타입인지 여부
    private var needsBrowseButton: Bool {
        switch item.type {
        case .application, .file, .directory:
            return true
        case .webURL, .deepLink:
            return false
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                // 활성/비활성 토글
                Toggle("", isOn: $item.isEnabled)
                    .toggleStyle(.checkbox)
                    .labelsHidden()

                // 타입 선택
                Picker("", selection: $item.type) {
                    ForEach(ContextItemType.allCases, id: \.self) { type in
                        Label(type.displayName, systemImage: type.iconName)
                            .tag(type)
                    }
                }
                .frame(width: 110)

                // 라벨
                TextField("라벨", text: $item.label)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)

                // 값 (URL, bundleId, filePath)
                TextField(item.type.placeholder, text: $item.value)
                    .textFieldStyle(.roundedBorder)

                // 찾아보기 버튼 (애플리케이션/파일/폴더)
                if needsBrowseButton {
                    Button {
                        browseForItem()
                    } label: {
                        Image(systemName: "folder.badge.plus")
                            .foregroundStyle(Color(hex: "#B0E0E6"))
                    }
                    .buttonStyle(.plain)
                    .help("찾아보기")
                }

                // 삭제 버튼
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("아이템 삭제")
            }

            // 애플리케이션일 때 프로젝트 폴더 선택 행
            if item.type == .application {
                HStack(spacing: 8) {
                    Spacer()
                        .frame(width: 22)

                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(width: 110, alignment: .trailing)

                    Text("프로젝트 폴더")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    TextField("(선택) 함께 열 폴더 경로", text: $item.projectPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11))

                    Button {
                        browseForProjectFolder()
                    } label: {
                        Image(systemName: "folder.badge.plus")
                            .foregroundStyle(Color(hex: "#98FF98"))
                    }
                    .buttonStyle(.plain)
                    .help("프로젝트 폴더 선택")

                    Spacer().frame(width: 20)
                }
            }

            // 모니터 선택 행
            if NSScreen.screens.count > 1 {
                let isURLType = item.type == .webURL || item.type == .deepLink

                if !isURLType || isFirstURLItem {
                    // 앱/파일/폴더 또는 첫 번째 URL: 모니터 선택 가능
                    HStack(spacing: 8) {
                        Spacer()
                            .frame(width: 22)

                        Image(systemName: "display")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .frame(width: 110, alignment: .trailing)

                        Text("실행 모니터")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .frame(width: 100, alignment: .leading)

                        Picker("", selection: $item.preferredScreen) {
                            Text("기본").tag("")
                            ForEach(NSScreen.screens, id: \.localizedName) { screen in
                                Text(screen.localizedName).tag(screen.localizedName)
                            }
                        }
                        .font(.system(size: 11))

                        if isURLType {
                            Text("(브라우저 전체)")
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }

                        Spacer().frame(width: 20)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(item.isEnabled ? Color.clear : Color.gray.opacity(0.05))
        )
        .opacity(item.isEnabled ? 1.0 : 0.6)
    }

    // MARK: - File Picker

    private func browseForItem() {
        guard let window = NSApp.keyWindow else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = item.type != .directory
        panel.canChooseDirectories = item.type == .directory || item.type == .application
        panel.allowsMultipleSelection = false
        panel.treatsFilePackagesAsDirectories = false

        switch item.type {
        case .application:
            panel.title = "애플리케이션 선택"
            panel.directoryURL = URL(fileURLWithPath: "/Applications")
            panel.allowedContentTypes = [.application]
        case .file:
            panel.title = "파일 선택"
        case .directory:
            panel.title = "폴더 선택"
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
        default:
            return
        }

        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }

            if item.type == .application {
                if let bundle = Bundle(url: url),
                   let bundleId = bundle.bundleIdentifier {
                    item.value = bundleId
                } else {
                    item.value = url.path
                }
                if item.label.isEmpty {
                    item.label = url.deletingPathExtension().lastPathComponent
                }
            } else {
                item.value = url.path
                if item.label.isEmpty {
                    item.label = url.lastPathComponent
                }
            }
        }
    }

    private func browseForProjectFolder() {
        guard let window = NSApp.keyWindow else { return }

        let panel = NSOpenPanel()
        panel.title = "프로젝트 폴더 선택"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        panel.beginSheetModal(for: window) { response in
            guard response == .OK, let url = panel.url else { return }
            item.projectPath = url.path
        }
    }
}

#Preview {
    @Previewable @State var item = ContextEditorViewModel.EditableItem(
        type: .webURL,
        label: "Jira 티켓",
        value: "https://example.atlassian.net/browse/PROJ-1234"
    )
    ContextItemRow(item: $item, onDelete: {})
        .padding()
        .frame(width: 500)
}
