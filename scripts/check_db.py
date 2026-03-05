"""データベースの内容を確認するスクリプト"""
import sqlite3
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

def check_database():
    """データベースの内容を確認"""
    if not DB_PATH.exists():
        print(f"エラー: データベースファイルが見つかりません: {DB_PATH}")
        return
    
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    
    # 問題数を確認
    cursor.execute('SELECT COUNT(*) FROM questions')
    total_count = cursor.fetchone()[0]
    print(f"問題数: {total_count}問")
    
    # カテゴリ・難易度別の集計
    cursor.execute('''
        SELECT category, difficulty, COUNT(*) 
        FROM questions 
        GROUP BY category, difficulty
        ORDER BY category, difficulty
    ''')
    print("\nカテゴリ・難易度別:")
    for row in cursor.fetchall():
        print(f"  {row[0]}/{row[1]}: {row[2]}問")
    
    # サンプル問題を表示
    cursor.execute('SELECT id, text, category, difficulty FROM questions LIMIT 3')
    print("\nサンプル問題:")
    for row in cursor.fetchall():
        print(f"  [{row[0]}] {row[1][:50]}... ({row[2]}/{row[3]})")
    
    # ID形式のチェック（特にチームクイズ）
    print("\n" + "="*60)
    print("ID形式のチェック")
    print("="*60)
    
    # チームクイズのIDチェック
    cursor.execute("SELECT COUNT(*) FROM questions WHERE category = 'teams'")
    teams_total = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM questions WHERE category = 'teams' AND id LIKE 'q%'")
    teams_q_start = cursor.fetchone()[0]
    
    print(f"\nチームクイズ（category='teams'）:")
    print(f"  総数: {teams_total}問")
    print(f"  IDが'q'で始まる: {teams_q_start}問")
    print(f"  IDが'q'で始まらない: {teams_total - teams_q_start}問")
    
    if teams_total > 0:
        percentage = (teams_q_start / teams_total * 100) if teams_total > 0 else 0
        print(f"  割合: {percentage:.1f}%")
    
    # チームクイズのIDサンプル表示
    if teams_total > 0:
        cursor.execute("SELECT id FROM questions WHERE category = 'teams' LIMIT 10")
        print("\n  チームクイズのIDサンプル（最初の10件）:")
        for row in cursor.fetchall():
            print(f"    {row[0]}")
        
        # qで始まらないIDがある場合
        cursor.execute("SELECT id FROM questions WHERE category = 'teams' AND id NOT LIKE 'q%' LIMIT 10")
        non_q_ids = cursor.fetchall()
        if non_q_ids:
            print("\n  IDが'q'で始まらない例（最初の10件）:")
            for row in non_q_ids:
                print(f"    {row[0]}")
    
    # 全カテゴリのID形式分布
    print("\n全カテゴリのID形式分布:")
    cursor.execute('''
        SELECT category, 
               COUNT(*) as total,
               SUM(CASE WHEN id LIKE 'q%' THEN 1 ELSE 0 END) as q_start,
               SUM(CASE WHEN id NOT LIKE 'q%' THEN 1 ELSE 0 END) as non_q_start
        FROM questions
        GROUP BY category
        ORDER BY category
    ''')
    for row in cursor.fetchall():
        category, total, q_start, non_q_start = row
        print(f"  {category}: 総数={total}問, qで始まる={q_start}問, その他={non_q_start}問")
    
    conn.close()

if __name__ == "__main__":
    check_database()
