"""ルールクイズと歴史クイズの詳細を確認するスクリプト"""
import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

conn = sqlite3.connect(str(DB_PATH))
cursor = conn.cursor()

print("="*60)
print("ルールクイズと歴史クイズの確認")
print("="*60)

for category in ['rules', 'history']:
    print(f"\n【{category.upper()}】")
    print("-" * 60)
    
    # 総件数
    cursor.execute("SELECT COUNT(*) FROM questions WHERE category = ?", (category,))
    total = cursor.fetchone()[0]
    print(f"総件数: {total}問")
    
    # 難易度別の件数
    cursor.execute("""
        SELECT difficulty, COUNT(*) 
        FROM questions 
        WHERE category = ? 
        GROUP BY difficulty 
        ORDER BY difficulty
    """, (category,))
    print("\n難易度別の件数:")
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]}問")
    
    # ID形式の分布
    cursor.execute("""
        SELECT 
            CASE 
                WHEN id LIKE 'r_%' THEN 'r_で始まる'
                WHEN id LIKE 'q_%' THEN 'q_で始まる'
                WHEN id LIKE 'h_%' THEN 'h_で始まる'
                WHEN id LIKE 'manual_%' THEN 'manual_で始まる'
                ELSE 'その他'
            END as id_pattern,
            COUNT(*) as count
        FROM questions 
        WHERE category = ?
        GROUP BY id_pattern
        ORDER BY count DESC
    """, (category,))
    print("\nID形式の分布:")
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]}問")
    
    # 各難易度のID範囲とサンプル
    cursor.execute("""
        SELECT difficulty 
        FROM questions 
        WHERE category = ? 
        GROUP BY difficulty 
        ORDER BY difficulty
    """, (category,))
    difficulties = [row[0] for row in cursor.fetchall()]
    
    for difficulty in difficulties:
        print(f"\n  [{difficulty}]")
        
        # ID範囲
        cursor.execute("""
            SELECT MIN(id), MAX(id), COUNT(*) 
            FROM questions 
            WHERE category = ? AND difficulty = ?
        """, (category, difficulty))
        result = cursor.fetchone()
        if result and result[0]:
            min_id, max_id, count = result
            print(f"    ID範囲: {min_id} ～ {max_id}")
            print(f"    件数: {count}問")
        
        # IDサンプル（最初の5件と最後の5件）
        cursor.execute("""
            SELECT id 
            FROM questions 
            WHERE category = ? AND difficulty = ?
            ORDER BY id
            LIMIT 5
        """, (category, difficulty))
        first_ids = [row[0] for row in cursor.fetchall()]
        
        cursor.execute("""
            SELECT id 
            FROM questions 
            WHERE category = ? AND difficulty = ?
            ORDER BY id DESC
            LIMIT 5
        """, (category, difficulty))
        last_ids = [row[0] for row in cursor.fetchall()]
        
        if first_ids:
            print(f"    最初の5件: {', '.join(first_ids)}")
        if last_ids:
            print(f"    最後の5件: {', '.join(reversed(last_ids))}")

conn.close()
