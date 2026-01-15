"""常設クイズ問題生成スクリプト"""
import json
import os
import sys
from datetime import datetime
from pathlib import Path

# scripts/ディレクトリをパスに追加
scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

# 出力ディレクトリをscripts/generatedに設定
OUTPUT_DIR = scripts_dir / "generated"

from utils.gemini_client import generate_questions_batch
from utils.question_validator import validate_questions

# カテゴリと難易度の定義
CATEGORIES = {
    'rules': 'ルールクイズ',
    'history': '歴史クイズ',
    'teams': 'チームクイズ',
}

DIFFICULTIES = {
    'easy': 'EASY',
    'normal': 'NORMAL',
    'hard': 'HARD',
    'extreme': 'EXTREME',
}

# 生成パラメータ
GENERATION_CONFIG = {
    'rules': {
        'easy': {'count': 50, 'tags': 'rules'},
        'normal': {'count': 50, 'tags': 'rules'},
        'hard': {'count': 50, 'tags': 'rules'},
        'extreme': {'count': 50, 'tags': 'rules'},
    },
    'history': {
        'easy': {'count': 50, 'tags': 'history,japan'},
        'normal': {'count': 50, 'tags': 'history,japan'},
        'hard': {'count': 50, 'tags': 'history,japan'},
        'extreme': {'count': 50, 'tags': 'history,japan'},
    },
    'teams': {
        'easy': {'count': 50, 'tags': 'teams,japan'},
        'normal': {'count': 50, 'tags': 'teams,japan'},
        'hard': {'count': 50, 'tags': 'teams,japan'},
        'extreme': {'count': 50, 'tags': 'teams,japan'},
    },
}


def generate_id(category: str, difficulty: str, index: int) -> str:
    """問題IDを生成"""
    return f"{category}_{difficulty}_{index:03d}"


def save_questions_to_json(questions: list, category: str, difficulty: str, output_dir: Path = None):
    """問題をJSONファイルに保存"""
    if output_dir is None:
        output_dir = OUTPUT_DIR
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    filename = f"{category}_{difficulty}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    filepath = output_dir / filename
    
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(questions, f, ensure_ascii=False, indent=2)
    
    print(f"保存完了: {filepath}")
    return str(filepath)


def main():
    """メイン処理"""
    import argparse
    
    parser = argparse.ArgumentParser(description='常設クイズ問題生成スクリプト')
    parser.add_argument('--category', choices=['rules', 'history', 'teams'], 
                       help='生成するカテゴリ（指定しない場合はすべて）')
    parser.add_argument('--difficulty', choices=['easy', 'normal', 'hard', 'extreme'],
                       help='生成する難易度（指定しない場合はすべて）')
    parser.add_argument('--count', type=int, 
                       help='各難易度あたりの生成数（デフォルト: 設定ファイルの値）')
    parser.add_argument('--test', action='store_true',
                       help='テストモード（各難易度5問のみ生成）')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("常設クイズ問題生成スクリプト")
    print("=" * 60)
    
    # テストモードの場合は生成数を5問に制限
    if args.test:
        print("\n【テストモード】各難易度5問のみ生成します")
        test_count = 5
    else:
        test_count = None
    
    all_questions = []
    
    # カテゴリのフィルタリング
    categories_to_process = [args.category] if args.category else list(CATEGORIES.keys())
    
    # 各カテゴリ・難易度ごとに問題を生成
    for category in categories_to_process:
        category_name = CATEGORIES[category]
        print(f"\n【{category_name}】")
        print("-" * 60)
        
        # 難易度のフィルタリング
        difficulties_to_process = [args.difficulty] if args.difficulty else list(DIFFICULTIES.keys())
        
        for difficulty in difficulties_to_process:
            difficulty_name = DIFFICULTIES[difficulty]
            config = GENERATION_CONFIG[category][difficulty]
            count = test_count if test_count else (args.count if args.count else config['count'])
            tags = config['tags']
            
            print(f"\n難易度: {difficulty_name} ({count}問)")
            
            # 問題を生成
            questions = generate_questions_batch(
                category=category,
                difficulty=difficulty,
                count=count,
                tags=tags
            )
            
            # IDを追加
            for i, question in enumerate(questions):
                question['id'] = generate_id(category, difficulty, i)
                question['category'] = category
                question['difficulty'] = difficulty
                question['tags'] = tags
            
            # 検証
            validation_result = validate_questions(questions)
            print(f"検証結果: 有効 {validation_result['valid']}/{validation_result['total']}問")
            
            if validation_result['invalid'] > 0:
                print("警告: 無効な問題があります")
                for error_info in validation_result['errors']:
                    print(f"  問題 {error_info['index']}: {error_info['errors']}")
            
            # JSONファイルに保存
            save_questions_to_json(questions, category, difficulty)
            
            # 全体のリストに追加
            all_questions.extend(questions)
    
    # すべての問題を1つのファイルに保存
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    all_questions_file = OUTPUT_DIR / f"all_questions_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(all_questions_file, 'w', encoding='utf-8') as f:
        json.dump(all_questions, f, ensure_ascii=False, indent=2)
    
    print("\n" + "=" * 60)
    print(f"生成完了: 合計 {len(all_questions)}問")
    if all_questions:
        print(f"統合ファイル: {all_questions_file}")
        print(f"\n次のステップ:")
        print(f"  python json_to_db.py \"{all_questions_file}\" --create-schema")
    print("=" * 60)


if __name__ == "__main__":
    main()
