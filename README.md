# Keykun

macOS 用のキー操作カスタマイズツール（メニューバー常駐アプリ）。現在は次の機能に絞っています。

- 左右の修飾キー単押しによる入力モード切り替え（英数 / かな）
- Slack が最前面のときの Esc → Ctrl-G 置き換え（SKK 向け）
- ログイン時の自動起動

キー入力は `CGEventTap` で監視します。アクセシビリティ権限が必要です。

## 設定

メニューバーのアイコン →「設定…」で設定ダイアログを開きます。

設定は `~/Library/Application Support/Keykun/settings.json` に保存されます。過去のバージョンで保存された
`safeQuit` や `modifierDoublePress` などの削除済み設定キーは無視されます。

### 入力切り替え

「入力切り替え」タブで、対象の修飾キーを単独で押して離したときに送るキーを設定できます。
組み合わせ操作では通常どおり修飾キーとして機能します。

- 左右それぞれに「英数」「かな」「なし」を割り当て
- 単押しの判定時間を変更
- 既定は無効

### Slack Esc

「Slack Esc」タブで有効にすると、Slack が最前面のときだけ修飾キーなしの Esc を握りつぶし、
代わりに Ctrl-G を送ります。SKK のキャンセル操作を Slack の Esc ショートカットと分離するための設定です。

## 多言語対応

GUI は日本語・英語に対応します。文字列は `Sources/Keykun/Resources/{en,ja}.lproj/Localizable.strings` に定義し、
`L.string` / `L.format` で参照します。詳細な開発ルールは [CLAUDE.md](CLAUDE.md) を参照してください。

## 構成

テスト可能なコアとアプリ本体を SwiftPM で分離しています。

```
Sources/
  KeykunCore/               純粋ロジックと設定モデル
    ModifierTapDetector.swift 左右修飾キーの単押し検知
    Settings.swift             設定モデル
    SettingsStore.swift        JSON 永続化
  Keykun/                   アプリ本体
    main.swift / AppDelegate.swift
    KeyEventTap.swift           CGEventTap の共有
    InputSwitchHandler.swift    入力切り替え
    SlackEscapeHandler.swift    Slack 前面時の Esc→Ctrl-G
    InputModeKey.swift          英数/かなキー送出
    AccessibilityPermission.swift
    StatusBarController.swift   メニューバー UI
    SettingsWindowController.swift / SettingsView.swift
    Localization.swift
    Resources/{en,ja}.lproj/Localizable.strings
Tests/KeykunCoreTests/      コアロジック・設定・永続化のテスト
Resources/Info.plist        バンドル情報
Scripts/bundle.sh           .app 生成 + 署名
```

## ビルド・テスト

```sh
swift build
swift test
bash Scripts/bundle.sh
```

ビルド成果物は `Keykun.app`（Bundle ID: `com.mtkg.keykun`）です。

## インストール

ビルドした `Keykun.app` を `/Applications` に置いて起動します。初回起動時に、システム設定の
「プライバシーとセキュリティ › アクセシビリティ」で Keykun を許可してください。

アップデートは自動確認しません。必要なときにこのリポジトリを更新して再ビルドします。
