"""hardのIDを詳しく確認するスクリプト"""
import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

conn = sqlite3.connect(str(DB_PATH))
cursor = conn.cursor()

print("="*60)
print("チームクイズ hardのID確認")
print("="*60)

# hardのIDを取得して番号順にソート
cursor.execute("""
    SELECT id 
    FROM questions 
    WHERE category = 'teams' AND difficulty = 'hard' AND id LIKE 'q%'
    ORDER BY CAST(SUBSTR(id, 3) AS INTEGER)
""")

ids = [row[0] for row in cursor.fetchall()]
print(f"\n総件数: {len(ids)}問")

# ID番号を抽出
id_numbers = []
for id_str in ids:
    try:
        num = int(id_str.split('_')[1])
        id_numbers.append(num)
    except:
        pass

id_numbers.sort()
print(f"ID番号範囲: {min(id_numbers)} ～ {max(id_numbers)}")

# 連続している範囲を確認
print("\n連続している範囲:")
ranges = []
start = id_numbers[0]
for i in range(1, len(id_numbers)):
    if id_numbers[i] != id_numbers[i-1] + 1:
        ranges.append((start, id_numbers[i-1]))
        start = id_numbers[i]
ranges.append((start, id_numbers[-1]))

for start_num, end_num in ranges:
    count = end_num - start_num + 1
    print(f"  q_{start_num:05d} ～ q_{end_num:05d}: {count}問")

# 欠番を確認（最初の範囲と最後の範囲の間）
if len(ranges) > 1:
    print("\n欠番がある範囲:")
    for i in range(len(ranges) - 1):
        gap_start = ranges[i][1] + 1
        gap_end = ranges[i+1][0] - 1
        gap_count = gap_end - gap_start + 1
        print(f"  q_{gap_start:05d} ～ q_{gap_end:05d}: {gap_count}件の欠番")

# 最初と最後の10件を表示
print("\n最初の10件:")
for id_str in ids[:10]:
    print(f"  {id_str}")

print("\n最後の10件:")
for id_str in ids[-10:]:
    print(f"  {id_str}")

conn.close()
