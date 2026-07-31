import AppKit
import CoreGraphics
import KeykunCore

/// 通常アプリで macOS 標準の Command-H（アプリを隠す）を無効化する。
///
/// ターミナル内では Command / Control 交換へ渡すため、Command-H を消費しない。
@MainActor
final class CommandHideHandler: KeyEventHandler {
    private var settings = CommandShortcutSettings()
    private var consumedKeyUps: Set<CGKeyCode> = []

    func update(_ settings: CommandShortcutSettings) {
        self.settings = settings
        if !settings.disableHide {
            consumedKeyUps.removeAll()
        }
    }

    func handle(type: CGEventType, event: CGEvent) -> Bool {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        if type == .keyUp, consumedKeyUps.remove(keyCode) != nil {
            return true
        }

        guard settings.disableHide,
              type == .keyDown,
              CommandHideShortcutMatcher.matches(
                  keyCode: keyCode,
                  modifiers: shortcutModifiers(from: event.flags),
                  isTerminal: TerminalApplication.isFrontmost
              )
        else {
            return false
        }

        consumedKeyUps.insert(keyCode)
        return true
    }

    func reset() {
        consumedKeyUps.removeAll()
    }
}
