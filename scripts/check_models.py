"""利用可能なGeminiモデルを確認するスクリプト"""
from google import genai
import sys
from pathlib import Path

scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

from config import GEMINI_API_KEY

client = genai.Client(api_key=GEMINI_API_KEY)

print("利用可能なモデル一覧:")
print("=" * 60)

try:
    # 新しいAPIでのモデル一覧取得
    models = client.models.list()
    for model in models:
        # モデルオブジェクトの属性を確認して表示
        model_name = getattr(model, 'name', str(model))
        print(f"モデル名: {model_name}")
        
        # 利用可能な属性を表示
        if hasattr(model, 'display_name') and model.display_name:
            print(f"  表示名: {model.display_name}")
        if hasattr(model, 'description') and model.description:
            print(f"  説明: {model.description}")
        if hasattr(model, 'version'):
            print(f"  バージョン: {model.version}")
        if hasattr(model, 'supported_generation_methods'):
            print(f"  サポートされている生成メソッド: {model.supported_generation_methods}")
        print("-" * 60)
except Exception as e:
    print(f"エラー: {e}")
    print("\n一般的なモデル名:")
    common_models = [
        "gemini-2.0-flash",
        "gemini-2.5-flash",
        "gemini-3-pro-preview",
        "gemini-1.5-pro",
        "gemini-1.5-flash",
    ]
    for model_name in common_models:
        print(f"  - {model_name}")
