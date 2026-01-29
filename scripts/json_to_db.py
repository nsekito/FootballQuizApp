"""JSONファイルからSQLiteデータベースへの変換スクリプト"""
import json
import sqlite3
import os
import sys
from pathlib import Path

# プロジェクトルートを取得（scripts/から見て../）
PROJECT_ROOT = Path(__file__).parent.parent
DB_PATH = PROJECT_ROOT / "data" / "questions.db"


def create_database_schema(db_path: str):
    """データベーススキーマを作成"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # questionsテーブルを作成（Flutterアプリと同じスキーマ）
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS questions (
            id TEXT PRIMARY KEY,
            text TEXT NOT NULL,
            options TEXT NOT NULL,
            answerIndex INTEGER NOT NULL,
            explanation TEXT NOT NULL,
            trivia TEXT,
            category TEXT NOT NULL,
            difficulty TEXT NOT NULL,
            tags TEXT NOT NULL,
            reference_date TEXT
        )
    ''')
    
    # インデックスを作成
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_questions_category_difficulty 
        ON questions(category, difficulty)
    ''')
    cursor.execute('''
        CREATE INDEX IF NOT EXISTS idx_questions_tags 
        ON questions(tags)
    ''')
    
    conn.commit()
    conn.close()
    print(f"データベーススキーマを作成しました: {db_path}")


def load_questions_from_json(json_path: str) -> list:
    """JSONファイルから問題を読み込む"""
    with open(json_path, 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    if not isinstance(questions, list):
        raise ValueError("JSONファイルは問題のリストである必要があります")
    
    print(f"JSONファイルから {len(questions)}問を読み込みました: {json_path}")
    return questions


def infer_metadata_from_filename(filename: str) -> dict:
    """
    ファイル名からcategory, difficulty, tagsを推測
    
    ファイル名のパターン:
    - rules_easy_20260119_000627.json → category=rules, difficulty=easy
    - manual_rules_easy_20260119_001.json → category=rules, difficulty=easy
    - my_questions.json → 推測不可
    """
    import re
    
    # ファイル名から拡張子を除去
    base_name = Path(filename).stem
    
    # パターン1: {category}_{difficulty}_{日付}_{時刻}.json
    pattern1 = r'^([a-z]+)_([a-z]+)_\d{8}_\d{6}$'
    match1 = re.match(pattern1, base_name)
    if match1:
        category = match1.group(1)
        difficulty = match1.group(2)
        return {'category': category, 'difficulty': difficulty}
    
    # パターン2: manual_{category}_{difficulty}_{日付}_{連番}.json
    pattern2 = r'^manual_([a-z]+)_([a-z]+)_\d{8}_\d{3}$'
    match2 = re.match(pattern2, base_name)
    if match2:
        category = match2.group(1)
        difficulty = match2.group(2)
        return {'category': category, 'difficulty': difficulty}
    
    # パターン3: {category}_{difficulty}で始まる
    pattern3 = r'^([a-z]+)_([a-z]+)'
    match3 = re.match(pattern3, base_name)
    if match3:
        category = match3.group(1)
        difficulty = match3.group(2)
        # 有効なカテゴリと難易度かチェック
        valid_categories = ['rules', 'history', 'teams']
        valid_difficulties = ['easy', 'normal', 'hard', 'extreme']
        if category in valid_categories and difficulty in valid_difficulties:
            return {'category': category, 'difficulty': difficulty}
    
    return {}


def get_default_tags(category: str) -> str:
    """カテゴリに応じたデフォルトのタグを返す"""
    tag_map = {
        'rules': 'rules',
        'history': 'history,japan',
        'teams': 'teams,japan',
    }
    return tag_map.get(category, category)


def add_missing_metadata(questions: list, category: str = None, difficulty: str = None, tags: str = None, json_filename: str = None) -> list:
    """
    問題リストに不足しているメタデータ（id, category, difficulty, tags）を追加
    
    Args:
        questions: 問題のリスト
        category: カテゴリ（指定がない場合はファイル名から推測）
        difficulty: 難易度（指定がない場合はファイル名から推測）
        tags: タグ（指定がない場合はカテゴリから推測）
        json_filename: JSONファイル名（ファイル名から推測する場合に使用）
    
    Returns:
        メタデータが追加された問題のリスト
    """
    from datetime import datetime
    
    # ファイル名から推測（引数で指定されていない場合）
    if json_filename and (not category or not difficulty):
        inferred = infer_metadata_from_filename(json_filename)
        if not category:
            category = inferred.get('category')
        if not difficulty:
            difficulty = inferred.get('difficulty')
    
    # タグが指定されていない場合はカテゴリから推測
    if not tags and category:
        tags = get_default_tags(category)
    
    # カテゴリと難易度がまだ不明な場合はエラー
    if not category or not difficulty:
        raise ValueError(
            "category と difficulty を指定してください。\n"
            "例: python json_to_db.py my_questions.json --category rules --difficulty easy\n"
            "または、ファイル名を {category}_{difficulty}_*.json の形式にしてください。"
        )
    
    # 各問題にメタデータを追加
    updated_questions = []
    for i, question in enumerate(questions):
        updated_question = question.copy()
        
        # IDが無い場合は生成
        if 'id' not in updated_question or not updated_question['id']:
            date_str = datetime.now().strftime('%Y%m%d')
            updated_question['id'] = f"manual_{category}_{difficulty}_{date_str}_{i+1:03d}"
        
        # category, difficulty, tagsを追加（既存の値がある場合は上書きしない）
        if 'category' not in updated_question or not updated_question['category']:
            updated_question['category'] = category
        if 'difficulty' not in updated_question or not updated_question['difficulty']:
            updated_question['difficulty'] = difficulty
        if 'tags' not in updated_question or not updated_question['tags']:
            updated_question['tags'] = tags
        
        updated_questions.append(updated_question)
    
    return updated_questions


def get_next_sequential_id(cursor, category: str, difficulty: str) -> int:
    """
    カテゴリと難易度ごとの次の連番IDを取得
    
    Returns:
        次の連番番号（0から開始）
    """
    import re
    
    # 既存の問題IDを取得（カテゴリと難易度でフィルタ）
    cursor.execute('''
        SELECT id FROM questions 
        WHERE category = ? AND difficulty = ?
        ORDER BY id
    ''', (category, difficulty))
    
    existing_ids = [row[0] for row in cursor.fetchall()]
    
    # 連番パターンに一致するIDを抽出: {category}_{difficulty}_{連番:03d}
    pattern = re.compile(rf'^{re.escape(category)}_{re.escape(difficulty)}_(\d{{3}})$')
    max_index = -1
    
    for question_id in existing_ids:
        match = pattern.match(question_id)
        if match:
            index = int(match.group(1))
            max_index = max(max_index, index)
    
    # 次の連番を返す
    return max_index + 1


def generate_sequential_id(category: str, difficulty: str, index: int) -> str:
    """カテゴリと難易度ごとの連番IDを生成"""
    return f"{category}_{difficulty}_{index:03d}"


def insert_questions_to_db(questions: list, db_path: str, replace: bool = True, is_manual: bool = False):
    """問題をデータベースに挿入（カテゴリ・難易度ごとに連番IDを自動生成）"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # カテゴリ・難易度ごとに問題をグループ化
    from collections import defaultdict
    questions_by_category_difficulty = defaultdict(list)
    
    for question in questions:
        category = question.get('category')
        difficulty = question.get('difficulty')
        if not category or not difficulty:
            print(f"警告: 問題 {question.get('id', 'unknown')} にcategoryまたはdifficultyがありません。スキップします。")
            continue
        questions_by_category_difficulty[(category, difficulty)].append(question)
    
    inserted_count = 0
    skipped_count = 0
    manual_count = 0
    updated_count = 0
    
    # カテゴリ・難易度ごとに処理
    for (category, difficulty), category_questions in questions_by_category_difficulty.items():
        # このカテゴリ・難易度の次の連番を取得
        next_index = get_next_sequential_id(cursor, category, difficulty)
        
        print(f"\n【{category}/{difficulty}】")
        print(f"  既存の問題数: {next_index}問")
        print(f"  追加する問題数: {len(category_questions)}問")
        
        for i, question in enumerate(category_questions):
            # 手動作成の問題かチェック
            original_id = question.get('id', '')
            if is_manual or original_id.startswith('manual_'):
                manual_count += 1
            
            # 新しい連番IDを生成
            new_id = generate_sequential_id(category, difficulty, next_index + i)
            
            # 必須フィールドの確認
            required_fields = ['text', 'options', 'answerIndex', 'explanation', 'category', 'difficulty', 'tags']
            if not all(field in question for field in required_fields):
                print(f"警告: 問題 {original_id} に必須フィールドが不足しています。スキップします。")
                skipped_count += 1
                continue
            
            # 選択肢を文字列に変換（|||で区切る）
            options_str = '|||'.join(question['options'])
            
            # 既存のIDがあるかチェック
            cursor.execute('SELECT id FROM questions WHERE id = ?', (new_id,))
            existing = cursor.fetchone()
            
            if existing:
                if replace:
                    # 既存のレコードを置き換え
                    cursor.execute('''
                        UPDATE questions 
                        SET text = ?, options = ?, answerIndex = ?, explanation = ?, 
                            trivia = ?, category = ?, difficulty = ?, tags = ?, reference_date = ?
                        WHERE id = ?
                    ''', (
                        question['text'],
                        options_str,
                        question['answerIndex'],
                        question['explanation'],
                        question.get('trivia'),
                        question['category'],
                        question['difficulty'],
                        question['tags'],
                        question.get('referenceDate'),
                        new_id
                    ))
                    updated_count += 1
                    if original_id != new_id:
                        print(f"  更新: {original_id} → {new_id}")
                else:
                    skipped_count += 1
                    print(f"  スキップ: {new_id} は既に存在します")
            else:
                # 新しいレコードを挿入
                try:
                    cursor.execute('''
                        INSERT INTO questions 
                        (id, text, options, answerIndex, explanation, trivia, category, difficulty, tags, reference_date)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ''', (
                        new_id,
                        question['text'],
                        options_str,
                        question['answerIndex'],
                        question['explanation'],
                        question.get('trivia'),
                        question['category'],
                        question['difficulty'],
                        question['tags'],
                        question.get('referenceDate')
                    ))
                    inserted_count += 1
                    if original_id != new_id:
                        print(f"  追加: {original_id} → {new_id}")
                except sqlite3.IntegrityError as e:
                    skipped_count += 1
                    print(f"  エラー: {new_id} の挿入に失敗しました: {e}")
    
    conn.commit()
    conn.close()
    
    print(f"\nデータベースに挿入完了: {inserted_count}問")
    if updated_count > 0:
        print(f"更新: {updated_count}問")
    if skipped_count > 0:
        print(f"スキップ: {skipped_count}問")
    if manual_count > 0:
        print(f"手動作成の問題: {manual_count}問")


def cleanup_old_json_files(current_json_file: Path):
    """古いJSONファイルを削除（現在のファイル以外）"""
    try:
        # cleanup_json_files.pyをインポートして実行
        cleanup_script = Path(__file__).parent / "cleanup_json_files.py"
        if cleanup_script.exists():
            import subprocess
            json_path = str(current_json_file.resolve())
            
            # Windowsでのエンコーディング問題を回避
            env = os.environ.copy()
            env['PYTHONIOENCODING'] = 'utf-8'
            
            result = subprocess.run(
                [sys.executable, str(cleanup_script), "--keep-current", json_path, "--delete-root-generated"],
                capture_output=True,
                text=True,
                encoding='utf-8',
                errors='replace',
                env=env
            )
            if result.returncode == 0:
                if result.stdout:
                    print("\n" + result.stdout)
            else:
                error_msg = result.stderr if result.stderr else "不明なエラー"
                print(f"\n警告: ファイル整理中にエラーが発生しました: {error_msg}")
    except Exception as e:
        print(f"\n警告: ファイル整理中にエラーが発生しました: {e}")


def main():
    """メイン処理"""
    import argparse
    
    parser = argparse.ArgumentParser(description='JSONファイルからSQLiteデータベースに問題を変換')
    parser.add_argument('json_file', help='変換するJSONファイルのパス')
    parser.add_argument('--db', default=str(DB_PATH), help='データベースファイルのパス（デフォルト: data/questions.db）')
    parser.add_argument('--replace', action='store_true', help='既存の問題を置き換える')
    parser.add_argument('--create-schema', action='store_true', help='データベーススキーマを作成')
    parser.add_argument('--cleanup', action='store_true', default=True, help='登録後に古いJSONファイルを削除（デフォルト: True）')
    parser.add_argument('--manual', action='store_true', help='手動作成の問題であることを示す（IDがmanual_で始まることを期待）')
    parser.add_argument('--category', choices=['rules', 'history', 'teams'], 
                       help='カテゴリ（JSONに含まれていない場合に使用）')
    parser.add_argument('--difficulty', choices=['easy', 'normal', 'hard', 'extreme'],
                       help='難易度（JSONに含まれていない場合に使用）')
    parser.add_argument('--tags', help='タグ（カンマ区切り、JSONに含まれていない場合に使用。指定がない場合はカテゴリから推測）')
    
    args = parser.parse_args()
    
    # データベースディレクトリを作成
    os.makedirs(os.path.dirname(args.db), exist_ok=True)
    
    # スキーマ作成
    if args.create_schema or not os.path.exists(args.db):
        create_database_schema(args.db)
    
    # JSONファイルから問題を読み込み
    json_file_path = Path(args.json_file)
    if not json_file_path.exists():
        print(f"エラー: JSONファイルが見つかりません: {args.json_file}")
        sys.exit(1)
    
    questions = load_questions_from_json(str(json_file_path))
    
    # 不足しているメタデータ（id, category, difficulty, tags）を追加
    try:
        questions = add_missing_metadata(
            questions,
            category=args.category,
            difficulty=args.difficulty,
            tags=args.tags,
            json_filename=json_file_path.name
        )
        print(f"\nメタデータを追加しました:")
        if args.category:
            print(f"  category: {args.category}")
        if args.difficulty:
            print(f"  difficulty: {args.difficulty}")
        if args.tags:
            print(f"  tags: {args.tags}")
    except ValueError as e:
        print(f"\nエラー: {e}")
        sys.exit(1)
    
    # 手動作成の問題の統計情報を表示
    if args.manual:
        manual_questions = [q for q in questions if q.get('id', '').startswith('manual_')]
        auto_questions = [q for q in questions if not q.get('id', '').startswith('manual_')]
        print(f"\n【問題の内訳】")
        print(f"  手動作成: {len(manual_questions)}問")
        if auto_questions:
            print(f"  自動生成: {len(auto_questions)}問")
            print(f"  警告: 手動作成フラグが指定されていますが、自動生成の問題が含まれています")
    
    # データベースに挿入
    insert_questions_to_db(questions, args.db, replace=args.replace, is_manual=args.manual)
    
    # 古いJSONファイルを削除
    if args.cleanup:
        cleanup_old_json_files(json_file_path)
    
    print("\n変換完了！")


if __name__ == "__main__":
    main()
