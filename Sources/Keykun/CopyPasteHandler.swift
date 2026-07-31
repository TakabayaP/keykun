import AppKit
import CoreGraphics
import KeykunCore
import OSLog

private let copyPasteLog = Logger(subsystem: "com.mtkg.keykun", category: "CopyPaste")

/// Ctrl ベースのコピー/ペーストを、macOS アプリが理解する Command ショートカットへ変換する。
///
/// 通常アプリでは Ctrl-C/V を変換する。ターミナルでは Ctrl-C（割り込み）と Ctrl-V
/// （Vim の矩形選択など）を保護し、Linux と同じ Ctrl-Shift-C/V だけを変換する。
@MainActor
final class CopyPasteHandler: KeyEventHandler {
    private var settings = CopyPasteSettings()
    private var consumedKeyUps: Set<CGKeyCode> = []

    private let terminalBundleIdentifiers: Set<String> = [
        "com.apple.Terminal",
        "com.github.wez.wezterm",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "com.mitchellh.ghostty-debug",
        "dev.warp.Warp",
        "dev.warp.Warp-Stable",
        "net.kovidgoyal.kitty",
        "org.alacritty",
    ]

    func update(_ settings: CopyPasteSettings) {
        self.settings = settings
        if !settings.isEnabled {
            consumedKeyUps.removeAll()
        }
    }

    func handle(type: CGEventType, event: CGEvent) -> Bool {
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        if type == .keyUp, consumedKeyUps.remove(keyCode) != nil {
            return true
        }

        guard settings.isEnabled, type == .keyDown else { return false }

        let modifiers = copyPasteModifiers(from: event.flags)
        guard let shortcut = CopyPasteShortcutMatcher.match(
            keyCode: keyCode,
            modifiers: modifiers,
            isTerminal: isTerminalFrontmost
        ) else {
            return false
        }

        consumedKeyUps.insert(keyCode)
        DispatchQueue.main.async {
            Self.postCommandShortcut(shortcut)
        }
        return true
    }

    func reset() {
        consumedKeyUps.removeAll()
    }

    private var isTerminalFrontmost: Bool {
        guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return false
        }
        return terminalBundleIdentifiers.contains(bundleIdentifier)
    }

    private func copyPasteModifiers(from flags: CGEventFlags) -> CopyPasteModifiers {
        var modifiers: CopyPasteModifiers = []
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskCommand) { modifiers.insert(.command) }
        return modifiers
    }

    private nonisolated static func postCommandShortcut(_ shortcut: CopyPasteShortcut) {
        let keyCode: CGKeyCode
        switch shortcut {
        case .copy:
            keyCode = CGKeyCode(CopyPasteShortcutMatcher.keyCodeC)
        case .paste:
            keyCode = CGKeyCode(CopyPasteShortcutMatcher.keyCodeV)
        }

        let source = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else {
            copyPasteLog.error("failed to create Command clipboard shortcut")
            return
        }

        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
