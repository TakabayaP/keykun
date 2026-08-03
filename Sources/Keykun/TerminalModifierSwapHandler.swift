import AppKit
import KeykunCore

/// ターミナルが最前面のときだけ Command と Control を交換する。
///
/// InputSwitchHandler が元の flagsChanged を観測した後に実行することで、
/// Command 単押しの英数/かな切り替えと両立する。
@MainActor
final class TerminalModifierSwapHandler: KeyEventHandler {
    private var settings = TerminalModifierSwapSettings()

    func update(_ settings: TerminalModifierSwapSettings) {
        self.settings = settings
    }

    func handle(type: CGEventType, event: CGEvent) -> Bool {
        guard settings.isEnabled,
              TerminalApplication.isFrontmost,
              !SyntheticEvent.bypassesTerminalModifierSwap(event)
        else {
            return false
        }

        guard type == .keyDown || type == .keyUp || type == .flagsChanged else {
            return false
        }

        if type == .keyDown || type == .keyUp {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            guard TerminalModifierSwap.shouldSwapKeyEventKeyCode(keyCode) else {
                // macSKK の Hiragana キーを Ctrl-J に統一する。修飾キー自体の
                // flagsChanged は交換済みなので、Herdr の held-prefix は
                // prefix+ctrl+j として別名登録する。
                return false
            }
        }

        event.flags = CGEventFlags(
            rawValue: TerminalModifierSwap.swapFlags(event.flags.rawValue)
        )

        if type == .flagsChanged {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            event.setIntegerValueField(
                .keyboardEventKeycode,
                value: TerminalModifierSwap.swapKeyCode(keyCode)
            )
        }

        // イベント自体を書き換えて後段へ渡すため、消費はしない。
        return false
    }
}
