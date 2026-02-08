"""team_id、region、difficulty、categoryでデータを取得・分析するスクリプト"""
import sqlite3
import sys
from pathlib import Path
from collections import Counter

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

def check_question_fields():
    """team_id、region、difficulty、categoryでデータを取得・分析"""
    if not DB_PATH.exists():
        print(f"エラー: データベースファイルが見つかりません: {DB_PATH}")
        return
    
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    
    # 総問題数
    cursor.execute('SELECT COUNT(*) FROM questions')
    total_count = cursor.fetchone()[0]
    print(f"\n{'='*80}")
    print(f"総問題数: {total_count}問")
    print(f"{'='*80}\n")
    
    # 1. category別の集計
    print("【1. category別の分布】")
    cursor.execute('''
        SELECT category, COUNT(*) 
        FROM questions 
        GROUP BY category
        ORDER BY category
    ''')
    for row in cursor.fetchall():
        percentage = (row[1] / total_count * 100) if total_count > 0 else 0
        print(f"  {row[0]}: {row[1]}問 ({percentage:.1f}%)")
    
    # 2. difficulty別の集計
    print("\n【2. difficulty別の分布】")
    cursor.execute('''
        SELECT difficulty, COUNT(*) 
        FROM questions 
        GROUP BY difficulty
        ORDER BY difficulty
    ''')
    for row in cursor.fetchall():
        percentage = (row[1] / total_count * 100) if total_count > 0 else 0
        print(f"  {row[0]}: {row[1]}問 ({percentage:.1f}%)")
    
    # 3. region別の集計（NULL含む）
    print("\n【3. region別の分布】")
    cursor.execute('''
        SELECT 
            CASE WHEN region IS NULL OR region = '' THEN '(NULL/空)' ELSE region END as region,
            COUNT(*) 
        FROM questions 
        GROUP BY region
        ORDER BY region
    ''')
    for row in cursor.fetchall():
        percentage = (row[1] / total_count * 100) if total_count > 0 else 0
        print(f"  {row[0]}: {row[1]}問 ({percentage:.1f}%)")
    
    # 4. team_id別の集計（NULL含む）
    print("\n【4. team_id別の分布（上位20個）】")
    cursor.execute('''
        SELECT 
            CASE WHEN team_id IS NULL OR team_id = '' THEN '(NULL/空)' ELSE team_id END as team_id,
            COUNT(*) 
        FROM questions 
        GROUP BY team_id
        ORDER BY COUNT(*) DESC
        LIMIT 20
    ''')
    for row in cursor.fetchall():
        percentage = (row[1] / total_count * 100) if total_count > 0 else 0
        print(f"  {row[0]}: {row[1]}問 ({percentage:.1f}%)")
    
    # 5. category × difficulty別の集計
    print("\n【5. category × difficulty別の分布】")
    cursor.execute('''
        SELECT category, difficulty, COUNT(*) 
        FROM questions 
        GROUP BY category, difficulty
        ORDER BY category, difficulty
    ''')
    for row in cursor.fetchall():
        print(f"  {row[0]}/{row[1]}: {row[2]}問")
    
    # 6. category × region別の集計
    print("\n【6. category × region別の分布】")
    cursor.execute('''
        SELECT 
            category,
            CASE WHEN region IS NULL OR region = '' THEN '(NULL/空)' ELSE region END as region,
            COUNT(*) 
        FROM questions 
        GROUP BY category, region
        ORDER BY category, region
    ''')
    for row in cursor.fetchall():
        print(f"  {row[0]}/{row[1]}: {row[2]}問")
    
    # 7. category × difficulty × region別の集計
    print("\n【7. category × difficulty × region別の分布】")
    cursor.execute('''
        SELECT 
            category,
            difficulty,
            CASE WHEN region IS NULL OR region = '' THEN '(NULL/空)' ELSE region END as region,
            COUNT(*) 
        FROM questions 
        GROUP BY category, difficulty, region
        ORDER BY category, difficulty, region
    ''')
    for row in cursor.fetchall():
        print(f"  {row[0]}/{row[1]}/{row[2]}: {row[3]}問")
    
    # 8. category × difficulty × team_id別の集計（teamsカテゴリのみ、上位30個）
    print("\n【8. category=teams × difficulty × team_id別の分布（上位30個）】")
    cursor.execute('''
        SELECT 
            difficulty,
            CASE WHEN team_id IS NULL OR team_id = '' THEN '(NULL/空)' ELSE team_id END as team_id,
            COUNT(*) 
        FROM questions 
        WHERE category = 'teams'
        GROUP BY difficulty, team_id
        ORDER BY COUNT(*) DESC
        LIMIT 30
    ''')
    for row in cursor.fetchall():
        print(f"  difficulty={row[0]}, team_id={row[1]}: {row[2]}問")
    
    # 9. エラーが発生しやすい条件の特定（データが0件の組み合わせを探す）
    print("\n【9. エラーが発生しやすい条件の特定】")
    print("  データが存在しない可能性のある組み合わせ:")
    
    # カテゴリと難易度の組み合わせを確認
    cursor.execute('SELECT DISTINCT category FROM questions')
    categories = [row[0] for row in cursor.fetchall()]
    
    cursor.execute('SELECT DISTINCT difficulty FROM questions')
    difficulties = [row[0] for row in cursor.fetchall()]
    
    cursor.execute("SELECT DISTINCT CASE WHEN region IS NULL OR region = '' THEN NULL ELSE region END FROM questions")
    regions = [row[0] for row in cursor.fetchall() if row[0] is not None]
    
    cursor.execute("SELECT DISTINCT CASE WHEN team_id IS NULL OR team_id = '' THEN NULL ELSE team_id END FROM questions WHERE category = 'teams'")
    team_ids = [row[0] for row in cursor.fetchall() if row[0] is not None]
    
    # teamsカテゴリで、各難易度×team_idの組み合わせを確認
    missing_combinations = []
    for difficulty in difficulties:
        for team_id in team_ids[:10]:  # 最初の10個のteam_idのみ確認
            cursor.execute('''
                SELECT COUNT(*) 
                FROM questions 
                WHERE category = ? AND difficulty = ? AND team_id = ?
            ''', ('teams', difficulty, team_id))
            count = cursor.fetchone()[0]
            if count == 0:
                missing_combinations.append(('teams', difficulty, team_id, None))
    
    if missing_combinations:
        print(f"  データが存在しない組み合わせ: {len(missing_combinations)}個")
        for combo in missing_combinations[:20]:  # 最初の20個のみ表示
            print(f"    category={combo[0]}, difficulty={combo[1]}, team_id={combo[2]}")
    else:
        print("  すべての組み合わせにデータが存在します")
    
    # 10. サンプルデータの表示（各フィールドの値の例）
    print("\n【10. サンプルデータ（各フィールドの値の例）】")
    cursor.execute('''
        SELECT id, category, difficulty, region, team_id, team
        FROM questions 
        WHERE category = 'teams' AND team_id IS NOT NULL AND team_id != ''
        LIMIT 10
    ''')
    print("  category=teams で team_id が設定されている問題:")
    for row in cursor.fetchall():
        print(f"    ID: {row[0]}")
        print(f"      category: {row[1]}, difficulty: {row[2]}")
        print(f"      region: {row[3]}, team_id: {row[4]}, team: {row[5]}")
        print()
    
    conn.close()
    
    print(f"{'='*80}")
    print("分析完了")
    print(f"{'='*80}\n")

if __name__ == "__main__":
    check_question_fields()
