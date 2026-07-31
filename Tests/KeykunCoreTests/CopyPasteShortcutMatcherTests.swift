import XCTest
@testable import KeykunCore

final class CopyPasteShortcutMatcherTests: XCTestCase {
    func testControlCMapsToCopyInRegularApplication() {
        XCTAssertEqual(
            CopyPasteShortcutMatcher.match(
                keyCode: CopyPasteShortcutMatcher.keyCodeC,
                modifiers: [.control],
                isTerminal: false
            ),
            .copy
        )
    }

    func testControlVMapsToPasteInRegularApplication() {
        XCTAssertEqual(
            CopyPasteShortcutMatcher.match(
                keyCode: CopyPasteShortcutMatcher.keyCodeV,
                modifiers: [.control],
                isTerminal: false
            ),
            .paste
        )
    }

    func testPlainControlShortcutsRemainUntouchedInTerminal() {
        XCTAssertNil(
            CopyPasteShortcutMatcher.match(
                keyCode: CopyPasteShortcutMatcher.keyCodeC,
                modifiers: [.control],
                isTerminal: true
            )
        )
        XCTAssertNil(
            CopyPasteShortcutMatcher.match(
                keyCode: CopyPasteShortcutMatcher.keyCodeV,
                modifiers: [.control],
                isTerminal: true
            )
        )
    }

    func testLinuxTerminalShortcutsMapToCopyAndPaste() {
        XCTAssertEqual(
            CopyPasteShortcutMatcher.match(
                keyCode: CopyPasteShortcutMatcher.keyCodeC,
                modifiers: [.control, .shift],
                isTerminal: true
            ),
            .copy
        )
        XCTAssertEqual(
            CopyPasteShortcutMatcher.match(
                keyCode: CopyPasteShortcutMatcher.keyCodeV,
                modifiers: [.control, .shift],
                isTerminal: true
            ),
            .paste
        )
    }

    func testOtherModifiersAndKeysAreNotMapped() {
        XCTAssertNil(
            CopyPasteShortcutMatcher.match(
                keyCode: CopyPasteShortcutMatcher.keyCodeC,
                modifiers: [.control, .option],
                isTerminal: false
            )
        )
        XCTAssertNil(
            CopyPasteShortcutMatcher.match(
                keyCode: 0,
                modifiers: [.control],
                isTerminal: false
            )
        )
    }
}
