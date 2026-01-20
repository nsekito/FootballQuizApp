# クイズ問題生成スクリプト

このディレクトリには、Gemini APIを使用してクイズ問題を自動生成するPythonスクリプトが含まれています。

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
FOOTBALL_API_KEY=実際のAPIキーをここに（週次クイズ用、後で設定可）
```

**重要**: 
- GCPプロジェクトのAPIキーは、Google Cloud Consoleで作成できます
- Gemini APIが有効になっていることを確認してください
- 従量課金はGCPプロジェクトに紐づいているため、自動的に適用されます

**重要**: `.env`ファイルはGitにコミットしないでください（既に`.gitignore`に追加済み）

## 使用方法

### 常設クイズの生成

**すべてのカテゴリ・難易度を生成（本番）:**
```powershell
python generate_static_questions.py
```

**テストモード（各難易度5問のみ）:**
```powershell
python generate_static_questions.py --test
```

**ルールクイズのみ生成:**
```powershell
python generate_static_questions.py --category rules
```

**特定の難易度のみ生成:**
```powershell
python generate_static_questions.py --difficulty easy
```

**カスタム生成数:**
```powershell
python generate_static_questions.py --category rules --count 10
```

生成されたJSONファイルは`generated/`ディレクトリに保存されます。

### JSONからデータベースへの変換

```powershell
# データベーススキーマを作成して変換
python json_to_db.py generated/all_questions_YYYYMMDD_HHMMSS.json --create-schema

# 既存のデータベースに追加（既存の問題は置き換え）
python json_to_db.py generated/all_questions_YYYYMMDD_HHMMSS.json --replace
```

### 手動で問題を作成・登録する

Gemini APIで自動生成した問題とは別に、手動で問題を作成して登録することができます。

#### 方法1: 対話型スクリプトを使用（推奨）

```powershell
# 1問作成
python create_manual_question.py

# 複数問作成
python create_manual_question.py --count 5

# 出力ファイルを指定
python create_manual_question.py --output my_questions.json
```

スクリプトを実行すると、対話的に以下を入力できます：
- カテゴリ（rules, history, teams）
- 難易度（easy, normal, hard, extreme）
- 問題文
- 4つの選択肢
- 正解の選択肢番号
- 解説
- 豆知識（オプション）
- タグ
- 対象年月（オプション）

#### 方法2: JSONファイルを直接編集

1. **テンプレートファイルをコピー**:
   ```powershell
   copy manual_question_template.json my_manual_questions.json
   ```

2. **JSONファイルを編集**:
   - `my_manual_questions.json`を開いて問題を記入
   - 問題IDは`manual_{category}_{difficulty}_{YYYYMMDD}_{3桁の連番}`形式で指定
   - 例: `manual_rules_easy_20250119_001`

3. **データベースに登録**:
   ```powershell
   # 手動作成の問題として登録（--manualフラグを使用）
   python json_to_db.py my_manual_questions.json --manual --replace
   ```

#### 手動作成の問題の特徴

- 問題IDは`manual_`で始まります（例: `manual_rules_easy_20250119_001`）
- `--manual`フラグを使用すると、手動作成の問題として識別されます
- 既存の自動生成問題と区別して管理できます

#### 注意事項

- 問題IDは既存の問題と重複しないように注意してください
- 選択肢は必ず4つである必要があります
- `answerIndex`は0-3の範囲内で指定してください（0が最初の選択肢）
- 問題の品質（正解が1つだけ存在するなど）は手動で確認してください

## ファイル構成

- `config.py` - 設定ファイル（環境変数読み込み）
- `generate_static_questions.py` - 常設クイズ生成スクリプト
- `json_to_db.py` - JSONからSQLite DBへの変換スクリプト
- `create_manual_question.py` - 手動問題作成スクリプト（対話型）
- `manual_question_template.json` - 手動作成用JSONテンプレート
- `utils/gemini_client.py` - Gemini APIクライアント
- `utils/question_validator.py` - 問題検証ユーティリティ

## 注意事項

- APIキーは`.env`ファイルに保存し、Gitにコミットしないでください
- 生成には時間がかかります（1問あたり約1-2秒）
- APIレート制限に注意してください
