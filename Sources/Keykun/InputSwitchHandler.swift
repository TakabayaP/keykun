import AppKit
import KeykunCore

/// 「入力切り替え」: 左右修飾キーの単押しで英数/かなキーを送出するイベントハンドラ。
///
/// 判定の核は純粋ロジック `ModifierTapDetector` に委ね、本クラスは
///   - flagsChanged から対象修飾キーの押下/解放を device 依存ビットで判定
///   - keyDown / 他修飾の同時押しでコンボ（汚染）を通知
///   - 単押し成立時に該当サイドへ割り当てた入力ソースへ切り替え
/// を担う。イベントは消費しない（通常の修飾キー操作と両立）。
@MainActor
final class InputSwitchHandler: KeyEventHandler {
    private var settings = InputSwitchSettings()
    private var detector = ModifierTapDetector(threshold: 0.3)

    /// 直近に観測した左右の押下状態。
    private var leftDown = false
    private var rightDown = false

    private var now: TimeInterval { ProcessInfo.processInfo.systemUptime }

    /// 設定を反映する。
    func update(_ settings: InputSwitchSettings) {
        self.settings = settings
        detector.threshold = settings.tapThreshold
    }

    func handle(type: CGEventType, event: CGEvent) -> Bool {
        guard settings.isEnabled else { return false }

        if type == .keyDown {
            detector.contaminate()
            return false
        }

        guard type == .flagsChanged else { return false }

        let flags = event.flags
        let target = settings.targetModifier
        let otherModifiers = hasOtherModifiers(flags: flags, excluding: target)

        // flagsChanged のキーコードは左右の物理キーを直接示す。
        // device 依存の flags ビットだけに頼ると、キーボードや macOS のイベント経路によって
        // 左右を正しく判定できないことがある。
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        if let side = modifierSide(for: keyCode, target: target) {
            let isDown = targetFlag(for: target).intersection(flags).isEmpty == false
            switch side {
            case .left:
                if isDown != leftDown {
                    if isDown {
                        detector.commandDown(side: .left, otherModifiersHeld: rightDown || otherModifiers, now: now)
                    } else if let firedSide = detector.commandUp(side: .left, now: now) {
                        fire(firedSide)
                    }
                    leftDown = isDown
                }
            case .right:
                if isDown != rightDown {
                    if isDown {
                        detector.commandDown(side: .right, otherModifiersHeld: leftDown || otherModifiers, now: now)
                    } else if let firedSide = detector.commandUp(side: .right, now: now) {
                        fire(firedSide)
                    }
                    rightDown = isDown
                }
            }
        }

        // 対象キーを押している間に別の修飾キーが加わったらコンボ扱いにする。
        if otherModifiers && (leftDown || rightDown) {
            detector.contaminate()
        }

        return false
    }

    /// flagsChanged イベントのキーコードから対象修飾キーの左右を判定する。
    private func modifierSide(for keyCode: Int64, target: TargetModifier) -> ModifierSide? {
        switch target {
        case .command:
            switch keyCode {
            case 55: return .left       // kVK_Command
            case 54: return .right      // kVK_RightCommand
            default: return nil
            }
        case .option:
            switch keyCode {
            case 58: return .left       // kVK_Option
            case 61: return .right      // kVK_RightOption
            default: return nil
            }
        case .control:
            switch keyCode {
            case 59: return .left       // kVK_Control
            case 62: return .right      // kVK_RightControl
            default: return nil
            }
        case .shift:
            switch keyCode {
            case 56: return .left       // kVK_Shift
            case 60: return .right      // kVK_RightShift
            default: return nil
            }
        }
    }

    /// 対象修飾キーが現在押されているかを示す通常のイベントフラグ。
    private func targetFlag(for target: TargetModifier) -> CGEventFlags {
        switch target {
        case .command: return .maskCommand
        case .option: return .maskAlternate
        case .control: return .maskControl
        case .shift: return .maskShift
        }
    }

    /// 対象修飾キー以外の修飾キーが押されているか判定する。
    private func hasOtherModifiers(flags: CGEventFlags, excluding target: TargetModifier) -> Bool {
        switch target {
        case .command:
            return flags.contains(.maskShift) || flags.contains(.maskControl) || flags.contains(.maskAlternate)
        case .option:
            return flags.contains(.maskShift) || flags.contains(.maskControl) || flags.contains(.maskCommand)
        case .control:
            return flags.contains(.maskShift) || flags.contains(.maskCommand) || flags.contains(.maskAlternate)
        case .shift:
            return flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskAlternate)
        }
    }

    private func fire(_ side: ModifierSide) {
        let keyCode: CGKeyCode
        switch settings.action(for: side) {
        case .none: return
        case .eisu: keyCode = InputModeKey.eisu
        case .kana: keyCode = InputModeKey.kana
        }
        // イベントタップのコールバック内で再入的に post しないよう、復帰後に送出する。
        // キー送出は軽量なので main で問題ない。
        DispatchQueue.main.async {
            InputModeKey.post(keyCode)
        }
    }

    /// イベント取りこぼし（タップ無効化）後に状態が固着しないよう、観測状態をリセットする。
    func reset() {
        leftDown = false
        rightDown = false
        detector.reset()
    }
}
