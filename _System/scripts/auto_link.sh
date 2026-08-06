#!/usr/bin/env bash
# CLAUDE.mdの3章（リンクとタグ）に従って、新規・更新されたノートに
# 自然文インラインwikilinkを自動付与するバッチ。
#
# 前回実行以降に変更された対象ノートを検出し、1件ずつClaude Code(-p, 非対話モード)に
# 「このノートにリンクを付けて」と依頼する。概念の候補探し・新規概念スタブの作成判断は
# すべてClaude Code自身がvault内を読んで行う（このスクリプトは概念一覧を持たない）。
#
# 対象外： 02_Journal（1気づき＝1ノートの生の記録）、03_Sources（未加工の生素材、ノートではない）。

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
STATE_FILE="$AUTOMATION_DIR/_state/auto_link_last_run.md"
LOG_FILE="$AUTOMATION_DIR/_state/auto_link_log.md"
TARGET_DIRS=("00_Personal" "01_Notes" "04_WorkSite")

mkdir -p "$AUTOMATION_DIR/_state"

# 前回実行時刻の読み込み（初回は24時間前を基準にする）
if [ -f "$STATE_FILE" ]; then
  LAST_RUN=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$STATE_FILE" | head -1)
else
  LAST_RUN=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S)
fi

# 基準時刻より新しい.mdファイルを探すための目印ファイル
REF_FILE=$(mktemp)
touch -d "$LAST_RUN" "$REF_FILE" 2>/dev/null || touch "$REF_FILE"

cd "$VAULT_ROOT"

TARGETS=()
for d in "${TARGET_DIRS[@]}"; do
  if [ -d "$d" ]; then
    while IFS= read -r -d '' f; do
      TARGETS+=("$f")
    done < <(find "$d" -type f -name "*.md" -newer "$REF_FILE" -print0)
  fi
done

rm -f "$REF_FILE"

echo "=== auto_link.sh 実行: $(date -u +%Y-%m-%dT%H:%M:%S) ===" | tee -a "$LOG_FILE"
echo "対象ノート件数: ${#TARGETS[@]}" | tee -a "$LOG_FILE"

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "対象ノートなし。終了。" | tee -a "$LOG_FILE"
else
  # 1回の起動にまとめて処理する（vault探索・CLAUDE.md読み込みのコストを1回分に抑えるため）
  LIST=$(printf '「%s」\n' "${TARGETS[@]}")
  PROMPT="CLAUDE.mdの3章（リンクとタグ）に従って、次の複数ノートそれぞれに自然文インラインwikilinkを追加してください。1件ずつ本文を読み、00_Personal・01_Notes・04_WorkSiteの既存ノート・aliasと自然に対応する固有のキーワードだけを[[キーワード]]としてリンク化してください。一般的な言い回しにはリンクを貼らないでください。リンク先が存在せず、かつ繰り返し出てくる固有の概念だと判断した場合のみ、1〜2行の短い概念ノートを01_Notesに新規作成してください（新規作成した概念ノートは、後続のノート処理時にもリンク候補として使ってください）。判断に迷う場合はリンクを追加しない側に倒してください。

対象ノート一覧：
$LIST

全件処理し終えたら、ノートごとに「変更した／変更なし」を1行で要約して報告してください。"

  # 対象ノート数が多い日に備え、コマンドライン引数ではなく標準入力経由で渡す
  printf '%s' "$PROMPT" | "$CLAUDE_BIN" -p \
    --permission-mode acceptEdits \
    --allowedTools "Read Edit Write Glob Grep" \
    --output-format json 2>&1 | tee -a "$LOG_FILE"
fi

date -u +"last_run: %Y-%m-%dT%H:%M:%S" > "$STATE_FILE"
echo "=== 完了 ===" | tee -a "$LOG_FILE"
