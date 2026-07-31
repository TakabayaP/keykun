/// コピー/ペースト変換で扱う修飾キー。CoreGraphics に依存しない純粋な判定に使う。
public struct CopyPasteModifiers: OptionSet, Equatable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let control = CopyPasteModifiers(rawValue: 1 << 0)
    public static let shift = CopyPasteModifiers(rawValue: 1 << 1)
    public static let option = CopyPasteModifiers(rawValue: 1 << 2)
    public static let command = CopyPasteModifiers(rawValue: 1 << 3)
}

/// Command ショートカットとして送出するクリップボード操作。
public enum CopyPasteShortcut: Equatable {
    case copy
    case paste
}

/// アプリ種別と修飾キーから、コピー/ペースト変換を行うか決める純粋ロジック。
public enum CopyPasteShortcutMatcher {
    /// macOS の仮想キーコード（ANSI C / V）。
    public static let keyCodeC: UInt16 = 8
    public static let keyCodeV: UInt16 = 9

    /// 通常アプリでは Ctrl-C/V、ターミナルでは Linux と同じ Ctrl-Shift-C/V だけを変換する。
    public static func match(
        keyCode: UInt16,
        modifiers: CopyPasteModifiers,
        isTerminal: Bool
    ) -> CopyPasteShortcut? {
        let expectedModifiers: CopyPasteModifiers = isTerminal
            ? [.control, .shift]
            : [.control]
        guard modifiers == expectedModifiers else { return nil }

        switch keyCode {
        case keyCodeC:
            return .copy
        case keyCodeV:
            return .paste
        default:
            return nil
        }
    }
}
