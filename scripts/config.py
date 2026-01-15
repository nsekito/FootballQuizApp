"""設定ファイル - 環境変数の読み込み"""
import os
from dotenv import load_dotenv

# ローカル開発時は.envファイルから読み込み
# GitHub Actions実行時は環境変数から読み込み（自動）
load_dotenv()

GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
FOOTBALL_API_KEY = os.getenv('FOOTBALL_API_KEY')

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEYが設定されていません。.envファイルまたは環境変数を確認してください。")
