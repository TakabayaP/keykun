import Foundation

/// アプリ全体の設定。機能ごとにサブ構造体を持ち、機能追加時はここにプロパティを足して拡張する。
///
/// 前方/後方互換のため Codable は欠損キーを既定値で補完する（古い/新しい設定ファイルでも壊れない）。
public struct Settings: Codable, Equatable {
    /// 「入力切り替え」（左右⌘単押し）機能の設定。
    public var inputSwitch: InputSwitchSettings
    /// 「Slack の Esc を SKK キャンセルへ変換」機能の設定。
    public var slackEscape: SlackEscapeSettings

    public init(
        inputSwitch: InputSwitchSettings = InputSwitchSettings(),
        slackEscape: SlackEscapeSettings = SlackEscapeSettings()
    ) {
        self.inputSwitch = inputSwitch
        self.slackEscape = slackEscape
    }

    /// 既定設定。
    public static let `default` = Settings()

    private enum CodingKeys: String, CodingKey {
        case inputSwitch
        case slackEscape
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.inputSwitch = try container.decodeIfPresent(InputSwitchSettings.self, forKey: .inputSwitch)
            ?? InputSwitchSettings()
        self.slackEscape = try container.decodeIfPresent(SlackEscapeSettings.self, forKey: .slackEscape)
            ?? SlackEscapeSettings()
    }
}

/// 左右 Command 単押し時に送出するキー（Karabiner 方式）。
/// 入力ソース選択ではなく、英数/かなキーの信号を送って IME のモードを切り替える。
public enum InputSwitchAction: String, Codable, Equatable, CaseIterable {
    /// 何もしない。
    case none
    /// 「英数」キー（英語入力へ）。
    case eisu
    /// 「かな」キー（日本語入力へ）。
    case kana
}

/// 「入力切り替え」機能の設定。左右修飾キーの単押しに、それぞれ送出キー（英数/かな）を割り当てる。
public struct InputSwitchSettings: Codable, Equatable {
    /// 機能の有効/無効。
    public var isEnabled: Bool
    /// 単押しを検知する修飾キーの種別。
    public var targetModifier: TargetModifier
    /// 左側単押しで送出するキー。
    public var leftAction: InputSwitchAction
    /// 右側単押しで送出するキー。
    public var rightAction: InputSwitchAction
    /// 単押しとみなす最大押下時間（秒）。
    public var tapThreshold: TimeInterval

    public init(
        isEnabled: Bool = false,
        targetModifier: TargetModifier = .option,
        leftAction: InputSwitchAction = .eisu,
        rightAction: InputSwitchAction = .kana,
        tapThreshold: TimeInterval = 0.5
    ) {
        self.isEnabled = isEnabled
        self.targetModifier = targetModifier
        self.leftAction = leftAction
        self.rightAction = rightAction
        self.tapThreshold = tapThreshold
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
        case targetModifier
        case leftAction
        case rightAction
        case tapThreshold
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = InputSwitchSettings()
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled)
            ?? defaults.isEnabled
        self.targetModifier = try container.decodeIfPresent(TargetModifier.self, forKey: .targetModifier)
            ?? defaults.targetModifier
        self.leftAction = try container.decodeIfPresent(InputSwitchAction.self, forKey: .leftAction)
            ?? defaults.leftAction
        self.rightAction = try container.decodeIfPresent(InputSwitchAction.self, forKey: .rightAction)
            ?? defaults.rightAction
        self.tapThreshold = try container.decodeIfPresent(TimeInterval.self, forKey: .tapThreshold)
            ?? defaults.tapThreshold
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(targetModifier, forKey: .targetModifier)
        try container.encode(leftAction, forKey: .leftAction)
        try container.encode(rightAction, forKey: .rightAction)
        try container.encode(tapThreshold, forKey: .tapThreshold)
    }

    /// 指定サイドに割り当てられた送出キー。
    public func action(for side: ModifierSide) -> InputSwitchAction {
        switch side {
        case .left: return leftAction
        case .right: return rightAction
        }
    }
}

/// 入力切り替えの対象とする修飾キーの種別。
/// 左右の判別に使う device 依存フラグビット（IOLLEvent.h の NX_DEVICE*KEYMASK）を持つ。
public enum TargetModifier: String, Codable, Equatable, CaseIterable {
    case command
    case option
    case control
    case shift

    /// 左側キーの device 依存フラグビット。
    public var leftBit: UInt64 {
        switch self {
        case .command: return 0x0000_0008  // NX_DEVICELCMDKEYMASK
        case .option: return 0x0000_0020   // NX_DEVICELALTKEYMASK
        case .control: return 0x0000_0001  // NX_DEVICELCTLKEYMASK
        case .shift: return 0x0000_0002    // NX_DEVICELSHIFTKEYMASK
        }
    }

    /// 右側キーの device 依存フラグビット。
    public var rightBit: UInt64 {
        switch self {
        case .command: return 0x0000_0010  // NX_DEVICERCMDKEYMASK
        case .option: return 0x0000_0040   // NX_DEVICERALTKEYMASK
        case .control: return 0x0000_2000  // NX_DEVICERCTLKEYMASK
        case .shift: return 0x0000_0004    // NX_DEVICERSHIFTKEYMASK
        }
    }
}


/// Slack が最前面のときだけ Esc を Ctrl-G に置き換える設定。
///
/// SKK 系 IME では Ctrl-G がキャンセル操作として使われるため、Slack 側の Esc ショートカットを発火させずに
/// SKK のキャンセル操作だけを成立させるための回避策として使う。
public struct SlackEscapeSettings: Codable, Equatable {
    /// 機能の有効/無効。
    public var isEnabled: Bool

    public init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    private enum CodingKeys: String, CodingKey {
        case isEnabled
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = SlackEscapeSettings()
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled)
            ?? defaults.isEnabled
    }
}
