---
type: state-index
updated: 2026-07-16
---

# _state 索引

> これはコンテンツのハブ（[[06_Brainstem]]）ではない。裏方の状態管理ファイルだけを束ねる、機械のための索引。Claude/ChatGPT/MTG、それぞれの自動化パイプラインが「どこまで処理したか」を覚えておくためのbookkeepingが目的。中身自体に思考的価値はない。

## Claude側
- [[claude_titles]] — daily-claude-distillationが毎日取得する、claude.aiサイドバーの現在のタイトル一覧（スナップショット）
- [[claude_seen_state]] — 上記タイトル一覧と照合し、どのセッションを・いつ・どう処理したか（新規／更新／スキップ）を記録した表

## ChatGPT側
- [[chatgpt_titles]] — daily-chatgpt-distillationが毎日取得する、chatgpt.comサイドバーの現在のタイトル一覧（スナップショット）
- [[chatgpt_seen_state]] — 上記タイトル一覧と照合し、どのチャットを・いつ・どう処理したか（新規／更新／スキップ、抽出先）を記録した表

## MTG側
- [[mtg_last_run]] — daily-mtg-obsidian-stockの前回実行時刻・処理件数のマーカー

## Slack/Journal側（daily-inbox-journal-capture、2026-07-16新設）
- `slack_inbox_last_run` — #z-pina-brainspaceの前回取得時刻のマーカー（初回実行後に作成される）
- `journal_pending` — 確定待ちの04_Journal/Daily下書きの情報（Slackメッセージtsとファイルパス。初回実行後に作成される）

## 対応関係
Claude・ChatGPTの2系統は構造が対（titles＝スナップショット、seen_state＝処理履歴）になっている。MTG・Slack/Journal系は単一マーカーで完結する軽量な構造。いずれも01_Inbox・05_Seeds・07_Compass・08_Business・04_Journalへのノート作成/追記という形で「読める記録」に変換された後は、このフォルダ自体には実質的な内容を残さない。

## 保持期間（2026-07-18追記）
`claude_seen_state.md`・`chatgpt_seen_state.md`は行が無期限に蓄積し肥大化する。処理日から30日を経過した行は、重複処理防止という役割をすでに終えている（対象セッションはとっくにサイドバーから消えている）ため、削除してよい。`titles.md`は毎回上書きのスナップショットなので対象外。
