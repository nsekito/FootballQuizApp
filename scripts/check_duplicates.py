"""データベース内の重複問題を確認するスクリプト"""
import sqlite3
from pathlib import Path
from collections import Counter

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

def check_duplicates():
    """データベース内の重複問題を確認"""
    if not DB_PATH.exists():
        print(f"エラー: データベースファイルが見つかりません: {DB_PATH}")
        return
    
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    
    # 全問題を取得
    cursor.execute('SELECT id, text, category, difficulty FROM questions')
    questions = cursor.fetchall()
    
    print(f"全問題数: {len(questions)}問")
    
    # IDの重複を確認
    ids = [q[0] for q in questions]
    id_counts = Counter(ids)
    duplicates_by_id = {id: count for id, count in id_counts.items() if count > 1}
    
    if duplicates_by_id:
        print(f"\nIDの重複: {len(duplicates_by_id)}件")
        for id, count in duplicates_by_id.items():
            print(f"  {id}: {count}回")
    else:
        print("\nIDの重複: なし")
    
    # 問題文の重複を確認
    texts = [q[1] for q in questions]
    text_counts = Counter(texts)
    duplicates_by_text = {text: count for text, count in text_counts.items() if count > 1}
    
    if duplicates_by_text:
        print(f"\n問題文の重複: {len(duplicates_by_text)}件")
        for text, count in list(duplicates_by_text.items())[:10]:  # 最初の10件のみ表示
            print(f"  {text[:50]}...: {count}回")
        if len(duplicates_by_text) > 10:
            print(f"  ... 他 {len(duplicates_by_text) - 10}件")
    else:
        print("\n問題文の重複: なし")
    
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
    
    conn.close()

if __name__ == "__main__":
    check_duplicates()
