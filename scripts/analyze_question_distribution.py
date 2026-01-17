"""問題の分布を分析するスクリプト"""
import sqlite3
import sys
from pathlib import Path
from collections import Counter
import re

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

def analyze_distribution():
    """問題の分布を詳細に分析"""
    if not DB_PATH.exists():
        print(f"エラー: データベースファイルが見つかりません: {DB_PATH}")
        return
    
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    
    # 総問題数
    cursor.execute('SELECT COUNT(*) FROM questions')
    total_count = cursor.fetchone()[0]
    print(f"\n{'='*60}")
    print(f"総問題数: {total_count}問")
    print(f"{'='*60}\n")
    
    # カテゴリ別の集計
    print("【カテゴリ別の分布】")
    cursor.execute('''
        SELECT category, COUNT(*) 
        FROM questions 
        GROUP BY category
        ORDER BY category
    ''')
    category_counts = {}
    for row in cursor.fetchall():
        category_counts[row[0]] = row[1]
        percentage = (row[1] / total_count * 100) if total_count > 0 else 0
        print(f"  {row[0]}: {row[1]}問 ({percentage:.1f}%)")
    
    # 難易度別の集計
    print("\n【難易度別の分布】")
    cursor.execute('''
        SELECT difficulty, COUNT(*) 
        FROM questions 
        GROUP BY difficulty
        ORDER BY difficulty
    ''')
    difficulty_counts = {}
    for row in cursor.fetchall():
        difficulty_counts[row[0]] = row[1]
        percentage = (row[1] / total_count * 100) if total_count > 0 else 0
        print(f"  {row[0]}: {row[1]}問 ({percentage:.1f}%)")
    
    # カテゴリ×難易度別の集計
    print("\n【カテゴリ×難易度別の分布】")
    cursor.execute('''
        SELECT category, difficulty, COUNT(*) 
        FROM questions 
        GROUP BY category, difficulty
        ORDER BY category, difficulty
    ''')
    expected_per_category_difficulty = total_count / (len(category_counts) * len(difficulty_counts)) if category_counts and difficulty_counts else 0
    
    distribution_data = []
    for row in cursor.fetchall():
        category, difficulty, count = row
        distribution_data.append((category, difficulty, count))
        expected = expected_per_category_difficulty
        deviation = count - expected
        deviation_percent = (deviation / expected * 100) if expected > 0 else 0
        print(f"  {category}/{difficulty}: {count}問 (期待値: {expected:.1f}問, 偏差: {deviation:+.1f}問 ({deviation_percent:+.1f}%))")
    
    # 偏りの検出
    print("\n【偏りの検出】")
    if distribution_data:
        counts = [count for _, _, count in distribution_data]
        if counts:
            avg = sum(counts) / len(counts)
            max_deviation = max(abs(c - avg) for c in counts)
            max_deviation_percent = (max_deviation / avg * 100) if avg > 0 else 0
            
            print(f"  平均問題数: {avg:.1f}問")
            print(f"  最大偏差: {max_deviation:.1f}問 ({max_deviation_percent:.1f}%)")
            
            if max_deviation_percent > 20:
                print(f"  ⚠️  警告: 20%以上の偏りが検出されました")
            else:
                print(f"  ✓ 問題の分布は比較的均等です")
    
    # 問題文の類似度チェック（最初の50文字で比較）
    print("\n【問題文の類似度チェック】")
    cursor.execute('SELECT text FROM questions LIMIT 100')
    texts = [row[0] for row in cursor.fetchall()]
    
    if len(texts) > 1:
        # 問題文の最初の30文字を抽出して類似パターンを検出
        prefixes = [text[:30] for text in texts]
        prefix_counter = Counter(prefixes)
        
        duplicates = {prefix: count for prefix, count in prefix_counter.items() if count > 1}
        if duplicates:
            print(f"  ⚠️  警告: {len(duplicates)}個の類似した問題文パターンが見つかりました")
            for prefix, count in list(duplicates.items())[:5]:  # 最初の5つだけ表示
                print(f"    \"{prefix}...\": {count}回")
        else:
            print(f"  ✓ 問題文の多様性は良好です")
    
    # タグの分布
    print("\n【タグの分布】")
    cursor.execute('SELECT tags FROM questions')
    all_tags = []
    for row in cursor.fetchall():
        if row[0]:
            tags = [tag.strip() for tag in row[0].split(',')]
            all_tags.extend(tags)
    
    tag_counter = Counter(all_tags)
    print(f"  使用されているタグ数: {len(tag_counter)}")
    print(f"  最も使用されているタグ（上位10個）:")
    for tag, count in tag_counter.most_common(10):
        percentage = (count / total_count * 100) if total_count > 0 else 0
        print(f"    {tag}: {count}回 ({percentage:.1f}%)")
    
    # サンプル問題を表示
    print("\n【サンプル問題（各カテゴリ×難易度から1問ずつ）】")
    cursor.execute('''
        SELECT id, text, category, difficulty 
        FROM questions 
        ORDER BY category, difficulty, RANDOM()
        LIMIT 12
    ''')
    shown_combinations = set()
    for row in cursor.fetchall():
        combo = (row[2], row[3])
        if combo not in shown_combinations:
            shown_combinations.add(combo)
            print(f"  [{row[0]}] {row[1][:60]}... ({row[2]}/{row[3]})")
    
    conn.close()
    
    print(f"\n{'='*60}")
    print("分析完了")
    print(f"{'='*60}\n")

if __name__ == "__main__":
    analyze_distribution()
