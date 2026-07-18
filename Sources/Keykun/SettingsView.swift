import SwiftUI
import AppKit
import KeykunCore

/// 設定ダイアログの編集状態。編集は作業コピー上で行い、Apply/OK で確定する。
@MainActor
final class SettingsViewModel: ObservableObject {
    /// 編集中の作業コピー。
    @Published var settings: KeykunCore.Settings
    /// 直近に確定（Apply/OK）した内容。Cancel 時の復帰先。
    private var committed: KeykunCore.Settings
    private let onApply: (KeykunCore.Settings) -> Void

    init(settings: KeykunCore.Settings, onApply: @escaping (KeykunCore.Settings) -> Void) {
        self.settings = settings
        self.committed = settings
        self.onApply = onApply
    }

    /// 未確定の変更があるか。
    var hasChanges: Bool { settings != committed }

    /// 作業コピーを確定し保存・反映する。
    func apply() {
        committed = settings
        onApply(settings)
    }

    /// 未確定の変更を破棄して直近の確定内容に戻す。
    func revert() {
        settings = committed
    }
}

/// 設定ダイアログ本体。タブで機能ごとの設定を切り替える。
/// 今後キー機能を増やす場合は、TabView 内にタブを追加する。
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject var loginItem: LoginItemController
    let onClose: () -> Void

    @State private var loginItemError: String?

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                GeneralSettingsTab(loginItem: loginItem, errorMessage: $loginItemError)
                    .tabItem { Text(L.string("tab.general")) }

                InputSwitchSettingsTab(settings: $viewModel.settings.inputSwitch)
                    .tabItem { Text(L.string("tab.input_switch")) }

                SlackEscapeSettingsTab(settings: $viewModel.settings.slackEscape)
                    .tabItem { Text(L.string("tab.slack_escape")) }
                // 将来のキー機能タブはここに追加する。
            }
            .padding()

            Divider()

            HStack {
                Spacer()
                Button(L.string("button.cancel")) {
                    viewModel.revert()
                    onClose()
                }
                .keyboardShortcut(.cancelAction)

                Button(L.string("button.apply")) {
                    viewModel.apply()
                }
                .disabled(!viewModel.hasChanges)

                Button(L.string("button.ok")) {
                    viewModel.apply()
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 520, height: 420)
        .alert(L.string("alert.error.title"), isPresented: Binding(
            get: { loginItemError != nil },
            set: { if !$0 { loginItemError = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(loginItemError ?? "")
        }
    }
}

/// 「Slack Esc」タブ。Slack が最前面のときだけ Esc を Ctrl-G に置き換える。
struct SlackEscapeSettingsTab: View {
    @SwiftUI.Binding var settings: SlackEscapeSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle(isOn: $settings.isEnabled) {
                Text(L.string("slack_escape.enabled"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(L.string("slack_escape.description"))
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// 「一般」タブ。ログイン時の自動起動とバージョン表示。
struct GeneralSettingsTab: View {
    @ObservedObject var loginItem: LoginItemController
    @SwiftUI.Binding var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // ログイン項目はシステム側が source of truth。トグル操作で即時反映する。
            Toggle(L.string("settings.launch_at_login"), isOn: Binding(
                get: { loginItem.isEnabled },
                set: { newValue in
                    if let message = loginItem.setEnabled(newValue) {
                        errorMessage = message
                    }
                }
            ))

            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            Text(L.format("settings.version", version))
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// 「入力切り替え」タブ。左右修飾キーの単押しに送出キー（英数/かな）を割り当てる。
struct InputSwitchSettingsTab: View {
    @SwiftUI.Binding var settings: InputSwitchSettings

    /// 単押しとみなす最大押下時間の候補（秒）。
    private let thresholdOptions: [TimeInterval] = [0.3, 0.5, 0.7, 1.0]

    private var modifierSymbol: String {
        switch settings.targetModifier {
        case .command: return "⌘"
        case .option: return "⌥"
        case .control: return "⌃"
        case .shift: return "⇧"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle(isOn: $settings.isEnabled) {
                Text(L.string("input_switch.enabled"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .firstTextBaseline) {
                Text(L.string("input_switch.modifier"))
                Spacer(minLength: 12)
                Picker("", selection: $settings.targetModifier) {
                    Text(L.string("modifier.command")).tag(TargetModifier.command)
                    Text(L.string("modifier.option")).tag(TargetModifier.option)
                    Text(L.string("modifier.control")).tag(TargetModifier.control)
                    Text(L.string("modifier.shift")).tag(TargetModifier.shift)
                }
                .labelsHidden()
                .frame(width: 200)
                .disabled(!settings.isEnabled)
            }

            actionPicker(
                title: L.format("input_switch.left_dynamic", modifierSymbol),
                selection: $settings.leftAction
            )
            actionPicker(
                title: L.format("input_switch.right_dynamic", modifierSymbol),
                selection: $settings.rightAction
            )

            HStack(alignment: .firstTextBaseline) {
                Text(L.string("input_switch.threshold"))
                Spacer(minLength: 12)
                Picker("", selection: $settings.tapThreshold) {
                    ForEach(thresholdOptions, id: \.self) { value in
                        Text(L.format("common.seconds", value)).tag(value)
                    }
                }
                .labelsHidden()
                .frame(width: 110)
                .disabled(!settings.isEnabled)
            }

            Text(L.string("input_switch.description"))
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// 送出キー選択 Picker（なし / 英数 / かな）。
    private func actionPicker(title: String, selection: SwiftUI.Binding<InputSwitchAction>) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
            Spacer(minLength: 12)
            Picker("", selection: selection) {
                Text(L.string("input_switch.action.none")).tag(InputSwitchAction.none)
                Text(L.string("input_switch.action.eisu")).tag(InputSwitchAction.eisu)
                Text(L.string("input_switch.action.kana")).tag(InputSwitchAction.kana)
            }
            .labelsHidden()
            .frame(width: 200)
            .disabled(!settings.isEnabled)
        }
    }
}
