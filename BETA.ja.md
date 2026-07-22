# 30日間 外部ベータ

AgentLaunch Doctorは、読み取り専用CLIの価値を実利用で確認しています。対象はmacOSでローカルAI、開発ツール、自動処理などのユーザーLaunchAgentを3個以上運用している、プロジェクト所有者以外の方です。

## 3分で安全に参加する

HomebrewとXcode 15以降が導入済みであることを前提にします。

```bash
brew install pastorstephan-prog/tap/agentlaunch-doctor
agentlaunch-doctor --version
agentlaunch-doctor --all-user-agents --format feedback
```

`feedback` 形式はstrict匿名化を自動で有効にし、版、LaunchAgent数、重要度別件数、検出コードだけを表示します。この短い出力だけを[初回ベータ報告フォーム](https://github.com/pastorstephan-prog/agentlaunch-doctor/issues/new?template=beta-activation.yml)へ転記してください。

インストール、`--version`、診断開始のいずれかで止まった場合は、件数入力のない[導入失敗フォーム](https://github.com/pastorstephan-prog/agentlaunch-doctor/issues/new?template=beta-install-failure.yml)を使ってください。

終了コード `1` は診断成功かつhigh判定あり、`0` はhigh判定なし、`2` はコマンドの使い方の誤りです。詳細は自分のMacだけで `agentlaunch-doctor --all-user-agents` を実行して確認してください。

公開Issueに完全なtext/JSONレポート、plist、ラベル、ファイル名、パス、ログ、スクリーンショット、トークン、資格情報、アカウント情報を投稿しないでください。Gatekeeperの回避操作はせず、Release版が止められる場合はHomebrew版を使ってください。

## 修正後の確認

修正を試して再診断したら[追跡フォーム](https://github.com/pastorstephan-prog/agentlaunch-doctor/issues/new?template=beta-follow-up.yml)から初回Issue番号を参照してください。同じ外部利用者について、初回と追跡が結び付き、元の検出が消え、ジョブが動作している場合だけ「確認済み修正」と数えます。

## 継続判断の基準

- 外部利用開始 10人
- 3人以上から確認済み修正 5件
- 確認対象の解決率 50%以上
- high誤判定率 10%未満
- 初回から30日経過した利用者の再診断率 30%以上
- 秘密情報の流出 0件

GitHub上の同一利用者は1人として数えます。所有者自身のMac、bot、CI、clone、ダウンロードは外部利用開始に含めません。安全に匿名化できたか不明な場合は投稿しないでください。
