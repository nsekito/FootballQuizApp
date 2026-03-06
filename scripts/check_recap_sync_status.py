"""Weekly Recap の DB 同期状態を確認するスクリプト"""
import sqlite3
from pathlib import Path
from datetime import datetime, timedelta

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"


def get_latest_monday() -> str:
    """直近の月曜日を YYYY-MM-DD 形式で返す"""
    today = datetime.now()
    days_from_monday = today.weekday()  # 0=月曜, 6=日曜
    monday = today - timedelta(days=days_from_monday)
    return monday.strftime("%Y-%m-%d")


def main():
    if not DB_PATH.exists():
        print(f"エラー: データベースが見つかりません: {DB_PATH}")
        return

    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()

    print("=" * 60)
    print("Weekly Recap (match_recap) の DB 同期状態")
    print("=" * 60)

    # match_recap の reference_date 別件数
    cursor.execute("""
        SELECT reference_date, COUNT(*) as count
        FROM questions
        WHERE category = 'match_recap'
        GROUP BY reference_date
        ORDER BY reference_date DESC
    """)
    rows = cursor.fetchall()

    print("\n登録されている週（reference_date 別）:")
    if rows:
        for date_str, count in rows:
            print(f"  {date_str}: {count}問")
    else:
        print("  （データなし）")

    # 最新週の確認
    latest_monday = get_latest_monday()
    cursor.execute(
        "SELECT COUNT(*) FROM questions WHERE category = 'match_recap' AND reference_date = ?",
        (latest_monday,),
    )
    latest_count = cursor.fetchone()[0]

    print(f"\n最新週（{latest_monday}）の登録状況:")
    if latest_count > 0:
        print(f"  {latest_count}問 登録済み")
    else:
        print("  未登録（データが古い可能性があります）")

    # recap_sync_history の確認（存在する場合）
    cursor.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='recap_sync_history'"
    )
    if cursor.fetchone():
        cursor.execute("""
            SELECT date, league_type, question_count, synced_at
            FROM recap_sync_history
            ORDER BY date DESC, league_type
            LIMIT 10
        """)
        sync_rows = cursor.fetchall()
        print("\nrecap_sync_history（最新10件）:")
        for row in sync_rows:
            print(f"  {row[0]} | {row[1]} | {row[2]}問")
    else:
        print("\nrecap_sync_history テーブル: 存在しません（アプリ未起動）")

    print(f"\n総 match_recap 件数: {sum(r[1] for r in rows)}問")
    conn.close()


if __name__ == "__main__":
    main()
