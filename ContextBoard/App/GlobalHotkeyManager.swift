import Carbon
import AppKit

/// 글로벌 핫키를 등록/해제하는 매니저입니다.
/// Carbon API (RegisterEventHotKey)를 사용합니다.
/// Phase 4에서 HotKey SPM 패키지로 교체할 수 있습니다.
@MainActor
final class GlobalHotkeyManager {

    static let shared = GlobalHotkeyManager()

    struct HotkeyPreset {
        let label: String
        let keyCode: UInt32
        let modifiers: UInt32
    }

    static let presets: [HotkeyPreset] = [
        HotkeyPreset(label: "Cmd+Shift+B", keyCode: UInt32(kVK_ANSI_B), modifiers: UInt32(cmdKey | shiftKey)),
        HotkeyPreset(label: "Cmd+Shift+C", keyCode: UInt32(kVK_ANSI_C), modifiers: UInt32(cmdKey | shiftKey)),
        HotkeyPreset(label: "Cmd+Shift+X", keyCode: UInt32(kVK_ANSI_X), modifiers: UInt32(cmdKey | shiftKey)),
        HotkeyPreset(label: "Cmd+Option+B", keyCode: UInt32(kVK_ANSI_B), modifiers: UInt32(cmdKey | optionKey)),
        HotkeyPreset(label: "Cmd+Ctrl+B", keyCode: UInt32(kVK_ANSI_B), modifiers: UInt32(cmdKey | controlKey)),
    ]

    private var hotkeyRef: EventHotKeyRef?
    private var onToggle: (() -> Void)?

    private init() {}

    /// 글로벌 핫키를 등록합니다.
    /// - Parameters:
    ///   - keyCode: 키 코드 (예: kVK_ANSI_B = 11)
    ///   - modifiers: 수정자 플래그 (예: cmdKey + shiftKey)
    ///   - handler: 핫키가 눌렸을 때 호출되는 클로저
    func register(
        keyCode: UInt32 = UInt32(kVK_ANSI_B),
        modifiers: UInt32 = UInt32(cmdKey | shiftKey),
        handler: @escaping () -> Void
    ) {
        self.onToggle = handler

        // 이벤트 핸들러 설치
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                Task { @MainActor in
                    GlobalHotkeyManager.shared.onToggle?()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        // 핫키 등록
        let hotkeyID = EventHotKeyID(signature: OSType(0x4342), id: 1) // "CB" = ContextBoard
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr {
            self.hotkeyRef = hotKeyRef
            print("[GlobalHotkey] 핫키 등록 성공: Cmd+Shift+B")
        } else {
            print("[GlobalHotkey] 핫키 등록 실패: \(status)")
        }
    }

    /// 프리셋 라벨로 핫키를 재등록합니다.
    func reregister(presetLabel: String) {
        guard let preset = Self.presets.first(where: { $0.label == presetLabel }),
              let handler = onToggle else { return }
        unregister()
        register(keyCode: preset.keyCode, modifiers: preset.modifiers, handler: handler)
    }

    /// 등록된 핫키를 해제합니다.
    func unregister() {
        guard let ref = hotkeyRef else { return }
        UnregisterEventHotKey(ref)
        hotkeyRef = nil
        print("[GlobalHotkey] 핫키 해제됨")
    }
}
