import SwiftUI

/// 글로벌 핫키를 설정하는 뷰입니다.
/// Phase 4에서 HotKey SPM 패키지와 연동될 예정입니다.
struct HotkeySettingsView: View {
    @State private var currentHotkey = "Cmd+Shift+B"
    @State private var isRecording = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("글로벌 단축키")
                .font(.system(size: 13, weight: .semibold, design: .rounded))

            HStack(spacing: 12) {
                Text("보드 토글:")
                    .font(.system(size: 12))

                Button {
                    isRecording.toggle()
                } label: {
                    HStack(spacing: 4) {
                        if isRecording {
                            Image(systemName: "record.circle")
                                .foregroundStyle(.red)
                            Text("키 입력 대기 중...")
                                .font(.system(size: 11))
                        } else {
                            Text(currentHotkey)
                                .font(.system(size: 12, design: .monospaced))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isRecording ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                            .stroke(isRecording ? Color.red.opacity(0.3) : Color.gray.opacity(0.2))
                    )
                }
                .buttonStyle(.plain)
            }

            Text("보드 창을 표시/숨기기하는 전역 단축키입니다.\n(Phase 4에서 구현 예정)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

#Preview {
    HotkeySettingsView()
        .padding(20)
}
