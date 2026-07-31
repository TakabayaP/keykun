import CoreGraphics
import KeykunCore

/// CGEvent の修飾キーフラグを、CoreGraphics に依存しない判定用の値へ変換する。
func shortcutModifiers(from flags: CGEventFlags) -> CopyPasteModifiers {
    var modifiers: CopyPasteModifiers = []
    if flags.contains(.maskControl) { modifiers.insert(.control) }
    if flags.contains(.maskShift) { modifiers.insert(.shift) }
    if flags.contains(.maskAlternate) { modifiers.insert(.option) }
    if flags.contains(.maskCommand) { modifiers.insert(.command) }
    return modifiers
}
