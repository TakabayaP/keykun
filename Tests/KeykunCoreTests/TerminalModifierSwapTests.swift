import XCTest
@testable import KeykunCore

final class TerminalModifierSwapTests: XCTestCase {
    func testCommandFlagsBecomeControlFlags() {
        let input = TerminalModifierSwap.command | TerminalModifierSwap.leftCommand
        let expected = TerminalModifierSwap.control | TerminalModifierSwap.leftControl

        XCTAssertEqual(TerminalModifierSwap.swapFlags(input), expected)
    }

    func testControlFlagsBecomeCommandFlags() {
        let input = TerminalModifierSwap.control | TerminalModifierSwap.rightControl
        let expected = TerminalModifierSwap.command | TerminalModifierSwap.rightCommand

        XCTAssertEqual(TerminalModifierSwap.swapFlags(input), expected)
    }

    func testOtherFlagsArePreserved() {
        let shift: UInt64 = 0x0002_0000
        let option: UInt64 = 0x0008_0000
        let input = shift | option | TerminalModifierSwap.command | TerminalModifierSwap.control

        XCTAssertEqual(TerminalModifierSwap.swapFlags(input), input)
    }

    func testModifierKeyCodesAreSwappedBySide() {
        XCTAssertEqual(TerminalModifierSwap.swapKeyCode(55), 59)
        XCTAssertEqual(TerminalModifierSwap.swapKeyCode(59), 55)
        XCTAssertEqual(TerminalModifierSwap.swapKeyCode(54), 62)
        XCTAssertEqual(TerminalModifierSwap.swapKeyCode(62), 54)
    }

    func testNonModifierKeyCodeIsUnchanged() {
        XCTAssertEqual(TerminalModifierSwap.swapKeyCode(3), 3)
    }

    func testCapsPositionCommandBecomesLinuxCopyShortcutBeforeMatching() {
        let physicalCapsFlags =
            TerminalModifierSwap.command
            | TerminalModifierSwap.rightCommand
            | 0x0002_0000
        let swapped = TerminalModifierSwap.swapFlags(physicalCapsFlags)
        var modifiers: CopyPasteModifiers = []
        if swapped & TerminalModifierSwap.control != 0 {
            modifiers.insert(.control)
        }
        if swapped & 0x0002_0000 != 0 {
            modifiers.insert(.shift)
        }

        XCTAssertEqual(
            CopyPasteShortcutMatcher.match(
                keyCode: CopyPasteShortcutMatcher.keyCodeC,
                modifiers: modifiers,
                isTerminal: true
            ),
            .copy
        )
    }
}
