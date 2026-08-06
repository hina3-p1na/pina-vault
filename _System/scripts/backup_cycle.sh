#!/usr/bin/env bash
# 毎晩23:00に1回実行。AI判定が不要な機械的処理のみのため claude -p は呼ばない（トークン消費ゼロ）。
#   1. Pina-Vault（Public repo）：構造・スクリプト・.obsidian設定のみをgit push
#      実データ（00_Personal〜05_Outputs）は.gitignoreでPublicから除外済み
#   2. 実データ＋Claude Codeセッションログ（~/.claude/projects配下、全プロジェクト）を
#      SessionLogBackup（Private repo）へミラーしてgit push
#
# Private backup側は追記のみ（source側で削除されたファイルもbackup側には残る）。
# 復元用の安全網という位置づけのため、意図的に削除を追随させていない。

set -euo pipefail

# 非ログインシェル経由だと/etc/profileが読まれずGit Bash標準コマンドがPATHに乗らないため、明示的に通す
export PATH="/usr/bin:/bin:/mingw64/bin:$PATH"

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AUTOMATION_DIR="/c/Users/朝比奈聖海/!ai-pinas-capital/Pina-Vault-Automation"
LOG_FILE="$AUTOMATION_DIR/_state/backup_cycle_log.md"
SESSION_LOG_SRC="/c/Users/朝比奈聖海/.claude/projects"
PRIVATE_BACKUP="/c/Users/朝比奈聖海/!ai-pinas-capital/SessionLogBackup"
VAULT_CONTENT_DIRS=("00_Personal" "01_Notes" "02_Journal" "03_Sources" "04_WorkSite" "05_Outputs")

mkdir -p "$AUTOMATION_DIR/_state"

echo "=== backup_cycle.sh 実行: $(date +%Y-%m-%dT%H:%M:%S) ===" | tee -a "$LOG_FILE"

# 1. Vault（Public repo）
cd "$VAULT_ROOT"
git add -A
if ! git diff --cached --quiet; then
  git commit -m "auto backup: $(date +%Y-%m-%dT%H:%M:%S)" | tee -a "$LOG_FILE"
  git push origin master 2>&1 | tee -a "$LOG_FILE"
  echo "Vault(Public): 変更をpushしました" | tee -a "$LOG_FILE"
else
  echo "Vault(Public): 変更なし" | tee -a "$LOG_FILE"
fi

# 2. 実データ + セッションログ（Private repo）
mkdir -p "$PRIVATE_BACKUP/vault-content" "$PRIVATE_BACKUP/claude-sessions"

for d in "${VAULT_CONTENT_DIRS[@]}"; do
  if [ -d "$VAULT_ROOT/$d" ]; then
    mkdir -p "$PRIVATE_BACKUP/vault-content/$d"
    cp -r "$VAULT_ROOT/$d/." "$PRIVATE_BACKUP/vault-content/$d/"
  fi
done

cp -r "$SESSION_LOG_SRC/." "$PRIVATE_BACKUP/claude-sessions/"

cd "$PRIVATE_BACKUP"
git add -A
if ! git diff --cached --quiet; then
  git commit -m "auto backup: $(date +%Y-%m-%dT%H:%M:%S)" | tee -a "$LOG_FILE"
  git push origin master 2>&1 | tee -a "$LOG_FILE"
  echo "Private backup: 変更をpushしました" | tee -a "$LOG_FILE"
else
  echo "Private backup: 変更なし" | tee -a "$LOG_FILE"
fi

echo "=== 完了 ===" | tee -a "$LOG_FILE"
