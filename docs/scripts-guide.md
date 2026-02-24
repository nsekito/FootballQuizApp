# クイズ問題生成スクリプト ガイド

`scripts/` ディレクトリには、Gemini APIを使用してWeekly Recap問題を自動生成するPythonスクリプトが含まれています。

---

## セットアップ

### 前提条件

- Python 3.8以上がインストールされていること
- PowerShellが使用可能であること

### 1. venv環境の作成

プロジェクトルート（`FootballQuizApp`）で実行：

```powershell
py -m venv scripts\venv
```

### 2. venv環境の有効化

```powershell
.\scripts\venv\Scripts\Activate.ps1
```

プロンプトの前に `(venv)` が表示されれば成功です。

### 3. 依存関係のインストール

```powershell
pip install -r scripts\requirements.txt
```

### 4. APIキーの設定

`.env.example`をコピーして`.env`ファイルを作成：

```powershell
Copy-Item scripts\.env.example scripts\.env
```

`.env`ファイルを編集して、実際のAPIキーを設定：

```
API_TYPE=gemini
GEMINI_API_KEY=実際のGCPプロジェクトのAPIキーをここに
VERTEX_AI_PROJECT_ID=your-project-id
VERTEX_AI_LOCATION=asia-northeast1
```

**GCPプロジェクトのAPIキー取得手順:**

1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. プロジェクトを選択
3. 「APIとサービス」→「認証情報」→「認証情報を作成」→「APIキー」
4. 「APIとサービス」→「ライブラリ」で「Generative Language API」を有効化

**重要**: `.env`ファイルはGitにコミットしないでください（既に`.gitignore`に追加済み）

### 5. テスト実行

```powershell
python scripts\generate_weekly_recap.py --j1-only
```

### トラブルシューティング

- **Pythonが見つからない場合**: `py`コマンドを試す
- **venvの有効化ができない場合**: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

---

## 使用方法

### Weekly Recap問題の生成

```powershell
# 最新の月曜日を対象
python generate_weekly_recap.py

# 特定の日付を指定
python generate_weekly_recap.py --date 2026-02-03

# J1リーグのみ
python generate_weekly_recap.py --j1-only

# ヨーロッパのみ
python generate_weekly_recap.py --europe-only

# 出力ディレクトリを指定
python generate_weekly_recap.py --output-dir data/weekly_recap
```

ファイル名は `{YYYY-MM-DD}_{league_type}.json` 形式です。

### JSONからデータベースへの変換

```powershell
# スキーマ作成 + 変換
python json_to_db.py data/weekly_recap/2026-02-03_j1.json --create-schema

# 既存のデータベースに追加
python json_to_db.py data/weekly_recap/2026-02-03_j1.json --replace
```

### 問題の手動作成

ルールクイズ、歴史クイズ、チームクイズの手動作成については [manual-question-guide.md](manual-question-guide.md) を参照。

---

## ファイル構成

| ファイル | 説明 |
|---|---|
| `config.py` | 設定ファイル（環境変数読み込み） |
| `generate_weekly_recap.py` | Weekly Recap問題生成スクリプト |
| `json_to_db.py` | JSONからSQLite DBへの変換スクリプト |
| `utils/gemini_client.py` | Gemini APIクライアント |

---

## Vertex AI設定（オプション）

通常のGemini APIより高いクォータ制限が必要な場合に使用。

### 設定

`.env`ファイルに以下を追加：

```env
API_TYPE=vertex
VERTEX_AI_PROJECT_ID=your-project-id
VERTEX_AI_LOCATION=us-central1
VERTEX_AI_CREDENTIALS_PATH=/path/to/service-account-key.json
```

パッケージ追加：

```powershell
pip install google-cloud-aiplatform
```

### サービスアカウントキーの取得

1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. 「IAMと管理」→「サービスアカウント」
3. サービスアカウントを作成/選択 →「キー」→「JSONを作成」

### 利用可能なモデル

- `gemini-1.5-flash` - 高速・コスト効率（推奨）
- `gemini-1.5-pro` - より高品質
- `gemini-2.0-flash-exp` - 実験的

---

## 注意事項

- APIキーは`.env`ファイルに保存し、Gitにコミットしないこと
- 生成には時間がかかります（1問あたり約1-2秒）
- APIレート制限に注意
