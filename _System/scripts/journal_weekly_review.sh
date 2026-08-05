#!/usr/bin/env bash
# フラクタル・ジャーナリング（週次統合）：毎週月曜10時に1回実行。
#   1. 直近7日分の journal タグ付きノート（断片）を集める
#   2. そのタイトル一覧をSlackで提示し、「振り返って見えたパターン・繋がり」を尋ねる
#   3. 返信は次回以降のjournal_cycle.sh（毎晩）が拾い、週次統合ノートとして記録する
#
# 統合ノートの中身（何が見えたか）はClaude Codeが自動要約しない。
# 本人の言葉で書いてもらうことに価値がある、という原則を踏襲する。

set -euo pipefail

# 非ログインシェル経由だと/etc/profileが読まれずGit Bash標準コマンドがPATHに乗らないため、明示的に通す
export PATH="/usr/bin:/bin:/mingw64/bin:$PATH"

CLAUDE_BIN="/c/Users/朝比奈聖海/.local/bin/claude"

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUTOMATION_DIR="/c/Users/朝比奈聖海/!ai-pinas-capital/Pina-Vault-Automation"
WEEKLY_STATE_FILE="$AUTOMATION_DIR/_state/journal_weekly_pending.md"
LOG_FILE="$AUTOMATION_DIR/_state/journal_weekly_review_log.md"
SLACK_CHANNEL_ID="C0BHK5MA0F7"
JOURNAL_DIR="02_Journal"

mkdir -p "$AUTOMATION_DIR/_state"
cd "$VAULT_ROOT"

TODAY=$(date +%Y-%m-%d)
SEVEN_DAYS_AGO=$(date -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d)

echo "=== journal_weekly_review.sh 実行: $(date +%Y-%m-%dT%H:%M:%S) ===" | tee -a "$LOG_FILE"

PROMPT="フラクタル・ジャーナリングの週次統合プロンプトを実行してください。

【手順】
1. $JOURNAL_DIR 直下（サブフォルダなし）のノートから、frontmatterのtagsに journal を含み、createdが $SEVEN_DAYS_AGO 〜 $TODAY の範囲にあるものを全て探してください。

2. 見つかったノートのタイトル一覧（ファイル名）を整理してください。0件の場合は、その旨だけをSlackに送って手順3以降はスキップしてください。

3. Slackチャンネル（channel_id: $SLACK_CHANNEL_ID）へ、その一覧を示したうえで「この1週間を振り返って、繋がりや見えてきたパターンがあれば書いてね」という趣旨のメッセージを送付してください。要約や解釈をこちらで先回りして提示しないでください（本人に気づいてもらうことが目的のため）。送付したメッセージのts（スレッドのルートts）を控えてください。

最後に、$WEEKLY_STATE_FILE を次の形式で完全に上書きしてください：
---
week_start: $SEVEN_DAYS_AGO
week_end: $TODAY
prompt_ts: {手順3で送付したメッセージのts、0件でスキップした場合はnull}
fragment_notes: [{対象になった断片ノートのファイル名の配列}]
---

作業完了後、対象件数と送付結果を簡潔に報告してください。"

printf '%s' "$PROMPT" | "$CLAUDE_BIN" -p \
  --permission-mode acceptEdits \
  --allowedTools "Read Edit Write Glob Grep mcp__claude_ai_Slack__slack_send_message" \
  --output-format json 2>&1 | tee -a "$LOG_FILE"

echo "=== 完了 ===" | tee -a "$LOG_FILE"
