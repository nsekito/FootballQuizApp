"""利用可能なGeminiモデルを確認するスクリプト"""
import google.generativeai as genai
import sys
from pathlib import Path

scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

from config import GEMINI_API_KEY

genai.configure(api_key=GEMINI_API_KEY)

print("利用可能なモデル一覧:")
print("=" * 60)

try:
    models = genai.list_models()
    for model in models:
        if 'generateContent' in model.supported_generation_methods:
            print(f"モデル名: {model.name}")
            print(f"  表示名: {model.display_name}")
            print(f"  説明: {model.description}")
            print("-" * 60)
except Exception as e:
    print(f"エラー: {e}")
