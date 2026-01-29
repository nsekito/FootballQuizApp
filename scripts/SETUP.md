# Phase 1 セットアップ手順

## 前提条件

- Python 3.8以上がインストールされていること
- PowerShellが使用可能であること

## セットアップ手順

### 1. Pythonのバージョン確認

```powershell
python --version
```

Python 3.8以上が表示されることを確認してください。

### 2. venv環境の作成

プロジェクトルート（`FootballQuizApp`）で実行：

```powershell
# pythonコマンドが使えない場合はpyコマンドを使用
py -m venv scripts\venv
```

### 3. venv環境の有効化

```powershell
.\scripts\venv\Scripts\Activate.ps1
```

プロンプトの前に `(venv)` が表示されれば成功です。

### 4. 依存関係のインストール

venvが有効化された状態で：

```powershell
pip install -r scripts\requirements.txt
```

### 5. APIキーの設定

`.env.example`をコピーして`.env`ファイルを作成：

```powershell
Copy-Item scripts\.env.example scripts\.env
```

`.env`ファイルを編集して、実際のAPIキーを設定：

```
GEMINI_API_KEY=実際のAPIキーをここに
# GEMINI_MODEL_NAME=gemini-3-pro-preview  # オプション
# WEEKLY_RECAP_OUTPUT_DIR=data/weekly_recap  # オプション
```

### 6. テスト実行

venvが有効化された状態で：

```powershell
# テストモード（ルールクイズ、各難易度5問のみ）
python scripts\generate_static_questions.py --test --category rules
```

## トラブルシューティング

### Pythonコマンドが見つからない場合

- Pythonがインストールされているか確認
- 環境変数PATHにPythonが追加されているか確認
- `py`コマンドを試す（`py -m venv scripts\venv`）

### venvの有効化ができない場合

実行ポリシーを確認：

```powershell
Get-ExecutionPolicy
```

必要に応じて変更：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
