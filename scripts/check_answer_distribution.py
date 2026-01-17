"""answerIndexの分布を確認するスクリプト"""
import json
import sys
from pathlib import Path

def check_distribution(json_file: str):
    """JSONファイルのanswerIndex分布を確認"""
    with open(json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    counts = [0, 0, 0, 0]
    for q in data:
        idx = q.get('answerIndex', -1)
        if 0 <= idx <= 3:
            counts[idx] += 1
    
    total = sum(counts)
    print(f"ファイル: {json_file}")
    print(f"合計問題数: {total}")
    print(f"answerIndex分布:")
    for i, count in enumerate(counts):
        percentage = (count / total * 100) if total > 0 else 0
        print(f"  [{i}]: {count:4d}問 ({percentage:5.1f}%)")
    print()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        json_file = sys.argv[1]
    else:
        # 最新のall_questionsファイルを探す
        generated_dir = Path(__file__).parent / "generated"
        json_files = list(generated_dir.glob("all_questions_*.json"))
        if not json_files:
            print("JSONファイルが見つかりません")
            sys.exit(1)
        json_file = max(json_files, key=lambda p: p.stat().st_mtime)
        print(f"最新のファイルを使用: {json_file}")
    
    check_distribution(str(json_file))
