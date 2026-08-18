/// ターミナル内で Command と Control を交換するための純粋ロジック。
///
/// CGEventFlags への依存を避け、汎用フラグと左右別の device-dependent
/// フラグを UInt64 のまま交換する。
public enum TerminalModifierSwap {
    public static let control: UInt64 = 0x0004_0000
    public static let command: UInt64 = 0x0010_0000

    public static let leftControl: UInt64 = 0x0000_0001
    public static let leftCommand: UInt64 = 0x0000_0008
    public static let rightCommand: UInt64 = 0x0000_0010
    public static let rightControl: UInt64 = 0x0000_2000

    public static func swapFlags(_ rawFlags: UInt64) -> UInt64 {
        var result = rawFlags
        swapBits(control, command, in: &result)
        swapBits(leftControl, leftCommand, in: &result)
        swapBits(rightControl, rightCommand, in: &result)
        return result
    }

    public static func swapKeyCode(_ keyCode: Int64) -> Int64 {
        switch keyCode {
        case 55: return 59  // left Command -> left Control
        case 59: return 55  // left Control -> left Command
        case 54: return 62  // right Command -> right Control
        case 62: return 54  // right Control -> right Command
        default: return keyCode
        }
    }

    private static func swapBits(_ first: UInt64, _ second: UInt64, in value: inout UInt64) {
        let hasFirst = value & first != 0
        let hasSecond = value & second != 0
        value &= ~(first | second)
        if hasFirst {
            value |= second
        }
        if hasSecond {
            value |= first
        }
    }
}
