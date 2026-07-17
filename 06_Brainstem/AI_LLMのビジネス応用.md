---
type: theme
tags: [ai, llm, business, ops, automation]
---

# AI / LLM のビジネス応用 — 思考整理

## AIに対する立ち位置
「AIは道具」であり「思考の補助装置」。
置き換えられるのは「情報処理」であり、「判断の文脈形成」は人間に残る。

## 関心のある応用領域

### RevOps × AI
- Pipeline予測の精度向上（Propensity scoring）
- Deal riskの自動検知（Communication analysis）
- Win-Loss分析の自動化
- CRMデータ品質の自動補完

### GTM × AI
- ICP scoring の自動化
- Personalization at scale（メール・コンテンツ）
- Call analysis → coaching automation

### Customer Success × AI
- Health score の多変量化・リアルタイム化
- Churn prediction の精度向上
- QBR / EBR の自動準備

### Ops設計 × AI
- SOP作成・更新の補助
- ナレッジベース構築・維持
- レポーティング自動化

## 注意しているポイント
- **"AIで自動化"より先に「プロセスの設計が正しいか」を確認する**
- ゴミデータをAIに食わせてもゴミが出るだけ（Garbage in, Garbage out）
- 判断基準・KPIの定義が曖昧なままAIを入れると混乱が増す

## LLMの特性理解（仕事で使う上で）
- 確率的な生成 → 重要判断のダブルチェックは必須
- コンテキスト管理 → 長期タスクはチャンク化・構造化が必要
- プロンプト設計 → ゴールと制約の明確化が品質を決める

## 個人仮説
> "AIを最も活用できる人は、プロセスの構造化と問いの精度が高い人。それは元々のビジネス設計能力と直結する"

## 関連テーマ
- [[RevOps_BizOpsの設計思想]]
- [[GTMは価値の届け方の設計]]


## 📚 関連ChatGPT参照 — AI/LLM（476件中上位20件）

- MP3解析AIツール
- 【公式】LegalOn（リーガルオン）｜ Professional AI for LEGAL ...
- AI: A Declaration of Autonomy
- デジタル&AIトランスフォーメーション／Digital & AI ...
- login - 【公式】LegalOn（リーガルオン）｜ Professional AI ...
- You want to maintain at least 8M JPY income.
- 世界No.1 AI CRM | AIエージェント搭載のSFA、CRM ...
- AIに奪われない仕事は「現場」にあった。アクセンチュアの新職種「フィールドコンサルタント」の正体
- NTTドコモ・グローバル、アクセンチュア、AWSがAI駆動開発で連携
- トゥルーストがAI競争と予算圧迫を理由にアクセンチュア株を格下げ 執筆
- AI時代の採用管理システム(ATS) HERP Hire(ハープハイアー)
- ビズリーチを使ってみた感想とスカウト実績｜Daisuke Nagai
- Notion AI運用設計
- AssemblyAI and Notion: Automate Workflows with n8n
- AssemblyAI and Zoom: Automate Workflows with n8n
- AssemblyAI integrations | Workflow automation with n8n
- Workflow for syncing Zoom AI transcripts to Notion Database
- Zoom AssemblyAI Integration - Quick Connect - Zapier
- AssemblyAI
- Gong vs Chorus.ai: Conversation Intelligence Comparison | AI-Ready CMO

## 📚 関連Claude参照（Coworkセッション）— 2026-07-15更新

- [個人向けAIコンサルタント体制の構築] — AIスタック設計の議論（7月2日〜5日）。Claude=Cowork実装担当、ChatGPT o3=戦略壁打ち担当という役割分担を確定。Claude Proのクレジット上限問題でラリーが途切れるため長い思考整理にはChatGPTを使っているという実態も明らかに。Manusについて「デザイン品質が高い」という評価に「テンプレ品質≠思考品質」と批判的検討を加えた。
- [💬 Notion AI活用法に関する悩みについて壁打ちさせて。…] — Notion AIの有料プランが「豚に真珠」状態になっている問題の構造診断。核心の気づきは「機能は点ではなく円」でありDB/Connector接続による動線整備が起点、その上に品質（カスタム指示）・範囲（コネクタ）・速度（自動化）が乗る順序を誤ってはいけない、というもの。ぴなちゃん自身がこの構造をValue Promise×実装一致の思想と相似形と気づき、抽象化能力の高さが発揮された。
- [Claude モデル間の性能差と使い分け] — Haiku/Sonnet/Opusの使い分け（速度×コスト×推論深さ）とCowork/Chat/Codeの役割分担を整理。実践的な結論：「0→1思考はOpus、日常実務はSonnet、大量処理はHaiku」「Chat＝思考・壁打ち、Cowork＝定常タスク委任、Code＝原則不要」。HarnessOps（Obsidian→Claude→Notion）の3層スタックとの対応関係も整理。
- [AI生成スライドの「AI臭さ」を取り除く診断] — AIスライドの品質問題を3層で診断。プロンプト層：上位思想（1スライド1メッセージ）の欠如。コード/QA層：ルールはあるが機械的検証機構がない。解決策として「メッセージファースト設計→ブランド実装→図解選定→数字の主役選定→機械QA→目視QA」の6ステップskillを構築。
- [栃木銀行のScope 3算定自動化と脱炭素支援] — （前回参照済み、今回未更新）
- [3C分析表の自動スライド生成] — スライド生成タスク、思考蒸留対象外
- [最近の様子について話そう] — Claude Code・Obsidian MCP連携の導入相談。「本格連携（MCP）でガッツリやる」という方向性を選択し、Obsidianのインストールから始めて段階的に整備していく道筋を確認。HarnessOpsの起点となったセッション。

### 2026-07-13（ChatGPT蒸留）

- [AIエージェント比較] — ClaudeとManusを「AIエージェントとしての実行力」で比較。Claude＝高品質な思考・実装・コードの相棒、Manus＝丸投げ自律実行（リサーチ・資料作成・ブラウザ操作・複数工程完走）という役割分担が明確化。エージェント感の強さはManusが上だが、信頼性・精度・業務定着度はClaudeが優位。
- [AI運用ポートフォリオ] — ChatGPT（思考整理）・Claude（PC操作・自動化）・Manus（作業完了まで）・Perplexity（リアルタイム検索）・Gemini（Google系）・NotebookLM（根拠ベース整理）という多AIポートフォリオを設計。「ツールが強くても情報がサイロ化するのが最大の問題」という課題認識から、将来的には1つの起点AIが複数AIを統括オーケストレーションする統合ワークフローを志向。
