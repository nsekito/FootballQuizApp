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
            tags TEXT NOT NULL
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


def insert_questions_to_db(questions: list, db_path: str, replace: bool = True):
    """問題をデータベースに挿入"""
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    inserted_count = 0
    skipped_count = 0
    
    for question in questions:
        # 必須フィールドの確認
        required_fields = ['id', 'text', 'options', 'answerIndex', 'explanation', 'category', 'difficulty', 'tags']
        if not all(field in question for field in required_fields):
            print(f"警告: 問題 {question.get('id', 'unknown')} に必須フィールドが不足しています。スキップします。")
            skipped_count += 1
            continue
        
        # 選択肢を文字列に変換（|||で区切る）
        options_str = '|||'.join(question['options'])
        
        try:
            cursor.execute('''
                INSERT INTO questions 
                (id, text, options, answerIndex, explanation, trivia, category, difficulty, tags)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                question['id'],
                question['text'],
                options_str,
                question['answerIndex'],
                question['explanation'],
                question.get('trivia'),
                question['category'],
                question['difficulty'],
                question['tags']
            ))
            inserted_count += 1
        except sqlite3.IntegrityError:
            if replace:
                # 既存のレコードを置き換え
                cursor.execute('''
                    UPDATE questions 
                    SET text = ?, options = ?, answerIndex = ?, explanation = ?, 
                        trivia = ?, category = ?, difficulty = ?, tags = ?
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
                    question['id']
                ))
                inserted_count += 1
            else:
                skipped_count += 1
                print(f"スキップ: 問題 {question['id']} は既に存在します")
    
    conn.commit()
    conn.close()
    
    print(f"データベースに挿入完了: {inserted_count}問")
    if skipped_count > 0:
        print(f"スキップ: {skipped_count}問")


def main():
    """メイン処理"""
    import argparse
    
    parser = argparse.ArgumentParser(description='JSONファイルからSQLiteデータベースに問題を変換')
    parser.add_argument('json_file', help='変換するJSONファイルのパス')
    parser.add_argument('--db', default=str(DB_PATH), help='データベースファイルのパス（デフォルト: data/questions.db）')
    parser.add_argument('--replace', action='store_true', help='既存の問題を置き換える')
    parser.add_argument('--create-schema', action='store_true', help='データベーススキーマを作成')
    
    args = parser.parse_args()
    
    # データベースディレクトリを作成
    os.makedirs(os.path.dirname(args.db), exist_ok=True)
    
    # スキーマ作成
    if args.create_schema or not os.path.exists(args.db):
        create_database_schema(args.db)
    
    # JSONファイルから問題を読み込み
    if not os.path.exists(args.json_file):
        print(f"エラー: JSONファイルが見つかりません: {args.json_file}")
        sys.exit(1)
    
    questions = load_questions_from_json(args.json_file)
    
    # データベースに挿入
    insert_questions_to_db(questions, args.db, replace=args.replace)
    
    print("\n変換完了！")


if __name__ == "__main__":
    main()
