# AgentLaunch Doctor

[English](README.md)

macOSでローカルAIエージェントや自動処理を動かすLaunchAgentのための、読み取り専用ヘルス・プライバシー診断CLIです。

plistの妥当性、実行ファイルと作業ディレクトリ、launchctlの状態、前回終了コード、ログの鮮度、ファイル権限、再起動ループの危険、外部公開バインド、秘密情報らしい設定を点検します。各検出には秘密値を含まない次の確認手順が付きます。秘密値やログ本文は表示しません。

## 安全方針

AgentLaunch Doctorはジョブのロード、アンロード、再起動、編集、削除、修復を行いません。Keychain、ブラウザ、メール、チャット、ログ本文を読みません。診断結果をサーバーやAIサービスへ送信しません。

公開ベータへの報告には `--format feedback` を使ってください。strict匿名化が自動で有効になり、版、集計数、検出コードだけを出力します。それ以外のレポートを共有する場合は必ず `--strict` を付けてください。

## 使い方

3分ベータ手順の前提はmacOS 13以降、Homebrew、Xcode 15以降です。推奨のHomebrew版は公開済みタグのソースをMac上でビルドします。

```bash
brew install pastorstephan-prog/tap/agentlaunch-doctor
agentlaunch-doctor --all-user-agents --format feedback
```

終了コード `1` はインストール失敗ではなく、診断が完了しhigh判定が1件以上あったという意味です。詳細はローカルで `agentlaunch-doctor --all-user-agents` を実行して確認し、公開Issueには[初回ベータ報告フォーム](https://github.com/pastorstephan-prog/agentlaunch-doctor/issues/new?template=beta-activation.yml)から最小出力だけを記載してください。

Homebrewを使わない場合は、Swift 5.9以降でソースから実行できます。

```bash
git clone https://github.com/pastorstephan-prog/agentlaunch-doctor.git
cd agentlaunch-doctor
swift run agentlaunch-doctor --all-user-agents
```

GitHub ReleasesのUniversalバイナリはad-hoc署名で、Appleの公証は未取得です。別のMacではGatekeeperに止められる場合があるため、その場合はHomebrew版を利用してください。macOSのセキュリティ確認を回避する操作は案内しません。

公開ベータ用の最小レポート:

```bash
agentlaunch-doctor --all-user-agents --format feedback
```

high判定が1件以上あれば終了コードは `1`、問題がなければ `0`、使い方の誤りは `2` です。

## 外部ベータ

現在は、標準テレメトリーを使わず、外部利用開始、確認済み修正、high誤判定、再利用を測る段階です。フィードバック前に[日本語ベータ案内](BETA.ja.md)を確認してください。公開Issueには集計数と検出コードだけを記載し、plist本文、ラベル、パス、ログ、スクリーンショット、秘密情報は投稿しないでください。

詳細な診断項目、開発方法、ライセンスは[英語README](README.md)を参照してください。
