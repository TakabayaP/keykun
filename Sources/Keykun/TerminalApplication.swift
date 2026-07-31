import AppKit

/// Keykun がターミナルとして扱うアプリ。
@MainActor
enum TerminalApplication {
    private static let bundleIdentifiers: Set<String> = [
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

    static var isFrontmost: Bool {
        guard let bundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            return false
        }
        return bundleIdentifiers.contains(bundleIdentifier)
    }
}
