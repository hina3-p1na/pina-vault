#!/usr/bin/env bash
# CLAUDE.mdの5章（日次サイクル）を実行するバッチ。
# 月曜日は6章（週次サイクル）も同じSlackスレッド内で合わせて実行する
# （6章「提案は日次サマリーと同じSlackスレッドで確認を取る」に従うため、
# 週次を別スクリプト・別スレッドに分けない）。
#
# 判定・執筆・Slack送信・状態ファイルの更新は、すべてClaude Code(-p, 非対話モード)に
# 1回のタスクとしてまとめて依頼する（auto_link.shと同じ方針：このスクリプト自身は
# 日付計算とプロンプト組み立てだけを行い、Vault内の判断はしない）。
#
# AIチャットセッションの生データは、Cowork（ブラウザ自動化担当）が
# _System/_staging/aiChat_sessions_pending.md に書き出す想定。存在しなければ0件として扱う。

set -euo pipefail

# 非ログインシェル(-c)経由だと/etc/profileが読まれず、date/dirname/mkdir/tee等の
# Git Bash標準コマンドがPATHに乗らずexit 127で即死する（実際に2026-07-25前後の
# タスクスケジューラ実行がこれで無言失敗していたことを確認済み）。ログイン有無に
# 依存しないよう、ここで明示的に通す。
export PATH="/usr/bin:/bin:/mingw64/bin:$PATH"

# タスクスケジューラ経由の実行だとPATHが通っていないことがあり、
# claudeコマンドがexit 127(command not found)で失敗する事例があったため、絶対パスで呼ぶ
CLAUDE_BIN="/c/Users/朝比奈聖海/.local/bin/claude"

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# 実行状態・ログはObsidianのノートとして表示されるべきものではないため、Vault外の専用フォルダで管理する
AUTOMATION_DIR="/c/Users/朝比奈聖海/!ai-pinas-capital/Pina-Vault-Automation"
STATE_FILE="$AUTOMATION_DIR/_state/slack_pending_confirmation.md"
LOG_FILE="$AUTOMATION_DIR/_state/daily_cycle_log.md"
# aiChat_sessions_pending.mdはCowork側が固定パスで書き込む受け渡しファイルのため、Vault内の現在地のまま変更しない
STAGING_FILE="$VAULT_ROOT/_System/_staging/aiChat_sessions_pending.md"
NOTION_MTG_DATA_SOURCE="collection://35bf60ae-f36f-80ae-a2c9-000b82d1a3eb"
NOTION_TRASH_PAGE_ID="3a5f60ae-f36f-813c-a076-d467a09412bb"
SLACK_CHANNEL_ID="C0BHK5MA0F7"

mkdir -p "$AUTOMATION_DIR/_state" "$VAULT_ROOT/_System/_staging"
cd "$VAULT_ROOT"

YESTERDAY=$(date -d 'yesterday' +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d)
TODAY_DOW=$(date +%u)  # 1=月曜

STATE_CONTENT="(状態ファイルなし。初回実行として扱う)"
if [ -f "$STATE_FILE" ]; then
  STATE_CONTENT=$(cat "$STATE_FILE")
fi

STAGING_NOTE="AIチャットセッションの受け渡しファイルは存在しません。AIチャットの新規候補は0件として扱ってください。"
if [ -s "$STAGING_FILE" ]; then
  STAGING_NOTE="AIチャットセッションの受け渡しファイルが存在します。内容は次の通りです。処理後、このファイルは空にしてください。
---
$(cat "$STAGING_FILE")
---"
fi

WEEKLY_BLOCK=""
if [ "$TODAY_DOW" = "1" ]; then
  WEEKLY_BLOCK="

【本日は月曜日：CLAUDE.md 6章（週次サイクル）も追加で実行してください】
5. 01_Seedsの新規蓄積分を横断し、複数回パターンとして出てきた候補を検出し、03_Brainstem／04_Knowledge／00_Personalへの昇格を提案してください（実行はしない、提案のみ）。
6. 04_Knowledge・05_Businessの生きたノートへの統合更新案をドラフトしてください（「## 📚 参照ノート」への追記案。本文は書き換えない）。
7. 3ヶ月更新のないノートを検出し、削除提案をしてください（Archiveへの退避ではなく削除）。
8. 00_Personal配下の全ノートを読み、00_Personal/Profile・思想・価値観/AIによる私のプロファイリングメモ.mdを最新の内容に更新してください（ぴなさんの声・価値観・判断基準の圧縮キャッシュ。前回更新から00_Personalに実質的な変化がなければ更新をスキップしてよい）。
9. 上記5〜7の提案は、下記の手順4で送るのと同じSlackメッセージ（同じスレッド）にまとめて含めてください。別メッセージにはしないでください。
10. 状態ファイルのweekly_review_fieldに、今回作成した週次提案の内容（提案一覧のテキスト）を記載してください（提案がなければ空欄でよい）。"
fi

echo "=== daily_cycle.sh 実行: $(date +%Y-%m-%dT%H:%M:%S) (対象日: $YESTERDAY) ===" | tee -a "$LOG_FILE"

PROMPT="CLAUDE.mdの5章（日次サイクル）に従って、本日分の日次サイクルを実行してください。

【前回の状態（$STATE_FILE の内容）】
$STATE_CONTENT

【手順】
1. 前日確定処理：上記の前回状態にslack_tsがあれば、Slackチャンネル（channel_id: $SLACK_CHANNEL_ID）の該当スレッドへの返信を確認してください。
   - 候補（notion_candidates/aiChat_candidates）：返信で明示的な却下・修正の指示があればそれに従う。指示がない項目は自動承認とし、4章の行き先判定に従って実際にVaultへ書き込んでください。
   - journal_fileに記載のJournal下書きファイル：返信テキストがあれば要約せずそのまま「## ぴなちゃんの声」セクションに転記し、frontmatterのstatusをconfirmedにしてください。返信がなければ「（この日は返信なし）」と記載してください。
   - 前回状態が「状態ファイルなし」の場合はこの手順をスキップしてください。

2. 前日（$YESTERDAY）分の収集・判定：
   - Notionの「MTGログBOX」（データソース: $NOTION_MTG_DATA_SOURCE）から、日付プロパティが$YESTERDAYのものを取得してください。①カテゴリが「メンバープロジェクト」のものは対象外です。それ以外は4章共通基準で判定してください。
   - **Notionの整理（巡回時のついでに実施）**：
     a. タイトルが空・「Untitled」等の無題ページを見つけたら、中身を読み取り、①カテゴリ／②詳細／③小分類の該当するものを選択し、内容を表す適切なタイトルと日付（date:日付:start、時刻まで分かればdate:日付:is_datetime=1）を記載してください（notion-update-pageのupdate_propertiesコマンドを使用）。
     b. 中身が実質的に空（本文がない、または会議リンクや日付だけで実質的な記録がない）ページを見つけたら、判定対象からは除外したうえで、notion-move-pagesで「🗑️ MTGログBOX 削除候補」ページ（page_id: $NOTION_TRASH_PAGE_ID）の子ページとして移動してください（Vaultへの書き込み判定の対象にはしない）。
     c. ②詳細・③小分類の選択は、選択肢の字面だけで推測しないこと。判断に迷ったら、notion-query-data-sourcesで既存の似たタイトル・内容のログが実際にどう分類されているかを確認し、それに合わせること。分かっている実際の使い分けの傾向：
        - 採用面接・候補者面談・登録面談など選考がらみのログは、③小分類は一貫して「面談」を使う（「選考会議」は用意されているが実運用では使われていない）
        - 「定例MTG」と「方針相談」は字面ではなく開催頻度で区別する。タイトルに「Daily」「デイリー」「同期」「定例」等、定期開催と分かる語がある、または過去の記録に同名の定例シリーズがある場合は「定例MTG」。単発のすり合わせ・相談ごとは「方針相談」
        - ②詳細は1つに絞らず、内容が複数テーマにまたがる場合は該当するものを複数選ぶ
   - AIチャットセッション：$STAGING_NOTE
   - 4章の基準を通過したものだけを本日の候補としてまとめてください（Vaultへの書き込みはまだしない）。

3. Journal下書き生成：02_Journal/Daily/$YESTERDAY.md に「## 客観的にあったこと」（事実ベースの要約）を作成してください。「## ぴなちゃんの声」は空欄のまま渡してください。ファイルが既にあれば上書きせず統合してください。

4. Slack送付：$SLACK_CHANNEL_ID へ、本日まとめた候補一覧とJournalの下書き内容を送付し、「気になること・問い」をラフに聞いてください。送付したメッセージのts（スレッドのルートts）を控えてください。$WEEKLY_BLOCK

最後に、$STATE_FILE （Vault外の自動化専用フォルダにあるファイルです。Vault内には作成しないでください）を次の形式で完全に上書きしてください（前回の内容は手順1で処理済みなので破棄してよい）：
---
date: $YESTERDAY
slack_ts: {上記手順4で送付したメッセージのts}
notion_candidates: [{候補になった各Notionノートのタイトルの配列}]
aiChat_candidates: [{候補になった各AIチャットセッションの短い識別子の配列}]
journal_file: {作成/更新したJournalファイルの相対パス}
weekly_review_file: {月曜日のみ、週次提案の内容。それ以外はnull}
note: \"{今回の実行結果を1〜2文で要約}\"
---

AIチャットセッションの受け渡しファイル（_System/_staging/aiChat_sessions_pending.md）が存在し、内容を読んだ場合は、処理後にこのファイルを空にしてください。

作業完了後、各手順で何を行ったか（件数・ファイル名）を簡潔に報告してください。"

# プロンプトが長大になりうる（AIチャットセッションの生テキストを含むため）ため、
# コマンドライン引数ではなく標準入力経由で渡す（"Argument list too long"エラー対策）
printf '%s' "$PROMPT" | "$CLAUDE_BIN" -p \
  --permission-mode acceptEdits \
  --allowedTools "Read Edit Write Glob Grep mcp__claude_ai_Notion__notion-query-data-sources mcp__claude_ai_Notion__notion-fetch mcp__claude_ai_Notion__notion-search mcp__claude_ai_Notion__notion-update-page mcp__claude_ai_Notion__notion-move-pages mcp__claude_ai_Slack__slack_read_thread mcp__claude_ai_Slack__slack_send_message mcp__claude_ai_Slack__slack_read_channel" \
  --output-format json 2>&1 | tee -a "$LOG_FILE"

echo "=== 完了 ===" | tee -a "$LOG_FILE"
