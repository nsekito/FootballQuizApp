"""手動で問題を作成するスクリプト"""
import json
import sys
from datetime import datetime
from pathlib import Path

# カテゴリと難易度の定義
CATEGORIES = {
    '1': ('rules', 'ルールクイズ'),
    '2': ('history', '歴史クイズ'),
    '3': ('teams', 'チームクイズ'),
}

DIFFICULTIES = {
    '1': ('easy', 'EASY'),
    '2': ('normal', 'NORMAL'),
    '3': ('hard', 'HARD'),
    '4': ('extreme', 'EXTREME'),
}

# 出力ディレクトリ
OUTPUT_DIR = Path(__file__).parent / "generated"


def generate_manual_id(category: str, difficulty: str, index: int = 1) -> str:
    """手動作成用の問題IDを生成"""
    date_str = datetime.now().strftime('%Y%m%d')
    return f"manual_{category}_{difficulty}_{date_str}_{index:03d}"


def validate_question(question: dict) -> list:
    """問題のバリデーション"""
    errors = []
    
    # 必須フィールドのチェック
    required_fields = ['id', 'text', 'options', 'answerIndex', 'explanation', 'category', 'difficulty', 'tags']
    for field in required_fields:
        if field not in question or not question[field]:
            errors.append(f"必須フィールド '{field}' が不足しています")
    
    # 選択肢のチェック
    if 'options' in question:
        if not isinstance(question['options'], list):
            errors.append("'options' はリストである必要があります")
        elif len(question['options']) != 4:
            errors.append("選択肢は4つである必要があります（現在: {}個）".format(len(question['options'])))
    
    # answerIndexのチェック
    if 'answerIndex' in question:
        try:
            answer_index = int(question['answerIndex'])
            if not (0 <= answer_index <= 3):
                errors.append("answerIndexは0-3の範囲内である必要があります（現在: {}）".format(answer_index))
        except (ValueError, TypeError):
            errors.append("answerIndexは整数である必要があります")
    
    # カテゴリのチェック
    valid_categories = ['rules', 'history', 'teams']
    if 'category' in question and question['category'] not in valid_categories:
        errors.append("categoryは 'rules', 'history', 'teams' のいずれかである必要があります")
    
    # 難易度のチェック
    valid_difficulties = ['easy', 'normal', 'hard', 'extreme']
    if 'difficulty' in question and question['difficulty'] not in valid_difficulties:
        errors.append("difficultyは 'easy', 'normal', 'hard', 'extreme' のいずれかである必要があります")
    
    return errors


def input_with_prompt(prompt: str, default: str = "", required: bool = True) -> str:
    """プロンプトを表示して入力を受け取る"""
    if default:
        full_prompt = f"{prompt} (デフォルト: {default}): "
    else:
        full_prompt = f"{prompt}: "
    
    while True:
        value = input(full_prompt).strip()
        if value:
            return value
        elif default:
            return default
        elif not required:
            return ""
        else:
            print("この項目は必須です。入力してください。")


def input_multiline(prompt: str, required: bool = True) -> str:
    """複数行の入力を受け取る"""
    print(f"{prompt} (複数行入力可、空行で終了):")
    lines = []
    while True:
        line = input()
        if not line and lines:
            break
        if line:
            lines.append(line)
        elif not lines and required:
            print("この項目は必須です。少なくとも1行入力してください。")
            continue
        elif not lines:
            break
    
    return "\n".join(lines)


def create_question_interactive() -> dict:
    """対話的に問題を作成"""
    print("\n" + "=" * 60)
    print("手動問題作成ツール")
    print("=" * 60)
    
    # カテゴリ選択
    print("\n【カテゴリ選択】")
    for key, (value, label) in CATEGORIES.items():
        print(f"  {key}: {label}")
    category_choice = input_with_prompt("カテゴリを選択", required=True)
    if category_choice not in CATEGORIES:
        print(f"エラー: 無効な選択です。デフォルトで 'rules' を使用します。")
        category = 'rules'
    else:
        category, _ = CATEGORIES[category_choice]
    
    # 難易度選択
    print("\n【難易度選択】")
    for key, (value, label) in DIFFICULTIES.items():
        print(f"  {key}: {label}")
    difficulty_choice = input_with_prompt("難易度を選択", required=True)
    if difficulty_choice not in DIFFICULTIES:
        print(f"エラー: 無効な選択です。デフォルトで 'easy' を使用します。")
        difficulty = 'easy'
    else:
        difficulty, _ = DIFFICULTIES[difficulty_choice]
    
    # 問題ID生成
    question_id = generate_manual_id(category, difficulty)
    print(f"\n生成された問題ID: {question_id}")
    
    # 問題文
    print("\n【問題文】")
    text = input_multiline("問題文を入力", required=True)
    
    # 選択肢
    print("\n【選択肢】")
    options = []
    for i in range(4):
        option = input_with_prompt(f"選択肢{i+1}", required=True)
        options.append(option)
    
    # 正解の選択肢
    print("\n【正解の選択肢】")
    print("  1: 選択肢1")
    print("  2: 選択肢2")
    print("  3: 選択肢3")
    print("  4: 選択肢4")
    answer_choice = input_with_prompt("正解の選択肢番号", required=True)
    try:
        answer_index = int(answer_choice) - 1
        if not (0 <= answer_index <= 3):
            raise ValueError()
    except (ValueError, TypeError):
        print(f"エラー: 無効な選択です。デフォルトで 0 を使用します。")
        answer_index = 0
    
    # 解説
    print("\n【解説】")
    explanation = input_multiline("解説を入力", required=True)
    
    # 豆知識（オプション）
    print("\n【豆知識】（オプション、Enterキーでスキップ）")
    trivia = input_multiline("豆知識を入力", required=False)
    
    # タグ
    print("\n【タグ】")
    default_tags = category
    if category == 'history' or category == 'teams':
        default_tags = f"{category},japan"
    tags = input_with_prompt("タグ（カンマ区切り）", default=default_tags, required=True)
    
    # 対象年月（オプション）
    print("\n【対象年月】（オプション、Enterキーでスキップ）")
    reference_date = input_with_prompt("対象年月（YYYYまたはYYYY-MM形式）", required=False)
    
    # 問題オブジェクトを作成
    question = {
        'id': question_id,
        'text': text,
        'options': options,
        'answerIndex': answer_index,
        'explanation': explanation,
        'category': category,
        'difficulty': difficulty,
        'tags': tags,
    }
    
    if trivia:
        question['trivia'] = trivia
    
    if reference_date:
        question['referenceDate'] = reference_date
    
    return question


def save_questions_to_json(questions: list, output_dir: Path = None):
    """問題をJSONファイルに保存"""
    if output_dir is None:
        output_dir = OUTPUT_DIR
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    filename = f"manual_questions_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    filepath = output_dir / filename
    
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(questions, f, ensure_ascii=False, indent=2)
    
    print(f"\n保存完了: {filepath}")
    return str(filepath)


def main():
    """メイン処理"""
    import argparse
    
    parser = argparse.ArgumentParser(description='手動で問題を作成するスクリプト')
    parser.add_argument('--count', type=int, default=1, help='作成する問題数（デフォルト: 1）')
    parser.add_argument('--output', type=str, help='出力ファイルパス（指定しない場合は自動生成）')
    
    args = parser.parse_args()
    
    questions = []
    
    for i in range(args.count):
        print(f"\n{'='*60}")
        print(f"問題 {i+1}/{args.count}")
        print(f"{'='*60}")
        
        try:
            question = create_question_interactive()
            
            # バリデーション
            errors = validate_question(question)
            if errors:
                print("\n【エラー】問題に以下のエラーがあります:")
                for error in errors:
                    print(f"  - {error}")
                retry = input("\n修正しますか？ (y/n): ").strip().lower()
                if retry == 'y':
                    i -= 1  # やり直し
                    continue
                else:
                    print("問題をスキップします。")
                    continue
            
            questions.append(question)
            print("\n✓ 問題が作成されました")
            
        except KeyboardInterrupt:
            print("\n\n中断されました。")
            if questions:
                save = input(f"作成済みの{len(questions)}問を保存しますか？ (y/n): ").strip().lower()
                if save == 'y':
                    save_questions_to_json(questions)
            sys.exit(0)
        except Exception as e:
            print(f"\nエラーが発生しました: {e}")
            continue
    
    if questions:
        # JSONファイルに保存
        if args.output:
            filepath = Path(args.output)
            filepath.parent.mkdir(parents=True, exist_ok=True)
            with open(filepath, 'w', encoding='utf-8') as f:
                json.dump(questions, f, ensure_ascii=False, indent=2)
            print(f"\n保存完了: {filepath}")
        else:
            filepath = save_questions_to_json(questions)
        
        print(f"\n{'='*60}")
        print(f"完了: {len(questions)}問を作成しました")
        print(f"{'='*60}")
        print(f"\nデータベースに登録するには:")
        print(f"  python json_to_db.py {filepath} --replace")
    else:
        print("\n問題が作成されませんでした。")


if __name__ == "__main__":
    main()
