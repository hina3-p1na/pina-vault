#!/usr/bin/env bash
# CLAUDE.mdの3章（リンクとタグ）に従って、新規・更新されたノートに
# 自然文インラインwikilinkを自動付与するバッチ。
#
# 前回実行以降に変更された対象ノートを検出し、1件ずつClaude Code(-p, 非対話モード)に
# 「このノートにリンクを付けて」と依頼する。概念の候補探し・新規概念スタブの作成判断は
# すべてClaude Code自身がvault内を読んで行う（このスクリプトは概念一覧を持たない）。
#
# 対象外： 02_Journal（生の日次記録のためリンク付与の対象外）、01_Seedsは対象（下記参照）。
# 2026-07-22: Cowork側のフォルダ再編（02_Resources/03_Sprout廃止、04_Journal→02_Journal、
# 06_Brainstem→03_Brainstem、07_Knowledge→04_Knowledge、08_Business→05_Businessへ改番）に追随。

set -euo pipefail

VAULT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$VAULT_ROOT/_System/_state/auto_link_last_run.md"
LOG_FILE="$VAULT_ROOT/_System/_state/auto_link_log.md"
TARGET_DIRS=("00_Personal" "01_Seeds" "03_Brainstem" "04_Knowledge" "05_Business")

mkdir -p "$VAULT_ROOT/_System/_state"

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
  claude -p "CLAUDE.mdの3章（リンクとタグ）に従って、次の複数ノートそれぞれに自然文インラインwikilinkを追加してください。1件ずつ本文を読み、00_Personal・03_Brainstem・04_Knowledge・05_Businessの既存ノート・aliasと自然に対応する固有のキーワードだけを[[キーワード]]としてリンク化してください。一般的な言い回しにはリンクを貼らないでください。リンク先が存在せず、かつ繰り返し出てくる固有の概念だと判断した場合のみ、成熟度ラダーに沿った適切なフォルダに1〜2行の短い概念ノートを新規作成してください（新規作成した概念ノートは、後続のノート処理時にもリンク候補として使ってください）。判断に迷う場合はリンクを追加しない側に倒してください。

対象ノート一覧：
$LIST

全件処理し終えたら、ノートごとに「変更した／変更なし」を1行で要約して報告してください。" \
    --permission-mode acceptEdits \
    --allowedTools "Read Edit Write Glob Grep" \
    --output-format json 2>&1 | tee -a "$LOG_FILE"
fi

date -u +"last_run: %Y-%m-%dT%H:%M:%S" > "$STATE_FILE"
echo "=== 完了 ===" | tee -a "$LOG_FILE"
