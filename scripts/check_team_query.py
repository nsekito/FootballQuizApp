"""team_id検索の問題を調査するスクリプト"""
import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

def check_team_query():
    """team_id検索の問題を調査"""
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    
    print("=" * 80)
    print("データベースの実際のデータを確認")
    print("=" * 80)
    
    # category=teams, difficulty=easy, team_id=kashiwaのデータを確認
    cursor.execute('''
        SELECT id, category, difficulty, tags, team_id, team
        FROM questions 
        WHERE category = ? AND difficulty = ? AND team_id = ?
        LIMIT 5
    ''', ('teams', 'easy', 'kashiwa'))
    
    rows = cursor.fetchall()
    print(f"\ncategory=teams, difficulty=easy, team_id=kashiwa のデータ: {len(rows)}件")
    for row in rows:
        print(f"  ID: {row[0]}")
        print(f"    category: {row[1]}, difficulty: {row[2]}")
        print(f"    tags: {row[3]}")
        print(f"    team_id: {row[4]}, team: {row[5]}")
        print()
    
    # tagsフィールドにjapanが含まれているか確認
    print("\n" + "=" * 80)
    print("tagsフィールドにjapanが含まれているデータを確認")
    print("=" * 80)
    
    cursor.execute('''
        SELECT id, tags
        FROM questions 
        WHERE category = ? AND difficulty = ? AND team_id = ?
        LIMIT 5
    ''', ('teams', 'easy', 'kashiwa'))
    
    rows = cursor.fetchall()
    for row in rows:
        tags = row[1]
        has_japan = 'japan' in tags.lower() if tags else False
        print(f"  ID: {row[0]}, tags: {tags}, japan含む: {has_japan}")
    
    # SQLクエリを実際に実行してみる
    print("\n" + "=" * 80)
    print("実際のSQLクエリを実行")
    print("=" * 80)
    
    # クエリ1: category, difficulty, team_idのみ
    cursor.execute('''
        SELECT COUNT(*) 
        FROM questions 
        WHERE category = ? AND difficulty = ? AND team_id = ?
    ''', ('teams', 'easy', 'kashiwa'))
    count1 = cursor.fetchone()[0]
    print(f"クエリ1 (category, difficulty, team_idのみ): {count1}件")
    
    # クエリ2: category, difficulty, team_id, tags LIKE %japan%
    cursor.execute('''
        SELECT COUNT(*) 
        FROM questions 
        WHERE category = ? AND difficulty = ? AND tags LIKE ? AND team_id = ?
    ''', ('teams', 'easy', '%japan%', 'kashiwa'))
    count2 = cursor.fetchone()[0]
    print(f"クエリ2 (category, difficulty, tags LIKE %japan%, team_id): {count2}件")
    
    # クエリ3: category, difficulty, team_id, tags LIKE %japan% AND tags LIKE %japan%
    cursor.execute('''
        SELECT COUNT(*) 
        FROM questions 
        WHERE category = ? AND difficulty = ? AND tags LIKE ? AND tags LIKE ? AND team_id = ?
    ''', ('teams', 'easy', '%japan%', '%japan%', 'kashiwa'))
    count3 = cursor.fetchone()[0]
    print(f"クエリ3 (category, difficulty, tags LIKE %japan% AND tags LIKE %japan%, team_id): {count3}件")
    
    conn.close()
    
    print("\n" + "=" * 80)
    print("調査完了")
    print("=" * 80)

if __name__ == "__main__":
    check_team_query()
