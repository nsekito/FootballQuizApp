"""match_recapのID体系を確認するスクリプト"""
import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

conn = sqlite3.connect(str(DB_PATH))
cursor = conn.cursor()

print("="*60)
print("match_recap（週間マッチクイズ）のID体系確認")
print("="*60)

# 総件数
cursor.execute("SELECT COUNT(*) FROM questions WHERE category = 'match_recap'")
total = cursor.fetchone()[0]
print(f"\n総件数: {total}問")

# 難易度別の件数
cursor.execute("""
    SELECT difficulty, COUNT(*) 
    FROM questions 
    WHERE category = 'match_recap'
    GROUP BY difficulty 
    ORDER BY difficulty
""")
print("\n難易度別の件数:")
for row in cursor.fetchall():
    print(f"  {row[0]}: {row[1]}問")

# ID形式の分布
cursor.execute("""
    SELECT 
        CASE 
            WHEN id LIKE 'w_%' THEN 'w_で始まる'
            WHEN id LIKE 'q_%' THEN 'q_で始まる'
            WHEN id LIKE 'r_%' THEN 'r_で始まる'
            WHEN id LIKE 'weekly_%' THEN 'weekly_で始まる'
            WHEN id LIKE 'recap_%' THEN 'recap_で始まる'
            ELSE 'その他'
        END as id_pattern,
        COUNT(*) as count
    FROM questions 
    WHERE category = 'match_recap'
    GROUP BY id_pattern
    ORDER BY count DESC
""")
print("\nID形式の分布:")
for row in cursor.fetchall():
    print(f"  {row[0]}: {row[1]}問")

# 全IDを表示
cursor.execute("""
    SELECT id, difficulty, text
    FROM questions 
    WHERE category = 'match_recap'
    ORDER BY id
""")
print("\n全ID一覧:")
for row in cursor.fetchall():
    print(f"  [{row[0]}] {row[2][:50]}... ({row[1]})")

# 各難易度のID範囲
cursor.execute("""
    SELECT difficulty 
    FROM questions 
    WHERE category = 'match_recap'
    GROUP BY difficulty 
    ORDER BY difficulty
""")
difficulties = [row[0] for row in cursor.fetchall()]

for difficulty in difficulties:
    print(f"\n【{difficulty}】")
    cursor.execute("""
        SELECT MIN(id), MAX(id), COUNT(*) 
        FROM questions 
        WHERE category = 'match_recap' AND difficulty = ?
    """, (difficulty,))
    result = cursor.fetchone()
    if result and result[0]:
        min_id, max_id, count = result
        print(f"  ID範囲: {min_id} ～ {max_id}")
        print(f"  件数: {count}問")

conn.close()
