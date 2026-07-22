# AgentLaunch Doctor

[English](README.md)

macOSでローカルAIエージェントや自動処理を動かすLaunchAgentのための、読み取り専用ヘルス・プライバシー診断CLIです。

plistの妥当性、実行ファイルと作業ディレクトリ、launchctlの状態、前回終了コード、ログの鮮度、ファイル権限、再起動ループの危険、外部公開バインド、秘密情報らしい設定を点検します。各検出には秘密値を含まない次の確認手順が付きます。秘密値やログ本文は表示しません。

## 安全方針

AgentLaunch Doctorはジョブのロード、アンロード、再起動、編集、削除、修復を行いません。Keychain、ブラウザ、メール、チャット、ログ本文を読みません。診断結果をサーバーやAIサービスへ送信しません。

共有用レポートには必ず `--strict` を付け、出力内容を目視確認してください。strictモードではラベルとファイル名も匿名化します。

## 使い方

対応環境はmacOS 13以降です。推奨の導入方法は、Xcode 15以降を使って公開済みタグのソースをMac上でビルドするHomebrew版です。

```bash
brew install pastorstephan-prog/tap/agentlaunch-doctor
agentlaunch-doctor --all-user-agents
```

Homebrewを使わない場合は、Swift 5.9以降でソースから実行できます。

```bash
git clone https://github.com/pastorstephan-prog/agentlaunch-doctor.git
cd agentlaunch-doctor
swift run agentlaunch-doctor --all-user-agents
```

GitHub ReleasesのUniversalバイナリはad-hoc署名で、Appleの公証は未取得です。別のMacではGatekeeperに止められる場合があるため、その場合はHomebrew版を利用してください。macOSのセキュリティ確認を回避する操作は案内しません。

共有用JSONレポート:

```bash
swift run agentlaunch-doctor --all-user-agents --strict --format json > report.json
```

high判定が1件以上あれば終了コードは `1`、問題がなければ `0`、使い方の誤りは `2` です。

## 外部ベータ

現在は、標準テレメトリーを使わず、確認済み修正、high誤判定、再利用を測る外部ベータ段階です。フィードバック前に[BETA.md](BETA.md)を確認してください。公開Issueには集計数と検出コードだけを記載し、plist本文、ラベル、パス、ログ、秘密情報は投稿しないでください。

詳細な診断項目、開発方法、ライセンスは[英語README](README.md)を参照してください。
