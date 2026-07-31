/// macOS 標準の「アプリを隠す」Command-H を無効化する判定。
public enum CommandHideShortcutMatcher {
    /// macOS の仮想キーコード（ANSI H）。
    public static let keyCodeH: UInt16 = 4

    /// 通常アプリの修飾なし Command-H だけを対象とする。
    ///
    /// ターミナル内では Command / Control 交換後の Command-H を Herdr などへ
    /// そのまま渡すため対象外にする。
    public static func matches(
        keyCode: UInt16,
        modifiers: CopyPasteModifiers,
        isTerminal: Bool
    ) -> Bool {
        !isTerminal
            && keyCode == keyCodeH
            && modifiers == [.command]
    }
}
