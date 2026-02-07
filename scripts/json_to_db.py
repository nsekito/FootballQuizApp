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
            reference_date TEXT,
            quiz_type TEXT,
            category_id TEXT,
            region TEXT,
            league TEXT,
            team TEXT,
            team_id TEXT,
            weekly_meta TEXT
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


def parse_filename_for_new_schema(filename: str) -> dict:
    """
    新しいスキーマのファイル名からquizTypeとdifficultyを解析
    
    ファイル名のパターン: {quizType}_{difficulty}_{YYYYMMDD}.json
    例: team_easy_20260207.json
    
    Returns:
        {'quizType': 'team', 'difficulty': 'easy'} または {}
    """
    import re
    
    # ファイル名から拡張子を除去
    base_name = Path(filename).stem
    
    # パターン: {quizType}_{difficulty}_{YYYYMMDD}
    pattern = r'^([a-z]+)_([a-z]+)_\d{8}$'
    match = re.match(pattern, base_name)
    if match:
        quiz_type = match.group(1)
        difficulty = match.group(2)
        # 有効なquizTypeとdifficultyかチェック
        valid_quiz_types = ['team', 'history', 'rule', 'weekly']
        valid_difficulties = ['easy', 'normal', 'hard']
        if quiz_type in valid_quiz_types and difficulty in valid_difficulties:
            return {'quizType': quiz_type, 'difficulty': difficulty}
    
    return {}


def infer_metadata_from_filename(filename: str) -> dict:
    """
    ファイル名からcategory, difficulty, tagsを推測（旧スキーマ用）
    
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


def is_new_schema_format(question: dict) -> bool:
    """新しいスキーマ形式かどうかを判定（quizTypeフィールドの有無で判定）"""
    return 'quizType' in question and question['quizType'] is not None


def convert_new_schema_to_db_format(question: dict) -> dict:
    """
    新しいスキーマ形式の問題をDB形式に変換
    
    - quizType → category の変換（team→teams, rule→rules, history→history, weekly→match_recap）
    - tags配列 → カンマ区切り文字列
    - weeklyMetaオブジェクト → JSON文字列
    """
    converted = question.copy()
    
    # quizType → category の変換
    quiz_type = question.get('quizType', '')
    category_map = {
        'team': 'teams',
        'rule': 'rules',
        'history': 'history',
        'weekly': 'match_recap'
    }
    if quiz_type in category_map:
        converted['category'] = category_map[quiz_type]
    
    # tags配列 → カンマ区切り文字列
    if 'tags' in question and isinstance(question['tags'], list):
        converted['tags'] = ','.join(question['tags'])
    
    # weeklyMetaオブジェクト → JSON文字列
    if 'weeklyMeta' in question and isinstance(question['weeklyMeta'], dict):
        converted['weeklyMeta'] = json.dumps(question['weeklyMeta'], ensure_ascii=False)
    
    return converted


def insert_questions_to_db(questions: list, db_path: str, replace: bool = True):
    """問題をデータベースに挿入（新しいスキーマ形式のみ対応）"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    inserted_count = 0
    skipped_count = 0
    updated_count = 0
    
    print("新しいスキーマ形式として処理します")
    # 新しいスキーマの場合はIDをそのまま使用
    for question in questions:
        if not is_new_schema_format(question):
            print(f"警告: 問題 {question.get('id', 'unknown')} が新しいスキーマ形式ではありません。スキップします。")
            skipped_count += 1
            continue
            
            # 新しいスキーマ形式に変換
            converted_question = convert_new_schema_to_db_format(question)
            
            original_id = converted_question.get('id', '')
            if not original_id:
                print(f"警告: 問題にIDがありません。スキップします。")
                skipped_count += 1
                continue
            
            # 必須フィールドの確認
            required_fields = ['text', 'options', 'answerIndex', 'explanation', 'category', 'difficulty', 'tags', 'quizType']
            if not all(field in converted_question for field in required_fields):
                print(f"警告: 問題 {original_id} に必須フィールドが不足しています。スキップします。")
                skipped_count += 1
                continue
            
            # 選択肢を文字列に変換（|||で区切る）
            options_str = '|||'.join(converted_question['options'])
            
            # tagsが配列の場合は文字列に変換
            tags_str = converted_question['tags']
            if isinstance(tags_str, list):
                tags_str = ','.join(tags_str)
            
            # 既存のIDがあるかチェック
            cursor.execute('SELECT id FROM questions WHERE id = ?', (original_id,))
            existing = cursor.fetchone()
            
            if existing:
                if replace:
                    # 既存のレコードを置き換え
                    cursor.execute('''
                        UPDATE questions 
                        SET text = ?, options = ?, answerIndex = ?, explanation = ?, 
                            trivia = ?, category = ?, difficulty = ?, tags = ?, reference_date = ?,
                            quiz_type = ?, category_id = ?, region = ?, league = ?, team = ?, team_id = ?, weekly_meta = ?
                        WHERE id = ?
                    ''', (
                        converted_question['text'],
                        options_str,
                        converted_question['answerIndex'],
                        converted_question['explanation'],
                        converted_question.get('trivia'),
                        converted_question['category'],
                        converted_question['difficulty'],
                        tags_str,
                        converted_question.get('referenceDate'),
                        converted_question.get('quizType'),
                        converted_question.get('categoryId'),
                        converted_question.get('region'),
                        converted_question.get('league'),
                        converted_question.get('team'),
                        converted_question.get('teamId'),
                        converted_question.get('weeklyMeta'),
                        original_id
                    ))
                    updated_count += 1
                    print(f"  更新: {original_id}")
                else:
                    skipped_count += 1
                    print(f"  スキップ: {original_id} は既に存在します")
            else:
                # 新しいレコードを挿入
                try:
                    cursor.execute('''
                        INSERT INTO questions 
                        (id, text, options, answerIndex, explanation, trivia, category, difficulty, tags, reference_date,
                         quiz_type, category_id, region, league, team, team_id, weekly_meta)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ''', (
                        original_id,
                        converted_question['text'],
                        options_str,
                        converted_question['answerIndex'],
                        converted_question['explanation'],
                        converted_question.get('trivia'),
                        converted_question['category'],
                        converted_question['difficulty'],
                        tags_str,
                        converted_question.get('referenceDate'),
                        converted_question.get('quizType'),
                        converted_question.get('categoryId'),
                        converted_question.get('region'),
                        converted_question.get('league'),
                        converted_question.get('team'),
                        converted_question.get('teamId'),
                        converted_question.get('weeklyMeta')
                    ))
                    inserted_count += 1
                    print(f"  追加: {original_id}")
                except sqlite3.IntegrityError as e:
                    skipped_count += 1
                    print(f"  エラー: {original_id} の挿入に失敗しました: {e}")
    
    conn.commit()
    conn.close()
    
    print(f"\nデータベースに挿入完了: {inserted_count}問")
    if updated_count > 0:
        print(f"更新: {updated_count}問")
    if skipped_count > 0:
        print(f"スキップ: {skipped_count}問")


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
    
    # 新しいスキーマ形式を検証
    is_new_schema = any(is_new_schema_format(q) for q in questions)
    
    if not is_new_schema:
        print("エラー: 新しいスキーマ形式（quizTypeフィールドを含む）のJSONファイルが必要です")
        sys.exit(1)
    
    print("新しいスキーマ形式を検出しました")
    # ファイル名からquizTypeとdifficultyを解析
    filename_info = parse_filename_for_new_schema(json_file_path.name)
    if filename_info:
        file_quiz_type = filename_info.get('quizType')
        file_difficulty = filename_info.get('difficulty')
        print(f"ファイル名から検出: quizType={file_quiz_type}, difficulty={file_difficulty}")
        
        # JSON内の値と一致するか確認
        for question in questions:
            json_quiz_type = question.get('quizType')
            json_difficulty = question.get('difficulty')
            
            if json_quiz_type and json_quiz_type != file_quiz_type:
                print(f"警告: 問題 {question.get('id', 'unknown')} のquizType ({json_quiz_type}) がファイル名 ({file_quiz_type}) と一致しません")
            
            if json_difficulty and json_difficulty != file_difficulty:
                print(f"警告: 問題 {question.get('id', 'unknown')} のdifficulty ({json_difficulty}) がファイル名 ({file_difficulty}) と一致しません")
    else:
        print("警告: ファイル名からquizTypeとdifficultyを検出できませんでした")
    
    # データベースに挿入
    insert_questions_to_db(questions, args.db, replace=args.replace)
    
    # 古いJSONファイルを削除
    if args.cleanup:
        cleanup_old_json_files(json_file_path)
    
    print("\n変換完了！")


if __name__ == "__main__":
    main()
