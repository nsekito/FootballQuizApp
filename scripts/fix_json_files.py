"""既存のJSONファイルのanswerIndexを均等化するスクリプト（直接実行版）"""
import json
import random
from pathlib import Path

def balance_answer_indices(questions: list) -> list:
    """
    問題リストのanswerIndexを均等に分散させる
    
    選択肢の順序をシャッフルして、正解のインデックスを均等に分散させます。
    これにより、ユーザーが特定のインデックスに偏って正解を選ぶことを防ぎます。
    
    Args:
        questions: 問題のリスト
    
    Returns:
        answerIndexが均等に分散された問題のリスト
    """
    if not questions:
        return questions
    
    # 各インデックスの目標数を計算
    total = len(questions)
    target_per_index = total // 4
    remainder = total % 4
    
    # 各インデックスの目標数を設定（余りは0,1,2,3に順に分配）
    targets = [target_per_index] * 4
    for i in range(remainder):
        targets[i] += 1
    
    # 現在の分布を確認
    current_counts = [0, 0, 0, 0]
    for q in questions:
        idx = q.get('answerIndex', 0)
        if 0 <= idx <= 3:
            current_counts[idx] += 1
    
    print(f"現在の分布: [0]: {current_counts[0]}, [1]: {current_counts[1]}, [2]: {current_counts[2]}, [3]: {current_counts[3]}")
    print(f"目標分布: [0]: {targets[0]}, [1]: {targets[1]}, [2]: {targets[2]}, [3]: {targets[3]}")
    
    # 各問題について、必要に応じて選択肢をシャッフル
    balanced_questions = []
    new_counts = [0, 0, 0, 0]
    
    for question in questions:
        original_index = question.get('answerIndex', 0)
        if not (0 <= original_index <= 3):
            original_index = 0
        
        # 現在の分布と目標分布を比較して、どのインデックスに割り当てるか決定
        # 最も不足しているインデックスを優先的に使用
        best_index = 0
        min_ratio = float('inf')
        for idx in range(4):
            if new_counts[idx] < targets[idx]:
                # 目標に対する現在の割合を計算
                ratio = new_counts[idx] / targets[idx] if targets[idx] > 0 else 0
                if ratio < min_ratio:
                    min_ratio = ratio
                    best_index = idx
        
        # 選択肢をシャッフルして、正解を指定されたインデックスに移動
        options = question.get('options', [])
        if len(options) == 4:
            # 正解の選択肢を取得
            correct_answer = options[original_index]
            
            # 選択肢をシャッフル（正解は除く）
            other_options = [opt for i, opt in enumerate(options) if i != original_index]
            random.shuffle(other_options)
            
            # 正解を指定されたインデックスに配置
            new_options = other_options[:best_index] + [correct_answer] + other_options[best_index:]
            
            # 問題を更新
            balanced_question = question.copy()
            balanced_question['options'] = new_options
            balanced_question['answerIndex'] = best_index
            balanced_questions.append(balanced_question)
            new_counts[best_index] += 1
        else:
            # 選択肢が4つでない場合はそのまま追加
            balanced_questions.append(question)
            if 0 <= original_index <= 3:
                new_counts[original_index] += 1
    
    print(f"均等化後の分布: [0]: {new_counts[0]}, [1]: {new_counts[1]}, [2]: {new_counts[2]}, [3]: {new_counts[3]}")
    
    return balanced_questions


def main():
    """メイン処理 - すべてのJSONファイルを修正"""
    generated_dir = Path(__file__).parent / "generated"
    
    # 修正対象のファイルリスト
    json_files = [
        "all_questions_20260118_000852.json",
        "rules_easy_20260117_232438.json",
        "rules_extreme_20260118_000852.json",
        "rules_hard_20260117_235106.json",
        "rules_normal_20260117_233547.json",
    ]
    
    for filename in json_files:
        filepath = generated_dir / filename
        if not filepath.exists():
            print(f"スキップ: {filepath} が見つかりません")
            continue
        
        print(f"\n{'='*60}")
        print(f"処理中: {filename}")
        print(f"{'='*60}")
        
        # JSONファイルを読み込む
        print(f"読み込み中...")
        with open(filepath, 'r', encoding='utf-8') as f:
            questions = json.load(f)
        
        print(f"問題数: {len(questions)}問")
        
        # バックアップを作成
        backup_path = filepath.with_suffix('.json.bak')
        print(f"バックアップ作成中: {backup_path.name}")
        with open(backup_path, 'w', encoding='utf-8') as f:
            json.dump(questions, f, ensure_ascii=False, indent=2)
        
        # answerIndexを均等化
        balanced_questions = balance_answer_indices(questions)
        
        # JSONファイルに保存
        print(f"保存中...")
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(balanced_questions, f, ensure_ascii=False, indent=2)
        
        print(f"✓ 完了: {filename}")
    
    print(f"\n{'='*60}")
    print("すべてのファイルの処理が完了しました！")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
