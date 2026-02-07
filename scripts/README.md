# クイズ問題生成スクリプト

このディレクトリには、Gemini APIを使用してWeekly Recap問題を自動生成するPythonスクリプトが含まれています。

## セットアップ

### 1. venv環境の作成

```powershell
cd scripts
# pythonコマンドが使えない場合はpyコマンドを使用
py -m venv venv
.\venv\Scripts\Activate.ps1
```

### 2. 依存関係のインストール

```powershell
pip install -r requirements.txt
```

### 3. APIキーの設定

#### GCPプロジェクトのAPIキーを使用する場合（推奨：従量課金）

GCPプロジェクトのAPIキーを使用して、通常のGemini APIエンドポイントで認証します。
従量課金はGCPプロジェクトに紐づいているため、自動的に適用されます。

1. **GCPプロジェクトのAPIキーを取得**:
   - [Google Cloud Console](https://console.cloud.google.com/)にアクセス
   - プロジェクトを選択
   - 「APIとサービス」→「認証情報」に移動
   - 「認証情報を作成」→「APIキー」を選択
   - 作成されたAPIキーをコピー

2. **Gemini APIを有効化**:
   - 「APIとサービス」→「ライブラリ」に移動
   - 「Generative Language API」を検索して有効化

3. **`.env`ファイルの設定**:
`.env.example`をコピーして`.env`ファイルを作成し、APIキーを設定してください：

```powershell
copy .env.example .env
```

`.env`ファイルを編集して、実際のAPIキーを設定：
```
API_TYPE=gemini
GEMINI_API_KEY=実際のGCPプロジェクトのAPIキーをここに
VERTEX_AI_PROJECT_ID=your-project-id  # 参考情報（必須ではない）
VERTEX_AI_LOCATION=asia-northeast1    # 参考情報（必須ではない）
# GEMINI_MODEL_NAME=gemini-3-pro-preview  # オプション（デフォルト: gemini-3-pro-preview）
# WEEKLY_RECAP_OUTPUT_DIR=data/weekly_recap  # オプション（デフォルト: data/weekly_recap）
```

**重要**: 
- GCPプロジェクトのAPIキーは、Google Cloud Consoleで作成できます
- Gemini APIが有効になっていることを確認してください
- 従量課金はGCPプロジェクトに紐づいているため、自動的に適用されます

**重要**: `.env`ファイルはGitにコミットしないでください（既に`.gitignore`に追加済み）

## 使用方法

### Weekly Recap問題の生成

Weekly Recap問題は、毎週実行する必要があります。Gemini APIのGrounding機能を使用して、最新の試合結果から問題を生成します。

**基本的な使用方法（最新の月曜日を対象）:**
```powershell
python generate_weekly_recap.py
```

**特定の日付を指定:**
```powershell
python generate_weekly_recap.py --date 2026-02-03
```

**J1リーグのみ生成（テスト用）:**
```powershell
python generate_weekly_recap.py --j1-only
```

**ヨーロッパサッカーのみ生成（テスト用）:**
```powershell
python generate_weekly_recap.py --europe-only
```

**出力ディレクトリを指定:**
```powershell
python generate_weekly_recap.py --output-dir data/weekly_recap
```

生成されたJSONファイルは`data/weekly_recap/`ディレクトリ（デフォルト）に保存されます。
ファイル名は`{YYYY-MM-DD}_{league_type}.json`形式（例: `2026-02-03_j1.json`）です。

### JSONからデータベースへの変換

生成されたJSONファイルをデータベースに登録するには：

```powershell
# データベーススキーマを作成して変換
python json_to_db.py data/weekly_recap/2026-02-03_j1.json --create-schema

# 既存のデータベースに追加（既存の問題は置き換え）
python json_to_db.py data/weekly_recap/2026-02-03_j1.json --replace
```

### 問題の手動作成について

ルールクイズ、歴史クイズ、チームクイズの問題は、gensparkのチャットを使用して手動で作成し、作成したJSONファイルを`json_to_db.py`で登録してください。

**詳細な手順は [MANUAL_QUESTION_GUIDE.md](MANUAL_QUESTION_GUIDE.md) を参照してください。**

**注意**: ルールクイズの問題作成時は、IFAB「サッカー競技規則」（Laws of the Game）を基準とし、大会固有ルールの場合はその旨を明記してください。

#### 基本的なワークフロー

1. **プロンプトの準備**
   - `MANUAL_QUESTION_GUIDE.md`に記載されているプロンプトテンプレートを使用
   - `# 今回の作成依頼` セクションを編集

2. **問題生成**
   - gensparkのチャットにプロンプトを貼り付け
   - JSON配列形式で問題を生成

3. **JSONファイルの保存**
   - 適切なディレクトリに保存（`data/manual_questions/`以下）
   - ファイル名は `{quizType}_{difficulty}_{YYYYMMDD}.json` 形式
   - 例: `team_easy_20260207.json`

4. **データベースへの取り込み**
   ```powershell
   python json_to_db.py data/manual_questions/team/japan/j1/team_easy_20260207.json --replace
   ```

5. **動作確認**
   - アプリで問題が正しく表示されるか確認

#### ファイル名規約

**形式:** `{quizType}_{difficulty}_{YYYYMMDD}.json`

- `quizType`: `team`, `history`, `rule`, `weekly`
- `difficulty`: `easy`, `normal`, `hard`
- `YYYYMMDD`: 作成日（例: `20260207`）

ファイル名から`quizType`と`difficulty`が自動的に検出され、JSON内の値と一致するか確認されます。

## ファイル構成

- `config.py` - 設定ファイル（環境変数読み込み）
- `generate_weekly_recap.py` - Weekly Recap問題生成スクリプト
- `json_to_db.py` - JSONからSQLite DBへの変換スクリプト
- `utils/gemini_client.py` - Gemini APIクライアント（Weekly Recap用）

## 注意事項

- APIキーは`.env`ファイルに保存し、Gitにコミットしないでください
- 生成には時間がかかります（1問あたり約1-2秒）
- APIレート制限に注意してください
