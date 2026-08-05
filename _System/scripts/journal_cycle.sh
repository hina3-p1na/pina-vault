#!/usr/bin/env bash
# 新Journal運用：毎晩22時に1回実行。
#   1. 前日のプッシュ（今日書きたいことある？）への返信を確認し、あれば1気づき＝1ノートとして記録
#   2. 当日 #vault タグ付きでSlackに投稿された内容を拾い、同様に1気づき＝1ノートとして記録
#   3. 今晩分のプッシュをSlackへ送信し、そのスレッドtsを次回チェック用に控える
#
# 4章の判定ロジック（AIによる要・不要判定）は適用しない。
# 本人がタグを付けて発信した／プッシュに返信した時点で「残す価値がある」という意思表示のため。
# 内容は要約せず、生テキストのまま転記する。

set -euo pipefail

# -lc（ログインシェル）はタスクスケジューラの非対話的な実行コンテキストでハングするため
# -c無しでbash.exeに直接渡す形式に変えたが、その場合プロファイルが読み込まれず
# dirname/mkdir等の基本コマンドへのPATHが通らない。スクリプト内で明示的に補う。
export PATH="/usr/bin:/bin:/mingw64/bin:$PATH"

CLAUDE_BIN="/c/Users/朝比奈聖海/.local/bin/claude"

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUTOMATION_DIR="/c/Users/朝比奈聖海/!ai-pinas-capital/Pina-Vault-Automation"
STATE_FILE="$AUTOMATION_DIR/_state/journal_pending.md"
WEEKLY_STATE_FILE="$AUTOMATION_DIR/_state/journal_weekly_pending.md"
LOG_FILE="$AUTOMATION_DIR/_state/journal_cycle_log.md"
SLACK_CHANNEL_ID="C0BHK5MA0F7"
JOURNAL_DIR="02_Journal"

mkdir -p "$AUTOMATION_DIR/_state"
cd "$VAULT_ROOT"

TODAY=$(date +%Y-%m-%d)

STATE_CONTENT="(状態ファイルなし。初回実行として扱う)"
if [ -f "$STATE_FILE" ]; then
  STATE_CONTENT=$(cat "$STATE_FILE")
fi

WEEKLY_BLOCK=""
if [ -f "$WEEKLY_STATE_FILE" ]; then
  WEEKLY_STATE_CONTENT=$(cat "$WEEKLY_STATE_FILE")
  WEEKLY_BLOCK="

【週次統合（フラクタル・ジャーナリング）の確認】
$WEEKLY_STATE_FILE の内容：
$WEEKLY_STATE_CONTENT

上記にprompt_tsがあり、かつnullでなければ、そのSlackスレッドへの返信を確認してください。返信があれば：
- 要約せず生テキストのまま、$JOURNAL_DIR 直下に1件のノートとして作成する
- frontmatter: tags: [journal, weekly-review], created: {返信のあった日付}
- タイトル: 内容を読んで短い見出しを生成する
- 本文の末尾に、上記state内のfragment_notesへの[[wikilink]]を「## 元になった断片」として列挙する
- 処理が終わったら、$WEEKLY_STATE_FILE のprompt_tsをnullに更新する（二重処理を防ぐため）
返信がまだ無ければ、何もせず次回に持ち越してください（$WEEKLY_STATE_FILEは変更しない）。"
fi

echo "=== journal_cycle.sh 実行: $(date +%Y-%m-%dT%H:%M:%S) ===" | tee -a "$LOG_FILE"

PROMPT="Pina-Vaultの新Journal運用（1気づき＝1ノート方式）を実行してください。4章の判定基準は適用しません（本人が発信・返信した時点で残す価値がある、という前提のため）。

【前回の状態（$STATE_FILE の内容）】
$STATE_CONTENT

【手順】
1. 前回プッシュへの返信確認：上記の状態に前回のprompt_tsがあれば、Slackチャンネル（channel_id: $SLACK_CHANNEL_ID）の該当スレッドへの返信を確認してください。返信があれば、要約せず生テキストのまま、$JOURNAL_DIR 直下（サブフォルダなし）に1件＝1ノートとして作成してください。
   - frontmatter: tags: [journal], created: {返信のあった日付}
   - タイトル: 「Diary｜{YYMMDD}_{内容要約}」の形式にする。YYMMDDはcreatedの日付を2桁年+2桁月+2桁日で（例：2026-07-28→260728）。内容要約は内容を読んで生成する、最大10文字（句読点・記号を含めて10文字以内に収める）
   - 本文: 返信テキストをそのまま（要約・言い換え禁止）

2. 当日分の#vaultタグ投稿確認：Slackチャンネル（channel_id: $SLACK_CHANNEL_ID）から、本日($TODAY)中に投稿された「#vault」を含むメッセージを検索してください。見つかった投稿ごとに、手順1と同じ形式（生テキストのまま、タイトル生成、tags: journal、created日付）で$JOURNAL_DIR直下に1件＝1ノートを作成してください。既に手順1で処理した内容と重複させないでください。

3. 今晩分のプッシュ送信：Slackチャンネル（channel_id: $SLACK_CHANNEL_ID）へ、以下の形式のメッセージをそのまま送付してください（項目名や体裁を変えない）。

【今日あったこと】


【気づき発見/アイデア】


【今の心境】


この続きに、気軽に返信を誘う一言（例：「埋められるところだけでOK！気軽に返信してね」）を添えてください。送付したメッセージのts（スレッドのルートts）を控えてください。
$WEEKLY_BLOCK

最後に、$STATE_FILE を次の形式で完全に上書きしてください：
---
date: $TODAY
prompt_ts: {手順3で送付したメッセージのts}
last_checked: $(date +%Y-%m-%dT%H:%M:%S)
note: \"{今回処理した件数を1文で要約}\"
---

作業完了後、処理件数（返信・タグ投稿それぞれ）を簡潔に報告してください。"

printf '%s' "$PROMPT" | "$CLAUDE_BIN" -p \
  --permission-mode acceptEdits \
  --allowedTools "Read Edit Write Glob Grep mcp__claude_ai_Slack__slack_read_thread mcp__claude_ai_Slack__slack_send_message mcp__claude_ai_Slack__slack_read_channel mcp__claude_ai_Slack__slack_search_public_and_private mcp__claude_ai_Slack__slack_search_public" \
  --output-format json 2>&1 | tee -a "$LOG_FILE"

echo "=== 完了 ===" | tee -a "$LOG_FILE"
