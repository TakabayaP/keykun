import XCTest
@testable import KeykunCore

final class CommandHideShortcutMatcherTests: XCTestCase {
    func testCommandHideMatchesOnlyCommandHOutsideTerminals() {
        XCTAssertTrue(
            CommandHideShortcutMatcher.matches(
                keyCode: CommandHideShortcutMatcher.keyCodeH,
                modifiers: [.command],
                isTerminal: false
            )
        )
        XCTAssertFalse(
            CommandHideShortcutMatcher.matches(
                keyCode: CommandHideShortcutMatcher.keyCodeH,
                modifiers: [.command],
                isTerminal: true
            )
        )
        XCTAssertFalse(
            CommandHideShortcutMatcher.matches(
                keyCode: CommandHideShortcutMatcher.keyCodeH,
                modifiers: [.command, .shift],
                isTerminal: false
            )
        )
        XCTAssertFalse(
            CommandHideShortcutMatcher.matches(
                keyCode: CopyPasteShortcutMatcher.keyCodeC,
                modifiers: [.command],
                isTerminal: false
            )
        )
    }
}
