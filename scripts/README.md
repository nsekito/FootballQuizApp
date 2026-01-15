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

`.env.example`をコピーして`.env`ファイルを作成し、APIキーを設定してください：

```powershell
copy .env.example .env
```

`.env`ファイルを編集して、実際のAPIキーを設定：
```
GEMINI_API_KEY=実際のAPIキーをここに
FOOTBALL_API_KEY=実際のAPIキーをここに（週次クイズ用、後で設定可）
```

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

## ファイル構成

- `config.py` - 設定ファイル（環境変数読み込み）
- `generate_static_questions.py` - 常設クイズ生成スクリプト
- `json_to_db.py` - JSONからSQLite DBへの変換スクリプト
- `utils/gemini_client.py` - Gemini APIクライアント
- `utils/question_validator.py` - 問題検証ユーティリティ

## 注意事項

- APIキーは`.env`ファイルに保存し、Gitにコミットしないでください
- 生成には時間がかかります（1問あたり約1-2秒）
- APIレート制限に注意してください
