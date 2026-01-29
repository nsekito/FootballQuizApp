"""historyカテゴリの問題数を確認するスクリプト"""
import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

def check_history_count():
    """historyカテゴリの問題数を確認"""
    if not DB_PATH.exists():
        print(f"エラー: データベースファイルが見つかりません: {DB_PATH}")
        return
    
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    
    # historyカテゴリの問題数を確認
    cursor.execute('SELECT COUNT(*) FROM questions WHERE category = ?', ('history',))
    history_count = cursor.fetchone()[0]
    print(f"historyカテゴリの問題数: {history_count}問")
    
    # 難易度別の内訳
    cursor.execute('''
        SELECT difficulty, COUNT(*) 
        FROM questions 
        WHERE category = ?
        GROUP BY difficulty
        ORDER BY difficulty
    ''', ('history',))
    print("\n難易度別:")
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]}問")
    
    # 全カテゴリの問題数
    cursor.execute('SELECT category, COUNT(*) FROM questions GROUP BY category')
    print("\n全カテゴリの問題数:")
    for row in cursor.fetchall():
        print(f"  {row[0]}: {row[1]}問")
    
    conn.close()

if __name__ == "__main__":
    check_history_count()
