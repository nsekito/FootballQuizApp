"""欠番をチェックするスクリプト"""
import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

conn = sqlite3.connect(str(DB_PATH))
cursor = conn.cursor()

print("="*60)
print("チームクイズの欠番チェック")
print("="*60)

for difficulty in ['easy', 'normal', 'hard']:
    print(f"\n【{difficulty}】")
    
    # 存在するIDを取得
    cursor.execute("""
        SELECT id 
        FROM questions 
        WHERE category = 'teams' AND difficulty = ? AND id LIKE 'q%'
        ORDER BY id
    """, (difficulty,))
    
    ids = [row[0] for row in cursor.fetchall()]
    
    if not ids:
        print("  データなし")
        continue
    
    # IDから番号を抽出
    id_numbers = []
    for id_str in ids:
        try:
            num = int(id_str.split('_')[1])
            id_numbers.append(num)
        except:
            pass
    
    if not id_numbers:
        print("  ID番号を抽出できませんでした")
        continue
    
    id_numbers.sort()
    min_num = min(id_numbers)
    max_num = max(id_numbers)
    expected_count = max_num - min_num + 1
    actual_count = len(id_numbers)
    
    print(f"  ID範囲: q_{min_num:05d} ～ q_{max_num:05d}")
    print(f"  期待される件数: {expected_count}問")
    print(f"  実際の件数: {actual_count}問")
    
    if actual_count < expected_count:
        missing_count = expected_count - actual_count
        print(f"  [警告] 欠番: {missing_count}件")
        
        # 欠番を特定
        expected_numbers = set(range(min_num, max_num + 1))
        actual_numbers = set(id_numbers)
        missing_numbers = sorted(expected_numbers - actual_numbers)
        
        if len(missing_numbers) <= 20:
            print(f"  欠番のID: {[f'q_{n:05d}' for n in missing_numbers]}")
        else:
            print(f"  欠番のID（最初の20件）: {[f'q_{n:05d}' for n in missing_numbers[:20]]}")
            print(f"  ... 他{len(missing_numbers) - 20}件")

conn.close()
