#!/usr/bin/env bash
# Notion「MTGログBOX」の整理を、Vaultへの書き込み判定とは独立して毎日実行する。
#   a. タイトルが空・Untitledのページに、内容を読んでタイトル・日付・カテゴリを補完する
#   b. 中身が実質的に空のページを「🗑️ MTGログBOX 削除候補」ページへ移動する（削除自体は手動）
#   c. タイトルはあるが分類（①②③）が未設定のページにも分類を補完する
#   d. 分類に迷う場合は、既存の類似ログの分類傾向に合わせる
#
# 旧daily_cycle.shの一部だった巡回整理ロジックを、Slack承認フロー廃止後も
# 独立して動かし続けるために切り出したもの。Vault側の判定（4章）とは無関係。

set -euo pipefail

export PATH="/usr/bin:/bin:/mingw64/bin:$PATH"

CLAUDE_BIN="/c/Users/朝比奈聖海/.local/bin/claude"

AUTOMATION_DIR="/c/Users/朝比奈聖海/!ai-pinas-capital/Pina-Vault-Automation"
STATE_FILE="$AUTOMATION_DIR/_state/notion_cleanup_last_run.md"
LOG_FILE="$AUTOMATION_DIR/_state/notion_cleanup_log.md"
NOTION_MTG_DATA_SOURCE="collection://35bf60ae-f36f-80ae-a2c9-000b82d1a3eb"
NOTION_TRASH_PAGE_ID="3a5f60ae-f36f-813c-a076-d467a09412bb"

mkdir -p "$AUTOMATION_DIR/_state"

if [ -f "$STATE_FILE" ]; then
  LAST_RUN=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$STATE_FILE" | head -1)
  SCOPE_NOTE="前回実行（$LAST_RUN）以降にcreatedTimeが新しいページに加え、タイトル・日付・カテゴリ（①②③のいずれか）が未設定のままの既存ページも対象に含めてください。"
else
  SCOPE_NOTE="初回実行のため、MTGログBOX全件を対象にしてください。"
fi

echo "=== notion_cleanup.sh 実行: $(date +%Y-%m-%dT%H:%M:%S) ===" | tee -a "$LOG_FILE"

PROMPT="Notionの「MTGログBOX」（データソース: $NOTION_MTG_DATA_SOURCE）を整理してください。Vaultへの書き込みは一切行わない、Notion側だけの独立した整理作業です。

【対象範囲】
$SCOPE_NOTE

【手順】
1. 対象ページを一通り確認し、以下を行ってください：
   a. タイトルが空・「Untitled」等の無題ページを見つけたら、中身を読み取り、①カテゴリ／②詳細／③小分類の該当するものを選択し、内容を表す適切なタイトルと日付（date:日付:start、時刻まで分かればdate:日付:is_datetime=1）を記載してください（notion-update-pageのupdate_propertiesコマンドを使用）。
   b. 中身が実質的に空（本文がない、または会議リンクや日付だけで実質的な記録がない）ページを見つけたら、notion-move-pagesで「🗑️ MTGログBOX 削除候補」ページ（page_id: $NOTION_TRASH_PAGE_ID）の子ページとして移動してください。このページは削除の最終判断をぴなさんが手動で行うための保管場所です。ここでは移動だけを行い、削除はしないでください。
   c. タイトルはあるが①カテゴリ・②詳細・③小分類のいずれかが未設定の既存ページにも、bと同様に中身を確認したうえで分類を補完してください（中身が実質的に空だった場合はbの扱いを優先する）。
   d. ②詳細・③小分類の選択は、選択肢の字面だけで推測しないこと。判断に迷ったら、notion-query-data-sourcesで既存の似たタイトル・内容のログが実際にどう分類されているかを確認し、それに合わせること。分かっている実際の使い分けの傾向：
      - 採用面接・候補者面談・登録面談など選考がらみのログは、③小分類は一貫して「面談」を使う（「選考会議」は用意されているが実運用では使われていない）
      - 「定例MTG」と「方針相談」は字面ではなく開催頻度で区別する。タイトルに「Daily」「デイリー」「同期」「定例」等、定期開催と分かる語がある、または過去の記録に同名の定例シリーズがある場合は「定例MTG」。単発のすり合わせ・相談ごとは「方針相談」
      - ②詳細は1つに絞らず、内容が複数テーマにまたがる場合は該当するものを複数選ぶ

2. $STATE_FILE を次の形式で完全に上書きしてください：
---
last_run: $(date +%Y-%m-%dT%H:%M:%S)
note: \"{今回処理した件数（タイトル/日付/分類補完、削除候補移動それぞれ）を1文で要約}\"
---

作業完了後、処理件数を簡潔に報告してください。"

printf '%s' "$PROMPT" | "$CLAUDE_BIN" -p \
  --permission-mode acceptEdits \
  --allowedTools "Read Write mcp__claude_ai_Notion__notion-query-data-sources mcp__claude_ai_Notion__notion-fetch mcp__claude_ai_Notion__notion-search mcp__claude_ai_Notion__notion-update-page mcp__claude_ai_Notion__notion-move-pages" \
  --output-format json 2>&1 | tee -a "$LOG_FILE"

echo "=== 完了 ===" | tee -a "$LOG_FILE"
