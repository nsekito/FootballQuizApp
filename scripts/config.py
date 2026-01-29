"""設定ファイル - 環境変数の読み込み"""
import os
from dotenv import load_dotenv

# ローカル開発時は.envファイルから読み込み
# GitHub Actions実行時は環境変数から読み込み（自動）
load_dotenv()

# Gemini API（GCPプロジェクトのAPIキーを使用）
# GCPプロジェクトのAPIキーは、Google Cloud Consoleの「APIとサービス」→「認証情報」で作成できます
GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')

# GCPプロジェクト情報（参考情報、必須ではない）
# 従量課金はGCPプロジェクトに紐づいているため、自動的に適用されます
VERTEX_AI_PROJECT_ID = os.getenv('VERTEX_AI_PROJECT_ID')  # 参考情報として残す（必須ではない）
VERTEX_AI_LOCATION = os.getenv('VERTEX_AI_LOCATION', 'asia-northeast1')  # 参考情報として残す（必須ではない）

# 使用するAPIタイプ（現在は'gemini'のみサポート）
API_TYPE = os.getenv('API_TYPE', 'gemini')  # デフォルト: gemini

# Geminiモデル名（オプション、デフォルト: gemini-3-pro-preview）
GEMINI_MODEL_NAME = os.getenv('GEMINI_MODEL_NAME', 'gemini-3-pro-preview')

# Weekly Recap出力ディレクトリ（オプション、デフォルト: data/weekly_recap）
WEEKLY_RECAP_OUTPUT_DIR = os.getenv('WEEKLY_RECAP_OUTPUT_DIR', 'data/weekly_recap')

# APIキーの検証
if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEYが設定されていません。.envファイルまたは環境変数を確認してください。")
