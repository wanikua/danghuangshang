[中文版](./README.md) | [English](./README_EN.md) | [🏢 企業版：Become CEO](https://github.com/wanikua/become-ceo) | [📚 完全ドキュメント](./docs/README.md)

<!-- SEO キーワード: 三省六部、明朝、六部制、中書省、門下省、尚書省、AI朝廷、AIエージェント、マルチエージェント協調、AI管理、古代中国統治、現代マネジメント、組織アーキテクチャ、OpenClaw、multi-agent、ancient-china -->

> **⚠️ オリジナリティに関する声明:** 本プロジェクトは **2025年2月22日** に初公開されました（小紅書での宣伝投稿は2月20日から）。「三省六部 × AIマルチエージェント」コンセプトのオリジナル作品です。21時間後に、15項目中15項目のコア設計が一致するコピープロジェクトが、出典表記なしに作成されました。証拠の詳細: [GitHub Issue](https://github.com/cft0808/edict/issues/55)。フォークや派生作品は歓迎します — ただし出典を明記してください。

<p align="center">
  <img src="./images/boluobobo-mascot.png" alt="菠蘿菠菠マスコット" width="120" />
</p>

# 🏛️ 三省六部 ✖️ OpenClaw

### コマンド一つで王朝を建国。六部すべてAI。遠方から百官を操り、一切手を動かす必要なし。

> **明朝の三省六部制（中書省・門下省・尚書省 → 吏部・戸部・礼部・兵部・刑部・工部）をモデルに、[OpenClaw](https://github.com/openclaw/openclaw) フレームワークで構築。**
> サーバー1台 + OpenClaw = 24時間365日稼働のAI朝廷。

<p align="center">
  <img src="https://img.shields.io/badge/モデル-六部制-gold?style=for-the-badge" />
  <img src="https://img.shields.io/badge/フレームワーク-OpenClaw-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/エージェント-18-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/OpenClawスキル-60+-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/デプロイ-5分-red?style=for-the-badge" />
</p>

<div align="center">

### 👑 ワンクリックで即位

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.sh)
```

**コマンド一つ。5分。あなたが皇帝です。** [→ クイックスタート](#クイックスタート三つのステップで即位)

🏥 **問題がありますか？** `bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/doctor.sh)` — [診断ツールドキュメント](./docs/doctor.md)

🤖 **ドキュメントを読みたくない？** [このプロンプト](./docs/install-prompt.md)をAIアシスタント（Claude / ChatGPT / DeepSeek）に渡して、ステップバイステップでガイドしてもらいましょう。

</div>

<p align="center">
  <img src="./images/flow-architecture.png" alt="システムアーキテクチャフロー" width="80%" />
</p>

---

## 📜 これは何？

**AI朝廷**は、すぐに使えるマルチAIエージェント協調システムです。中国古代の**三省六部**（中書省・門下省・尚書省 → 吏部・戸部・礼部・兵部・刑部・工部）を現代のAIエージェント組織にマッピングしています。

**簡単に言うと:** あなたは皇帝 👑、AIエージェントはあなたの大臣です。各大臣には明確な役割があります — コードを書く者、財務を管理する者、マーケティングを担当する者、DevOpsを運用する者 — あなたは「勅令」を出す（Discordでエージェントを@メンション）だけで、即座に実行されます。

### 🤔 なぜ古代の朝廷アーキテクチャ？

三省六部制は、人類史上最も長く運用された組織フレームワークの一つです（隋唐〜清朝、1,300年以上）。そのコア設計原則：

- **🏛️ 明確な職務分掌** — 各部署が担当領域を持ち、越権なし（＝各AIエージェントが専門分野を持つ）
- **📋 標準化されたプロセス** — 奏本提出と勅令審査制度（＝プロンプトテンプレート + SOUL.mdペルソナ注入）
- **🔄 相互チェック** — 三省による相互検証（＝エージェント間クロスレビュー、多段階確認）
- **📜 記録保持** — 起居注と史書（＝メモリ永続化、Notion自動アーカイブ）

これらのコンセプトは、現代のマルチエージェントシステム設計のニーズに完璧にマッピングされます。**古代の統治の知恵は、現代のAIチーム管理のベストプラクティスです。**

### 🎯 コア機能一覧

| 機能 | 説明 |
|------|------|
| 🤖 **マルチエージェント協調** | 18以上の独立AIエージェントが、それぞれ専門分野を持ち協調動作 |
| 🧠 **独立メモリ** | 各エージェントが独自のワークスペースとメモリファイルを保持 — 使うほど賢くなる |
| 🛠️ **60以上の組み込みスキル** | GitHub、Notion、ブラウザ、Cron、TTSなど、すぐに使える |
| ⏰ **自動タスク** | Cronスケジューリング + ハートビート自己チェック、24時間365日無人運転 |
| 🔒 **サンドボックス分離** | Dockerコンテナ分離、エージェントコードが独立して実行 |
| 💬 **マルチプラットフォーム** | Discord / Feishu (Lark) / Slack / Telegram / 純粋WebUI |
| 🖥️ **Webダッシュボード** | React + TypeScriptダッシュボードで視覚的に管理 |
| 🌐 **OpenClawエコシステム** | [OpenClaw](https://github.com/openclaw/openclaw)上に構築、[OpenClaw Hub](https://github.com/openclaw/openclaw)のスキルエコシステムにアクセス |

> 📖 **詳細** → [アーキテクチャ](./docs/architecture.md)

### 🏢 企業版をお好みですか？

現代の企業経営コンセプトに馴染みがある方向けに、**企業版**があります：

👉 **[Become CEO](https://github.com/wanikua/become-ceo)** — 同じアーキテクチャで、朝廷の役職の代わりにCEO / CTO / CFO / CMOなどの役職を使用

| 🏛️ 朝廷の役職 | 🏢 企業の役職 | 責務 |
|:---:|:---:|:---:|
| 皇帝 👑 | CEO | 最終意思決定者 |
| 司礼監 | COO | 日常調整、タスク委任 |
| 兵部 | CTO / VP Engineering | ソフトウェアエンジニアリング、アーキテクチャ |
| 戸部 | CFO / VP Finance | 財務分析、コスト管理 |
| 礼部 | CMO / VP Marketing | ブランドマーケティング、コンテンツ戦略 |
| 工部 | VP Infra / SRE | DevOps、インフラ |
| 吏部 | VP Product / PMO | プロジェクト管理、チーム調整 |
| 刑部 | General Counsel | 法務コンプライアンス、契約レビュー |

> 💡 両プロジェクトとも同じ [OpenClaw](https://github.com/openclaw/openclaw) フレームワーク上に構築され、アーキテクチャは同一です — 役職名と文化的コンテキストのみ異なります。お好みのスタイルをお選びください！

---

> 📌 **オリジナリティについて** — 本プロジェクトは **2025年2月22日** に初コミットされ（[コミット履歴](https://github.com/wanikua/danghuangshang/commits/main)）、「中国の朝廷制度をモデルにしたAIマルチエージェント協調」コンセプトのオリジナル実装です。[cft0808/edict](https://github.com/cft0808/edict)（初コミット2025年2月23日、約21時間後）が本プロジェクトと、フレームワーク選定、SOUL.mdペルソナファイル、install.shデプロイ方式、競合比較表において顕著な類似性を持つことを確認しました — 詳細は [Issue #55](https://github.com/cft0808/edict/issues/55) をご覧ください。
>
> **転載歓迎 — 出典を明記してください。**
>
> 📕 小紅書オリジナルシリーズ: [AI皇帝3日目 — もうハマってしまった](https://www.xiaohongshu.com/discovery/item/6998638f000000000d0092fe) | [サイバー皇帝の暮らし：寝る前に命令、AIが一晩でコードを書く](https://www.xiaohongshu.com/discovery/item/69a95dc3000000002801e886)

---

## なぜこの構成？

| | ChatGPT & Web UI | AutoGPT / CrewAI / MetaGPT | **AI朝廷（本プロジェクト）** |
|---|---|---|---|
| マルチエージェント協調 | ❌ 単一の汎用AI | ✅ Pythonオーケストレーションが必要 | ✅ 設定ファイルのみ、コード不要 |
| 永続メモリ | ⚠️ 単一の共有メモリ | ⚠️ ベクターDB自前構築 | ✅ 各エージェントが独自のワークスペース + メモリファイル |
| ツール連携 | ⚠️ 限定的なプラグイン | ⚠️ 自前構築 | ✅ 60以上の組み込みスキル（GitHub / Notion / ブラウザ / Cron …） |
| インターフェース | Web | CLI / セルフホストUI | ✅ ネイティブDiscord（スマホ＆デスクトップ対応） |
| デプロイ難易度 | デプロイ不要 | Docker + コーディング必要 | ✅ ワンラインスクリプト、5分で起動 |
| 24時間稼働 | ❌ 手動会話のみ | ✅ | ✅ Cronジョブ + ハートビート自己チェック |
| 組織メタファー | ❌ なし | ❌ なし | ✅ 六部制、明確な職務分掌 |
| フレームワークエコシステム | クローズド | 自前構築 | ✅ OpenClaw Hubスキルエコシステム |

**最大の利点：フレームワークではなく、完成品です。** スクリプトを実行し、Discordでエージェントを@メンションするだけで会話開始。

---

## アーキテクチャ

```
                        ┌───────────────────────────┐
                        │   👑 皇帝（あなた）         │
                        │   Discord / Web UI         │
                        └─────────────┬─────────────┘
                                      │ 勅令（@メンション）
                                      ▼
                    ┌──────────────────────────────────────┐
                    │   OpenClaw Gateway（中書省）           │
                    │   Node.js デーモン                     │
                    │   ┌────────────────────────────────┐  │
                    │   │ 📨 メッセージルーティング（門下省）│  │
                    │   │ @メンション → マッチ → ディスパッチ│  │
                    │   │ セッション分離 · 自動スレッド      │  │
                    │   │ Cronスケジュール · ハートビート     │  │
                    │   └────────────────────────────────┘  │
                    └───┬────┬────┬────┬────┬────┬─────────┘
                        │    │    │    │    │    │
           ┌────────────┘    │    │    │    │    └────────────┐
           ▼                 ▼    ▼    ▼    ▼                ▼
     ┌──────────┐  ┌──────┐ ┌────┐ ┌────┐ ┌──────┐  ┌──────────┐
     │ 司礼監   │  │ 兵部 │ │戸部│ │礼部│ │ 工部 │  │  刑部    │
     │Scheduler │  │Code  │ │財務│ │広報│ │DevOps│  │ 法務     │
     └──────────┘  └──────┘ └────┘ └────┘ └──────┘  └──────────┘
           │          │       │      │       │            │
           └──────────┴───────┴──────┴───────┴────────────┘
                                  │
                   ┌──────────────┴──────────────┐
                   │  尚書省（実行層）              │
                   │  60以上の組み込みスキル         │
                   │  GitHub · Notion · ブラウザ    │
                   │  Cron · TTS · スクリーンショット │
                   │  OpenClaw Hub拡張              │
                   └──────────────────────────────┘
```

各エージェントは独自のAIアイデンティティに紐付けられた独立したDiscord Botです：
- **独立メモリ**: 各エージェントが独自の `memory/` ディレクトリを持つ — 使うほどプロジェクトへの理解が深まる
- **独立モデル**: 重い作業にはパワーモデル、軽い作業には高速モデル — 品質を犠牲にせずコスト節約
- **サンドボックス実行**: エージェントのコードが分離実行、相互汚染なし
- **アイデンティティ注入**: OpenClawが自動的にSOUL.md + IDENTITY.md + ワークスペースファイルをシステムプロンプトに組み立て

---

## 🎬 デモ：Discordでの会話

```
👑 皇帝: @bingbu Node.js + Expressでユーザーログイン用のREST APIを書いてくれ

🏛️ 兵部 bingbu: 御意。直ちに取り掛かります。
  📁 auth-api/ プロジェクト構成を作成
  ✅ POST /api/login — JWT認証
  ✅ POST /api/register — ユーザー登録
  ✅ middleware/auth.js — トークン検証ミドルウェア
  ✅ GitHubにプッシュ: wanikua/auth-api#1
  作業完了いたしました。御確認ください、陛下。

👑 皇帝: @hubu 今月のAPI費用はいくらだ？

🏛️ 戸部 hubu: 陛下、今月のAPI支出でございます：
  💰 合計: $23.47
  ├── 兵部 bingbu（パワーモデル）: $15.20（コーディングタスク142件）
  ├── 礼部 libu（高速モデル）: $3.80（コピーライティングタスク89件）
  ├── 司礼監 silijian（高速モデル）: $2.12（日常会話203件）
  └── その他: $2.35
  📊 前月比12%減少、主に兵部のプロンプト長最適化によるものです。

👑 皇帝: @libu AIツール構成を紹介する小紅書の投稿を書いてくれ

🏛️ 礼部 libu: 承知いたしました！こちらがコピーです：
  📝 タイトル: 「一般人でもAI皇帝になれる？6つのAIでチーム全体を管理してます」
  本文: まだAIと一対一で会話してる？私は丸ごとAI朝廷を建てちゃいました…
  🏷️ #AIツール #生産性向上 #マルチエージェント #AI朝廷 #六部制

👑 皇帝: @everyone 明日午後3時に会議 — 全部署週報を準備せよ

🏛️ 司礼監: 承知いたしました。会議を設定しました。
🏛️ 兵部: 了解。今週のコード成果をまとめます。
🏛️ 戸部: 了解。財務報告書を準備いたします。
🏛️ 礼部: 了解。マーケティング指標をまとめます。
🏛️ 工部: 了解。サーバーステータスレポートを準備いたします。
```

---

## クイックスタート（三つのステップで即位）

> 🔴 **初心者の方：個人PCではなくクラウドサーバーを使用してください。** [セキュリティガイド](./docs/security.md)を参照。

### 📍 ステップ0：すでにOpenClawをお持ちですか？

> すでにOpenClawを実行中なら、再インストール不要です。Liteスクリプトで朝廷ワークスペースと設定テンプレートを初期化できます：
> ```bash
> bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install-lite.sh)
> ```
> その後、ステップ3に進んでキーを入力してください。**新規ユーザーの方はここを無視して、ステップ1から始めてください。**

### 📍 ステップ1：サーバーはありますか？

| 状況 | アクション |
|------|-----------|
| ✅ Linuxサーバーがある | ステップ2へ |
| ✅ Macがある | ステップ2へ |
| ❌ サーバーがない | → [**無料サーバーを取得**](./docs/server-setup.md)（Oracle Cloud: 無料4コア24GB） |

### 📍 ステップ2：プラットフォームを選択

| パス | プラットフォーム | 最適な対象 | デプロイ方法 | ドキュメント |
|:---:|----------|----------|------------|------------|
| **A** | Discord | グローバルユーザー / 初心者 | Linuxワンラインスクリプト | [→ パスA](./docs/setup-linux-discord.md) |
| **B** | 任意 | Docker経験者 | Dockerコンテナ | [→ パスB](./docs/setup-docker.md) |
| **C** | 任意 | Macユーザー | macOS Homebrew | [→ パスC](./docs/setup-macos.md) |
| **D** | Feishu (Lark) | 中国ユーザー | Linuxワンラインスクリプト | [→ パスD](./docs/setup-feishu.md) |
| **E** | 純粋WebUI | Bot不要 | APIキーのみ | [→ パスE](./docs/setup-webui.md) |
| **W** | 任意 | Windowsユーザー | WSL2 | [→ WSL2ガイド](./docs/windows-wsl.md) |

> 💡 **迷ったら？** 中国ユーザー → **D**（Feishu）。グローバルユーザー → **A**（Discord）。

### 📍 ステップ3：インストール → キー追加 → 起動

```bash
# 1️⃣ ワンラインインストール（Linux例）
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.sh)

# 2️⃣ APIキーとBotトークンを追加
nano ~/.openclaw/openclaw.json

# 3️⃣ 起動
systemctl --user start openclaw-gateway
```

Botを@メンションして返信が来れば = 即位完了！ 🎉

> 📖 **ステップバイステップチュートリアル** → [基礎チュートリアル](./docs/tutorial-basics.md)

---

### 📍 オプション拡張（インストール後いつでも追加可能）

| 拡張機能 | 説明 | 必須？ | ドキュメント |
|---------|------|--------|------------|
| 📝 Notion | 日報・週報の自動生成 | オプション | [→ Notionガイド](./docs/notion-setup.md) |
| 🖥️ Web GUI | 視覚的管理ダッシュボード | オプション | [→ GUIドキュメント](./docs/gui.md) |
| ⏰ Cronタスク | 自動スケジューリング | オプション | [→ 上級チュートリアル](./docs/tutorial-advanced.md) |
| 🛡️ セキュリティ | サンドボックス設定 | 推奨 | [→ セキュリティガイド](./docs/security.md) |
| 🏥 診断 | ワンクリックトラブルシューティング | 必要時 | [→ 診断ツール](./docs/doctor.md) |

---

### 翰林院 OpenViking連携

OpenVikingは、拡張3D永続メモリのための**オプションプラグイン**です。デフォルトのメモリシステムはファイルベースで、`novel-memory` スキルが提供します。OpenVikingをオプションアップグレードとしてインストールするには：

```bash
openclaw plugins install ./extensions/novel-openviking
```

インストール後、OpenVikingは以下のMCPサーバーモジュールを提供します：

| OpenVikingモジュール | 機能 | ユースケース |
|---------------------|------|------------|
| Memories | 静的知識 + 動的ログ | 章の要約、キャラクター状態、伏線追跡 |
| Resources | 参考資料ライブラリ | 参考小説、文体サンプル |
| Skills | 構造化ナレッジグラフ | キャラクター関係、世界観設定 |

> OpenVikingプラグインなしでは、すべてのメモリ操作は組み込みのファイルベース `novel-memory` スキルを使用し、エージェントの `memory/` ディレクトリにデータを保存します。OpenVikingは、構造化グラフクエリが有益となる大規模小説（100章以上）に推奨されます。

---

## コア機能

### 🤖 マルチエージェント協調
各部署が独自のBotです。一つを@メンションすれば応答し、@everyoneで全員が起動します。大きなタスクは自動的にスレッドを生成してチャンネルを整理します。
> ⚠️ Bot間のインタラクション（しりとりゲーム、マルチBot議論など）を有効にするには、`openclaw.json` の `channels.discord` セクションに `"allowBots": "mentions"` を追加してください。これにより、Botは他のBotから@メンションされた時のみ応答し、無限返信ループを防ぎます。この設定がないと、BotはデフォルトでBot間のメッセージを無視します。各アカウントには `"groupPolicy": "open"` も必要です。そうでないとグループメッセージがサイレントに破棄されます。

### 🧠 独立メモリシステム
各エージェントが独自のワークスペースと `memory/` ディレクトリを持ちます。会話を通じて蓄積されたプロジェクト知識はファイルに永続化され、セッションを超えて保持されます。エージェントを使うほど、プロジェクトへの理解が深まります。

### 🛠️ 60以上の組み込みスキル（OpenClawエコシステム搭載）
単なるチャットボットではありません — 組み込みツールセットが開発ライフサイクル全体をカバーし、[OpenClaw Hub](https://github.com/openclaw/openclaw)からさらにスキルを拡張できます：

| カテゴリ | スキル |
|---------|--------|
| 開発 | GitHub（Issues/PRs/CI）、Coding Agent |
| ドキュメント | Notion（データベース/ページ/自動レポート） |
| 情報 | ブラウザ自動化、Web検索、Webスクレイピング |
| 自動化 | Cronスケジュールタスク、ハートビート自己チェック |
| メディア | TTS音声、スクリーンショット、動画フレーム抽出 |
| 運用 | tmuxリモート制御、シェルコマンド実行 |
| コミュニケーション | Discord、Slack、Lark（Feishu）、Telegram、WhatsApp、Signal… |
| 拡張 | OpenClaw Hubコミュニティスキル、カスタムスキル |

### ⏰ スケジュールタスク（Cron）
組み込みCronスケジューラーにより、エージェントがタスクを自動実行：
- 日報を自動生成、Discordに投稿 + Notionに保存
- 週次サマリーのロールアップ
- 定期的なヘルスチェックとコードバックアップ
- 思いつくあらゆるカスタム定期タスク

### 👥 チームコラボレーション
友人をDiscordサーバーに招待 — 全員が部署Botを@メンションしてコマンドを出せます。ユーザー間の干渉はなく、結果は全員に表示されます。

### 🔒 サンドボックス分離
エージェントはDockerサンドボックス内で分離されたコード実行が可能です。ネットワーク、ファイルシステム、環境変数に対して設定可能な分離レベルをサポートしています。

---

## 🖥️ GUI管理インターフェース

Discordコマンドラインのやり取り以外にも、AI朝廷は複数のグラフィカルインターフェース（GUI）管理オプションを提供します：

### Webダッシュボード（菠蘿朝ダッシュボード）

本プロジェクトには組み込みのWeb管理ダッシュボード（`gui/` ディレクトリ内）が含まれており、React + TypeScript + Viteで構築されています：

<p align="center">
  <img src="./images/gui-court.png" alt="朝廷概要 — 全部署を一目で" width="90%" />
  <br/>
  <em>朝廷概要 — 玉座、六部、補助機関のライブステータス</em>
</p>

<p align="center">
  <img src="./images/gui-sessions.png" alt="セッション管理 — トークン消費とメッセージ統計" width="90%" />
  <br/>
  <em>セッション管理 — 88セッション、9008メッセージ、87.34Mトークンをリアルタイム追跡</em>
</p>

機能一覧：
- **ダッシュボード**: 部署ステータス、トークン消費、システム負荷のリアルタイム表示
- **朝廷ホール**: Webインターフェースから直接部署Botとチャット
- **セッション管理**: 全履歴セッション、メッセージ詳細、トークン統計を閲覧
- **Cronジョブ**: スケジュールタスクの視覚的管理（有効化/無効化/手動トリガー）
- **トークン分析**: 部署別・日別のトークン消費内訳
- **システムヘルス**: CPU/メモリ/ディスク監視、Gatewayステータス

**起動方法:**
```bash
# フロントエンドをビルド
cd gui && npm install && npm run build

# バックエンドAPIサーバーを起動（デフォルトポート18795）
cd server && npm install && node index.js
```

アクセス: `http://your-server-ip:18795`

> 💡 本番環境では、ポートを直接公開せず、Nginxリバースプロキシ + HTTPSを使用してください。

### DiscordをGUIとして

Discord自体が最良のGUI管理インターフェースです：
- **スマホ + デスクトップ** 同期 — どこからでも管理
- **チャンネルカテゴリ** が自然に部署にマッピング（兵部、戸部、礼部…）
- **メッセージ履歴** が永久保存、組み込み検索機能付き
- **権限管理** で誰が何を見て何ができるか細かく制御
- **@メンション** でエージェントを呼び出し — 学習コストゼロ

### Notionをデータ可視化に

OpenClawのNotion Skill連携により、朝廷データがNotionに自動同期：
- **日報** と **週次サマリー** が自動生成
- **財務追跡** がAPI消費を自動記録
- **プロジェクトアーカイブ** が全プロジェクトの進捗を追跡
- Notionのカンバン、カレンダー、テーブルビューで豊富なデータ可視化

> 💡 三層GUI: **Webダッシュボード** でシステムステータス → **Discord** でコマンド発行 → **Notion** でレポートと履歴データ。

---

## 詳細チュートリアル

基礎（サーバー準備 → インストール → 設定 → 初回起動）と上級トピック（tmux、GitHub、Notion、Cron、Discord、プロンプトエンジニアリングのヒント）については、小紅書のチュートリアルシリーズをご覧ください。

---

## FAQ

**Q: プログラミングの知識は必要ですか？**
→ いいえ。ワンラインスクリプトですべてインストールされます。Discordで自然言語でやり取り。

**Q: ChatGPTとの違いは？**
→ ChatGPT = 単一の汎用AI、すべて忘れる。本プロジェクト = 永続メモリ、ツール、自動化を備えた複数の専門家。

**Q: 他のモデルを使えますか？**
→ はい。OpenClawはAnthropic、OpenAI、Google Gemini、およびOpenAI API互換の任意のプロバイダーをサポートしています。部署ごとに異なるモデルを使用可能。

**Q: 月額API費用は？**
→ ライト: $10-15。ミディアム: $20-30。重いタスクにパワーモデル、軽いタスクに高速モデルを使い分け（5倍の節約）。

**Q: Become CEOとの関係は？**
→ 同じOpenClawフレームワークとアーキテクチャですが、朝廷の役職の代わりに現代の企業役職（CTO、CFOなど）を使用。

**Q: @everyoneで応答がない？**
→ 各Botで Message Content Intent + Server Members Intent を有効にしてください。[診断ツール](./docs/doctor.md)を参照。

**Q: Botの返信が@everyoneをpingする？**
→ サーバー設定 → ロール → @everyone → 「@everyone、@here、すべてのロールへのメンション」を無効化（サーバーオーナーは影響なし）

**Q: サンドボックス有効化後にエージェントが権限エラーを報告する？**
→ サンドボックスモード `all` はデフォルト制限付きDockerコンテナを使用します。`workspaceAccess: "rw"`、`docker.network: "bridge"` を設定し、`docker.env` でAPIキーを渡してください。

**Q: 複数ユーザーが同じエージェントを@メンションすると競合する？**
→ いいえ。OpenClawはユーザー × エージェントの組み合わせごとに独立したセッションを維持します。

**Q: エージェント同士が呼び出せる？**
→ はい。`sessions_spawn` でサブタスクを委任するか、`sessions_send` で他のエージェントのセッションにメッセージを送れます。

**Q: カスタムスキルの作り方は？**
→ 各スキルは `SKILL.md` + スクリプトのディレクトリです。`skills/` に配置すれば、エージェントがすぐに使用可能。コミュニティスキルは [OpenClaw Hub](https://github.com/openclaw/openclaw) で入手可能。

**Q: プライベートモデル（Ollamaなど）に接続するには？**
→ `openclaw.json` の `models.providers` にOpenAI API互換プロバイダーを追加し、`baseUrl` をOllamaアドレスに指定。

**Q: Gatewayの起動失敗をトラブルシューティングするには？**
→ `journalctl --user -u openclaw-gateway --since today --no-pager` または `openclaw doctor` を実行。よくある原因: APIキー未設定、JSON不正、Botトークン無効。

> 📖 **完全FAQ** → [FAQ](./docs/faq.md)

---

## 🏛️ 朝廷に参加

| 小紅書 | WeChat公式: 菠言菠語 | WeChatグループ: OpenClaw皇帝の集い |
|:---:|:---:|:---:|
| <a href="https://www.xiaohongshu.com/user/profile/5a169df34eacab2bc9a7a22d"><img src="./images/avatar-xiaohongshu.png" width="180" style="border-radius:50%"/></a> | <img src="./images/qr-wechat-official.jpg" width="180"/> | <img src="./images/qr-wechat-group.png" width="180"/> |
| [@菠萝菠菠🍍](https://www.xiaohongshu.com/user/profile/5a169df34eacab2bc9a7a22d) | チュートリアル＆更新情報をフォロー | QRが期限切れの場合は公式アカウントで最新リンクを確認 |

## 🤝 おすすめ

- 🎁 [MiniMax Coding Plan](https://platform.minimaxi.com/subscribe/coding-plan?code=CIeSxc2iq2&source=link) — 限定12%割引 + ビルダー特典

## 関連リンク

- 🏢 [Become CEO — 企業版](https://github.com/wanikua/become-ceo) — 同じアーキテクチャ、現代の企業役職
- 🎭 [AI朝廷スキル — 中国語](https://github.com/wanikua/ai-court-skill)
- 🔧 [OpenClawフレームワーク](https://github.com/openclaw/openclaw) — 本プロジェクトの基盤フレームワーク
- 📖 [OpenClaw公式ドキュメント](https://docs.openclaw.ai)
- 📚 [完全ドキュメント一覧](./docs/README.md)

---

## ⚠️ オリジナリティ＆権利に関する通知

本プロジェクトは **2025年2月22日** に初公開されました。証拠の詳細: [GitHub Issue](https://github.com/cft0808/edict/issues/55) | [権利記事](https://mp.weixin.qq.com/s/erVkoANrpZQFawMCNn6p9g)。フォーク歓迎 — 出典を明記してください。

---

## 🛡️ セキュリティガイド

> 詳細 → [セキュリティガイド](./docs/security.md)

- 🔴 **個人PCにインストールしないでください** — クラウドサーバーを使用
- 🔴 **ワークスペースを専用ディレクトリに設定**（例: `/home/ubuntu/clawd`）
- 🔴 **APIキーを公開リポジトリにコミットしない**
- 💡 非コーディング部署: サンドボックス `"off"`。コーディング部署: サンドボックス `"all"`

---

## 🔄 インストール済み？ ワンクリック更新

> 💡 安全に実行可能 — SOUL.md、USER.md、IDENTITY.md、openclaw.jsonは上書きされません。

```bash
# インストールスクリプトを再実行（設定は自動保持）
bash <(curl -fsSL https://raw.githubusercontent.com/wanikua/danghuangshang/main/install.sh)

# Dockerユーザー
docker pull boluobobo/ai-court:latest && docker compose up -d

# 手動更新
npm update -g openclaw && systemctl --user restart openclaw-gateway
```

---

## 免責事項

本プロジェクトは「現状のまま」提供され、いかなる保証もありません。AI生成コンテンツは参考用です — 本番使用前にレビューしてください。財務・セキュリティに関わる操作にはヒューマンレビューが必要です。

---

v3.5.3 | MIT License

> 📜 MITライセンス。派生作品はクレジット表記をお願いします: [danghuangshang](https://github.com/wanikua/danghuangshang) by [@wanikua](https://github.com/wanikua)
