import CoreGraphics

/// Keykun が再送出するイベントを識別する。
enum SyntheticEvent {
    /// ASCII "KEYKUN"。ターミナル修飾キー交換を再適用しないための印。
    static let bypassTerminalModifierSwap: Int64 = 0x4B45_594B_554E

    static func markBypassingTerminalModifierSwap(_ event: CGEvent) {
        event.setIntegerValueField(
            .eventSourceUserData,
            value: bypassTerminalModifierSwap
        )
    }

    static func bypassesTerminalModifierSwap(_ event: CGEvent) -> Bool {
        event.getIntegerValueField(.eventSourceUserData) == bypassTerminalModifierSwap
    }
}
