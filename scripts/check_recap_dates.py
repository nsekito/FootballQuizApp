"""週間マッチクイズの日付を確認するスクリプト"""
import sqlite3
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

conn = sqlite3.connect(str(DB_PATH))
cursor = conn.cursor()

print("="*60)
print("週間マッチクイズ（match_recap）の日付確認")
print("="*60)

# 日付別の件数
cursor.execute("""
    SELECT reference_date, COUNT(*) as count
    FROM questions 
    WHERE category = 'match_recap'
    GROUP BY reference_date
    ORDER BY reference_date DESC
""")

print("\n日付別の登録件数:")
dates_info = []
for row in cursor.fetchall():
    date_str, count = row
    dates_info.append((date_str, count))
    print(f"  {date_str}: {count}問")

# 難易度別の内訳
print("\n難易度別の内訳:")
cursor.execute("""
    SELECT difficulty, COUNT(*) 
    FROM questions 
    WHERE category = 'match_recap'
    GROUP BY difficulty 
    ORDER BY difficulty
""")
for row in cursor.fetchall():
    print(f"  {row[0]}: {row[1]}問")

# リーグタイプ別の内訳（weeklyMetaから取得）
print("\nリーグタイプ別の内訳（推定）:")
cursor.execute("""
    SELECT weekly_meta, COUNT(*) 
    FROM questions 
    WHERE category = 'match_recap'
    GROUP BY weekly_meta
""")
for row in cursor.fetchall():
    meta_str = row[0] if row[0] else "不明"
    print(f"  {meta_str[:50]}...: {row[1]}問")

print(f"\n総件数: {sum(count for _, count in dates_info)}問")
print(f"登録されている週数: {len(dates_info)}週")

conn.close()
