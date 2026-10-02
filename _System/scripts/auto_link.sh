#!/usr/bin/env bash
# 前回実行以降に更新されたノートへ、AGENTS.mdの規則に従って
# hub・related・aliasesを追加する。本文中の語を無差別にリンク化しない。

set -euo pipefail
export PATH="/usr/bin:/bin:/mingw64/bin:$PATH"

CLAUDE_BIN="/c/Users/朝比奈聖海/.local/bin/claude"
VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUTOMATION_DIR="/c/Users/朝比奈聖海/!ai-pinas-capital/Pina-Vault-Automation"
STATE_FILE="$AUTOMATION_DIR/_state/auto_link_last_run.md"
LOG_FILE="$AUTOMATION_DIR/_state/auto_link_log.md"
TARGET_DIRS=("00_Personal" "01_Notes" "02_Memorandum" "03_Sources" "04_WorkSite" "05_Outputs" "06_AI知的資産")

if [ "${1:-}" != "--dry-run" ]; then mkdir -p "$AUTOMATION_DIR/_state"; fi
if [ -f "$STATE_FILE" ]; then
  LAST_RUN=$(grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}' "$STATE_FILE" | head -1)
else
  LAST_RUN=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%S)
fi

REF_FILE=$(mktemp)
touch -d "$LAST_RUN" "$REF_FILE" 2>/dev/null || touch "$REF_FILE"
cd "$VAULT_ROOT"
TARGETS=()
for d in "${TARGET_DIRS[@]}"; do
  [ -d "$d" ] || continue
  while IFS= read -r -d '' f; do
    case "$f" in
      *"/_Legacy Daily/"*|*"/_Legacy/"*) continue ;;
    esac
    TARGETS+=("$f")
  done < <(find "$d" -type f -name "*.md" -newer "$REF_FILE" -print0)
done
rm -f "$REF_FILE"

if [ "${1:-}" = "--dry-run" ]; then
  printf '対象ノート件数: %s\n' "${#TARGETS[@]}"
  if [ "${#TARGETS[@]}" -gt 0 ]; then printf '%s\n' "${TARGETS[@]}"; fi
  if [ -x "$CLAUDE_BIN" ]; then echo "Claude CLI: 存在確認OK"; else echo "Claude CLI: 実行ファイル未確認"; fi
  echo "確認のみ完了（AI呼び出し・ノート編集・状態更新なし）"
  exit 0
fi
echo "=== auto_link.sh 実行: $(date -u +%Y-%m-%dT%H:%M:%S) ===" | tee -a "$LOG_FILE"
echo "対象ノート件数: ${#TARGETS[@]}" | tee -a "$LOG_FILE"
if [ "${#TARGETS[@]}" -gt 0 ]; then
  LIST=$(printf '「%s」\n' "${TARGETS[@]}")
  PROMPT="Vault直下のAGENTS.mdと06_AI知的資産/Rules/自動リンクルール.mdを読み、次のノートだけを処理してください。

対象ノート：
$LIST

各ノートについて、既存frontmatterを壊さず次を行ってください。
- hub：原則1件。明確な橋渡しのみ最大2件。無所属も許可
- related：直接関係する既存ノートのみ最大3件
- aliases：実在する別名・略称・表記揺れだけ
- 存在しないノートへの空リンクを作らない
- 本文を書き換えない
- 旧Daily・_Legacy配下は処理しない
- 判断に迷う場合は追加しない

処理後、ノートごとに変更内容を1行で報告してください。"
  printf '%s' "$PROMPT" | "$CLAUDE_BIN" -p \
    --permission-mode acceptEdits \
    --allowedTools "Read Edit Glob Grep" \
    --output-format json 2>&1 | tee -a "$LOG_FILE"
fi
date -u +"last_run: %Y-%m-%dT%H:%M:%S" > "$STATE_FILE"
echo "=== 完了 ===" | tee -a "$LOG_FILE"
