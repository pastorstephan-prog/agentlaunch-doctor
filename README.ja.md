# AgentLaunch Doctor

[English](README.md)

macOSでローカルAIエージェントや自動処理を動かすLaunchAgentのための、読み取り専用ヘルス・プライバシー診断CLIです。

plistの妥当性、実行ファイルと作業ディレクトリ、launchctlの状態、前回終了コード、ログの鮮度、ファイル権限、再起動ループの危険、外部公開バインド、秘密情報らしい設定を点検します。秘密値やログ本文は表示しません。

## 安全方針

AgentLaunch Doctorはジョブのロード、アンロード、再起動、編集、削除、修復を行いません。Keychain、ブラウザ、メール、チャット、ログ本文を読みません。診断結果をサーバーやAIサービスへ送信しません。

共有用レポートには必ず `--strict` を付け、出力内容を目視確認してください。strictモードではラベルとファイル名も匿名化します。

## 使い方

対応環境はmacOS 13以降です。GitHub ReleasesからUniversalバイナリを取得するか、Swift 5.9以降でソースから実行できます。

```bash
git clone https://github.com/pastorstephan-prog/agentlaunch-doctor.git
cd agentlaunch-doctor
swift run agentlaunch-doctor --all-user-agents
```

共有用JSONレポート:

```bash
swift run agentlaunch-doctor --all-user-agents --strict --format json > report.json
```

high判定が1件以上あれば終了コードは `1`、問題がなければ `0`、使い方の誤りは `2` です。

詳細な診断項目、開発方法、ライセンスは[英語README](README.md)を参照してください。
