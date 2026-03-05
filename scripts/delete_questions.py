"""指定したID範囲の問題を削除するスクリプト"""
import sqlite3
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"

def delete_questions_by_id_range(start_id: str, end_id: str, dry_run: bool = True, force: bool = False):
    """指定したID範囲の問題を削除"""
    if not DB_PATH.exists():
        print(f"エラー: データベースファイルが見つかりません: {DB_PATH}")
        return
    
    conn = sqlite3.connect(str(DB_PATH))
    cursor = conn.cursor()
    
    # 削除対象を確認
    cursor.execute("SELECT COUNT(*) FROM questions WHERE id >= ? AND id <= ?", (start_id, end_id))
    count = cursor.fetchone()[0]
    print(f"削除対象: {count}件 (ID範囲: {start_id} ～ {end_id})")
    
    if count == 0:
        print("削除対象がありません。")
        conn.close()
        return
    
    # 削除対象のサンプルを表示
    cursor.execute("SELECT id, category, difficulty, text FROM questions WHERE id >= ? AND id <= ? LIMIT 10", 
                   (start_id, end_id))
    print("\n削除対象のサンプル（最初の10件）:")
    for row in cursor.fetchall():
        print(f"  [{row[0]}] {row[3][:50]}... ({row[1]}/{row[2]})")
    
    if dry_run:
        print("\n【DRY RUNモード】実際には削除されません。")
        print("実際に削除するには、--executeオプションを指定してください。")
    else:
        if not force:
            # 確認
            print(f"\n本当に{count}件を削除しますか？ (yes/no): ", end="")
            confirm = input().strip().lower()
            
            if confirm != 'yes':
                print("削除をキャンセルしました。")
                conn.close()
                return
        
        # 削除実行
        cursor.execute("DELETE FROM questions WHERE id >= ? AND id <= ?", (start_id, end_id))
        deleted_count = cursor.rowcount
        conn.commit()
        
        print(f"\n削除完了: {deleted_count}件を削除しました。")
    
    conn.close()

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description='指定したID範囲の問題を削除')
    parser.add_argument('start_id', help='開始ID（例: r_01201）')
    parser.add_argument('end_id', help='終了ID（例: r_01300）')
    parser.add_argument('--execute', action='store_true', help='実際に削除を実行（デフォルトはDRY RUN）')
    parser.add_argument('--force', action='store_true', help='確認なしで削除を実行（--executeと併用）')
    
    args = parser.parse_args()
    
    delete_questions_by_id_range(args.start_id, args.end_id, dry_run=not args.execute, force=args.force)
