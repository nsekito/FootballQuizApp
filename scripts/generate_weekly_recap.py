"""Weekly Recap問題生成スクリプト（Gemini Grounding使用）"""
import json
import sys
from datetime import datetime, timedelta
from pathlib import Path

# scripts/ディレクトリをパスに追加
scripts_dir = Path(__file__).parent
sys.path.insert(0, str(scripts_dir))

from utils.gemini_client import generate_weekly_recap_questions_by_category, balance_answer_indices
from config import WEEKLY_RECAP_OUTPUT_DIR

# プロジェクトルートを取得（scripts/から見て../）
PROJECT_ROOT = Path(__file__).parent.parent


def get_monday_date() -> str:
    """最新の月曜日の日付をYYYY-MM-DD形式で取得
    
    月曜日が今日の場合、今日の日付を返す
    それ以外の場合、直近の月曜日の日付を返す
    """
    today = datetime.now()
    # weekday(): 月曜日=0, 火曜日=1, ..., 日曜日=6
    days_from_monday = today.weekday()
    monday = today - timedelta(days=days_from_monday)
    return monday.strftime('%Y-%m-%d')


def calculate_weekly_meta_params(date: str) -> dict:
    """weeklyMetaパラメータを計算
    
    Args:
        date: 対象日付（YYYY-MM-DD形式）
    
    Returns:
        weeklyMetaパラメータの辞書
    """
    date_obj = datetime.strptime(date, '%Y-%m-%d')
    
    # publishDate: 月曜日の日付（dateが月曜日と仮定）
    publish_date = date
    
    # expiryDate: publishDate + 7日
    expiry_date_obj = date_obj + timedelta(days=7)
    expiry_date = expiry_date_obj.strftime('%Y-%m-%d')
    
    # season: YYYY-YY形式（例: 2025-26）
    # 8月開始のシーズンを想定（8月〜7月が1シーズン）
    year = date_obj.year
    month = date_obj.month
    
    # 8月以降は同じシーズン、1-7月は前年から始まるシーズン
    if month >= 8:
        # 8月〜12月: YYYY-YY形式（例: 2025年8月 → 2025-26）
        season = f"{year}-{str(year + 1)[-2:]}"
    else:
        # 1月〜7月: YYYY-YY形式（例: 2026年2月 → 2025-26）
        season = f"{year - 1}-{str(year)[-2:]}"
    
    # matchweek: 現時点では計算ロジックが不明のため、Noneとする
    # TODO: リーグごとの節数計算ロジックを実装する必要がある
    matchweek = None
    
    return {
        'matchweek': matchweek,
        'publish_date': publish_date,
        'expiry_date': expiry_date,
        'season': season
    }


def save_weekly_recap_json(
    questions: list,
    date: str,
    league_type: str,
    output_dir: Path
) -> Path:
    """Weekly Recap問題をJSONファイルに保存
    
    Args:
        questions: 問題のリスト
        date: 日付（YYYY-MM-DD形式）
        league_type: リーグタイプ（"j1" または "europe"）
        output_dir: 出力ディレクトリ
    
    Returns:
        保存されたファイルのパス
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # ファイル名: {date}_{league_type}.json (例: 2026-01-28_j1.json)
    filename = f"{date}_{league_type}.json"
    filepath = output_dir / filename
    
    # JSON形式に整形
    output_data = {
        "version": "1.0",
        "generated_at": datetime.now().strftime('%Y-%m-%dT%H:%M:%SZ'),
        "category": "match_recap",
        "league_type": league_type,
        "date": date,
        "questions": questions
    }
    
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(output_data, f, ensure_ascii=False, indent=2)
    
    print(f"保存完了: {filepath}")
    return filepath


def main():
    """メイン処理"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Weekly Recap問題生成スクリプト（Gemini Grounding使用）')
    parser.add_argument('--date', type=str,
                       help='対象日付（YYYY-MM-DD形式、指定しない場合は最新の月曜日）')
    parser.add_argument('--output-dir', type=str,
                       help=f'出力ディレクトリ（デフォルト: {WEEKLY_RECAP_OUTPUT_DIR}）')
    parser.add_argument('--j1-only', action='store_true',
                       help='J1リーグのみ生成（テスト用）')
    parser.add_argument('--europe-only', action='store_true',
                       help='ヨーロッパサッカーのみ生成（テスト用）')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("Weekly Recap問題生成スクリプト（Gemini Grounding使用）")
    print("=" * 60)
    
    # 日付の決定
    if args.date:
        target_date = args.date
    else:
        target_date = get_monday_date()
    
    print(f"\n対象日付: {target_date}")
    
    # 出力ディレクトリの決定
    if args.output_dir:
        output_dir = Path(args.output_dir)
    else:
        # 相対パスの場合はプロジェクトルートからの相対パスとして解釈
        if Path(WEEKLY_RECAP_OUTPUT_DIR).is_absolute():
            output_dir = Path(WEEKLY_RECAP_OUTPUT_DIR)
        else:
            output_dir = PROJECT_ROOT / WEEKLY_RECAP_OUTPUT_DIR
    print(f"出力ディレクトリ: {output_dir}")
    
    # weeklyMetaパラメータの計算
    weekly_meta_params = calculate_weekly_meta_params(target_date)
    
    saved_files = []
    
    # J1リーグ問題生成（カテゴリごとに分割生成）
    if not args.europe_only:
        print("\n" + "-" * 60)
        print("J1リーグ問題生成中...")
        print("-" * 60)
        try:
            # カテゴリごとの問題数定義
            j1_categories = [
                ("weekly-jp-match", "試合・結果", 10),
                ("weekly-jp-standings", "順位・スタッツ", 6),
                ("weekly-jp-player", "選手の動向", 5),
                ("weekly-jp-club", "クラブ・リーグの動向", 5),
                ("weekly-jp-buzz", "今週の注目ニュース", 4),
            ]
            
            j1_questions = []
            current_id = 1
            
            for category_id, category_name, question_count in j1_categories:
                print(f"\nカテゴリ: {category_name} ({question_count}問) 生成中...")
                category_questions = generate_weekly_recap_questions_by_category(
                    region="japan",
                    category_id=category_id,
                    category_name=category_name,
                    question_count=question_count,
                    reference_date=target_date,
                    matchweek=weekly_meta_params['matchweek'],
                    publish_date=weekly_meta_params['publish_date'],
                    expiry_date=weekly_meta_params['expiry_date'],
                    season=weekly_meta_params['season'],
                    start_number=current_id
                )
                
                # IDを連番に更新
                for q in category_questions:
                    q['id'] = f"w_{current_id:05d}"
                    current_id += 1
                
                j1_questions.extend(category_questions)
                print(f"  {len(category_questions)}問生成完了")
            
            # answerIndexのバランス調整
            j1_questions = balance_answer_indices(j1_questions)
            
            # 分布を確認して表示
            counts = [0, 0, 0, 0]
            for q in j1_questions:
                idx = q.get('answerIndex', 0)
                if 0 <= idx <= 3:
                    counts[idx] += 1
            print(f"\nanswerIndex分布: [0]: {counts[0]}, [1]: {counts[1]}, [2]: {counts[2]}, [3]: {counts[3]}")
            
            # 難易度分布を確認して表示
            difficulty_counts = {"easy": 0, "normal": 0, "hard": 0}
            for q in j1_questions:
                diff = q.get('difficulty', 'normal')
                if diff in difficulty_counts:
                    difficulty_counts[diff] += 1
            print(f"難易度分布: easy: {difficulty_counts['easy']}, normal: {difficulty_counts['normal']}, hard: {difficulty_counts['hard']}")
            
            # カテゴリ分布を確認して表示
            category_counts = {}
            for q in j1_questions:
                cat_id = q.get('categoryId', 'unknown')
                category_counts[cat_id] = category_counts.get(cat_id, 0) + 1
            print(f"カテゴリ分布: {category_counts}")
            
            # J1リーグの問題を個別のファイルに保存
            if j1_questions:
                filepath = save_weekly_recap_json(j1_questions, target_date, "j1", output_dir)
                saved_files.append(filepath)
                print(f"\nJ1リーグ: {len(j1_questions)}問生成完了")
        except Exception as e:
            print(f"エラー: J1リーグ問題の生成に失敗しました: {e}")
            import traceback
            traceback.print_exc()
            if args.j1_only:
                raise
    
    # ヨーロッパサッカー問題生成（カテゴリごとに分割生成）
    if not args.j1_only:
        print("\n" + "-" * 60)
        print("ヨーロッパサッカー問題生成中...")
        print("-" * 60)
        try:
            # カテゴリごとの問題数定義
            europe_categories = [
                ("weekly-world-match", "試合・結果", 10),
                ("weekly-world-standings", "順位・スタッツ", 6),
                ("weekly-world-japanese", "海外日本人選手", 5),
                ("weekly-world-player", "選手の動向", 5),
                ("weekly-world-buzz", "今週の注目ニュース", 4),
            ]
            
            europe_questions = []
            current_id = 1
            
            for category_id, category_name, question_count in europe_categories:
                print(f"\nカテゴリ: {category_name} ({question_count}問) 生成中...")
                category_questions = generate_weekly_recap_questions_by_category(
                    region="world",
                    category_id=category_id,
                    category_name=category_name,
                    question_count=question_count,
                    reference_date=target_date,
                    matchweek=weekly_meta_params['matchweek'],
                    publish_date=weekly_meta_params['publish_date'],
                    expiry_date=weekly_meta_params['expiry_date'],
                    season=weekly_meta_params['season'],
                    start_number=current_id
                )
                
                # IDを連番に更新
                for q in category_questions:
                    q['id'] = f"w_{current_id:05d}"
                    current_id += 1
                
                europe_questions.extend(category_questions)
                print(f"  {len(category_questions)}問生成完了")
            
            # answerIndexのバランス調整
            europe_questions = balance_answer_indices(europe_questions)
            
            # 分布を確認して表示
            counts = [0, 0, 0, 0]
            for q in europe_questions:
                idx = q.get('answerIndex', 0)
                if 0 <= idx <= 3:
                    counts[idx] += 1
            print(f"\nanswerIndex分布: [0]: {counts[0]}, [1]: {counts[1]}, [2]: {counts[2]}, [3]: {counts[3]}")
            
            # 難易度分布を確認して表示
            difficulty_counts = {"easy": 0, "normal": 0, "hard": 0}
            for q in europe_questions:
                diff = q.get('difficulty', 'normal')
                if diff in difficulty_counts:
                    difficulty_counts[diff] += 1
            print(f"難易度分布: easy: {difficulty_counts['easy']}, normal: {difficulty_counts['normal']}, hard: {difficulty_counts['hard']}")
            
            # カテゴリ分布を確認して表示
            category_counts = {}
            for q in europe_questions:
                cat_id = q.get('categoryId', 'unknown')
                category_counts[cat_id] = category_counts.get(cat_id, 0) + 1
            print(f"カテゴリ分布: {category_counts}")
            
            # ヨーロッパサッカーの問題を個別のファイルに保存
            if europe_questions:
                filepath = save_weekly_recap_json(europe_questions, target_date, "europe", output_dir)
                saved_files.append(filepath)
                print(f"\nヨーロッパサッカー: {len(europe_questions)}問生成完了")
        except Exception as e:
            print(f"エラー: ヨーロッパサッカー問題の生成に失敗しました: {e}")
            import traceback
            traceback.print_exc()
            if args.europe_only:
                raise
    
    # 結果の表示
    print("\n" + "=" * 60)
    print("生成結果")
    print("=" * 60)
    total_count = 0
    if not args.europe_only:
        j1_file = output_dir / f"{target_date}_j1.json"
        if j1_file.exists():
            with open(j1_file, 'r', encoding='utf-8') as f:
                j1_data = json.load(f)
                j1_count = len(j1_data.get('questions', []))
                total_count += j1_count
                print(f"  - J1リーグ: {j1_count}問 ({j1_file.name})")
    if not args.j1_only:
        europe_file = output_dir / f"{target_date}_europe.json"
        if europe_file.exists():
            with open(europe_file, 'r', encoding='utf-8') as f:
                europe_data = json.load(f)
                europe_count = len(europe_data.get('questions', []))
                total_count += europe_count
                print(f"  - ヨーロッパサッカー: {europe_count}問 ({europe_file.name})")
    
    print(f"\n合計: {total_count}問")
    
    if saved_files:
        print(f"\n保存されたファイル:")
        for filepath in saved_files:
            print(f"  - {filepath}")
    else:
        print("\n警告: 生成された問題がありません")
        sys.exit(1)


if __name__ == '__main__':
    main()
