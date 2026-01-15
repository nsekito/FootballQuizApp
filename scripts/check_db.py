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
    
    conn.close()

if __name__ == "__main__":
    check_database()
