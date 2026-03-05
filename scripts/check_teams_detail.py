"""チームクイズの詳細を確認するスクリプト"""
import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

conn = sqlite3.connect(str(DB_PATH))
cursor = conn.cursor()

print("="*60)
print("チームクイズの詳細確認")
print("="*60)

# 難易度別の件数
cursor.execute("""
    SELECT difficulty, COUNT(*) 
    FROM questions 
    WHERE category = 'teams' 
    GROUP BY difficulty 
    ORDER BY difficulty
""")
print("\n【難易度別の総件数】")
for row in cursor.fetchall():
    print(f"  {row[0]}: {row[1]}問")

# IDがqで始まる難易度別の件数
cursor.execute("""
    SELECT difficulty, COUNT(*) 
    FROM questions 
    WHERE category = 'teams' AND id LIKE 'q%'
    GROUP BY difficulty 
    ORDER BY difficulty
""")
print("\n【IDがqで始まる難易度別件数】")
for row in cursor.fetchall():
    print(f"  {row[0]}: {row[1]}問")

# 各難易度のID範囲
for difficulty in ['easy', 'normal', 'hard']:
    cursor.execute("""
        SELECT MIN(id), MAX(id), COUNT(*) 
        FROM questions 
        WHERE category = 'teams' AND difficulty = ? AND id LIKE 'q%'
    """, (difficulty,))
    result = cursor.fetchone()
    if result and result[0]:
        min_id, max_id, count = result
        print(f"\n【{difficulty}】")
        print(f"  ID範囲: {min_id} ～ {max_id}")
        print(f"  件数: {count}問")
        
        # IDの連番をチェック（欠番がないか）
        if min_id.startswith('q_'):
            try:
                min_num = int(min_id.split('_')[1])
                max_num = int(max_id.split('_')[1])
                expected_count = max_num - min_num + 1
                if count != expected_count:
                    print(f"  ⚠️  警告: 期待される件数は{expected_count}問ですが、実際は{count}問です")
                    print(f"     欠番がある可能性があります")
            except:
                pass

# 各難易度でIDがqで始まらないものがあるかチェック
cursor.execute("""
    SELECT difficulty, COUNT(*) 
    FROM questions 
    WHERE category = 'teams' AND id NOT LIKE 'q%'
    GROUP BY difficulty 
    ORDER BY difficulty
""")
non_q_results = cursor.fetchall()
if non_q_results:
    print("\n【IDがqで始まらない問題】")
    for row in non_q_results:
        print(f"  {row[0]}: {row[1]}問")
else:
    print("\n【IDがqで始まらない問題】")
    print("  なし（すべてqで始まります）")

conn.close()
