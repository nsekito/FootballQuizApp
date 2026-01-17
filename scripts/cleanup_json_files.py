"""JSONファイル整理スクリプト - 古いファイルを削除し、最新のファイルのみを残す"""
import os
import sys
from pathlib import Path
from collections import defaultdict

# プロジェクトルートを取得（scripts/から見て../）
PROJECT_ROOT = Path(__file__).parent.parent
GENERATED_DIR = PROJECT_ROOT / "scripts" / "generated"
ROOT_GENERATED_DIR = PROJECT_ROOT / "generated"


def cleanup_generated_files(generated_dir: Path, keep_current_file: Path = None):
    """generatedディレクトリ内の古いJSONファイルを削除し、最新のファイルのみを残す"""
    if not generated_dir.exists():
        print(f"ディレクトリが存在しません: {generated_dir}")
        return
    
    # all_questionsファイルとカテゴリ難易度ごとのファイルを分ける
    all_files = []
    category_difficulty_files = defaultdict(list)
    
    for json_file in generated_dir.glob("*.json"):
        filename = json_file.name
        
        if filename.startswith("all_questions_"):
            all_files.append(json_file)
        else:
            # {category}_{difficulty}_{timestamp}.json の形式
            parts = filename.replace(".json", "").split("_")
            if len(parts) >= 3:
                category = parts[0]
                difficulty = parts[1]
                key = f"{category}_{difficulty}"
                category_difficulty_files[key].append(json_file)
    
    deleted_count = 0
    
    # all_questionsファイル: 最新の1つだけ残す
    if all_files:
        all_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        latest_all = all_files[0]
        
        # 現在登録中のファイルは削除しない
        if keep_current_file and latest_all.samefile(keep_current_file):
            print(f"現在登録中のファイルは保持: {latest_all.name}")
        else:
            print(f"最新のallファイルを保持: {latest_all.name}")
        
        # 古いallファイルを削除
        for old_file in all_files[1:]:
            if keep_current_file and old_file.samefile(keep_current_file):
                print(f"現在登録中のファイルは保持: {old_file.name}")
                continue
            print(f"削除: {old_file.name}")
            old_file.unlink()
            deleted_count += 1
    
    # カテゴリ難易度ごとのファイル: 各組み合わせで最新の1つだけ残す
    for key, files in category_difficulty_files.items():
        files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
        latest_file = files[0]
        
        # 現在登録中のファイルは削除しない
        if keep_current_file and latest_file.samefile(keep_current_file):
            print(f"現在登録中のファイルは保持: {latest_file.name}")
        else:
            print(f"最新の{key}ファイルを保持: {latest_file.name}")
        
        # 古いファイルを削除
        for old_file in files[1:]:
            if keep_current_file and old_file.samefile(keep_current_file):
                print(f"現在登録中のファイルは保持: {old_file.name}")
                continue
            print(f"削除: {old_file.name}")
            old_file.unlink()
            deleted_count += 1
    
    print(f"\n削除完了: {deleted_count}個のファイルを削除しました")


def main():
    """メイン処理"""
    import argparse
    
    parser = argparse.ArgumentParser(description='JSONファイルを整理して古いファイルを削除')
    parser.add_argument('--keep-current', help='現在登録中のJSONファイルのパス（このファイルは削除しない）')
    parser.add_argument('--delete-root-generated', action='store_true', help='ルートのgeneratedフォルダを削除')
    
    args = parser.parse_args()
    
    keep_current_file = None
    if args.keep_current:
        keep_current_file = Path(args.keep_current)
        if not keep_current_file.exists():
            print(f"警告: 指定されたファイルが見つかりません: {args.keep_current}")
            keep_current_file = None
    
    print("=" * 60)
    print("JSONファイル整理スクリプト")
    print("=" * 60)
    
    # scripts/generatedの整理
    print(f"\n【scripts/generated/の整理】")
    cleanup_generated_files(GENERATED_DIR, keep_current_file)
    
    # ルートのgeneratedフォルダを削除
    if args.delete_root_generated and ROOT_GENERATED_DIR.exists():
        print(f"\n【ルートのgeneratedフォルダを削除】")
        import shutil
        try:
            shutil.rmtree(ROOT_GENERATED_DIR)
            print(f"削除完了: {ROOT_GENERATED_DIR}")
        except Exception as e:
            print(f"エラー: {ROOT_GENERATED_DIR}の削除に失敗しました: {e}")
    
    print("\n" + "=" * 60)
    print("整理完了！")
    print("=" * 60)


if __name__ == "__main__":
    main()
