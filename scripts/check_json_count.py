"""生成されたJSONファイルの問題数を確認するスクリプト"""
import json
from pathlib import Path

GENERATED_DIR = Path(__file__).parent / "generated"

def check_json_files():
    """生成されたJSONファイルの問題数を確認"""
    if not GENERATED_DIR.exists():
        print(f"エラー: ディレクトリが見つかりません: {GENERATED_DIR}")
        return
    
    # historyカテゴリのJSONファイルを確認
    history_files = list(GENERATED_DIR.glob("history_*.json"))
    
    print("historyカテゴリのJSONファイル:")
    total_history = 0
    for file in sorted(history_files):
        try:
            with open(file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                count = len(data)
                total_history += count
                print(f"  {file.name}: {count}問")
        except Exception as e:
            print(f"  {file.name}: エラー - {e}")
    
    print(f"\n合計: {total_history}問")
    
    # 全カテゴリのJSONファイルを確認
    print("\n全カテゴリのJSONファイル:")
    all_files = list(GENERATED_DIR.glob("*_*.json"))
    category_counts = {}
    
    for file in sorted(all_files):
        try:
            with open(file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                count = len(data)
                # ファイル名からカテゴリを抽出
                parts = file.stem.split('_')
                if len(parts) >= 2:
                    category = parts[0]
                    if category not in category_counts:
                        category_counts[category] = 0
                    category_counts[category] += count
                print(f"  {file.name}: {count}問")
        except Exception as e:
            print(f"  {file.name}: エラー - {e}")
    
    print("\nカテゴリ別合計:")
    for category, count in sorted(category_counts.items()):
        print(f"  {category}: {count}問")

if __name__ == "__main__":
    check_json_files()
