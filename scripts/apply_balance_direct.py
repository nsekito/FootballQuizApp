"""直接JSONファイルを修正するスクリプト"""
import json
import random
from pathlib import Path

def balance_answer_indices(questions: list) -> list:
    """問題リストのanswerIndexを均等に分散させる"""
    if not questions:
        return questions
    
    total = len(questions)
    target_per_index = total // 4
    remainder = total % 4
    
    targets = [target_per_index] * 4
    for i in range(remainder):
        targets[i] += 1
    
    current_counts = [0, 0, 0, 0]
    for q in questions:
        idx = q.get('answerIndex', 0)
        if 0 <= idx <= 3:
            current_counts[idx] += 1
    
    print(f"現在の分布: [0]: {current_counts[0]}, [1]: {current_counts[1]}, [2]: {current_counts[2]}, [3]: {current_counts[3]}")
    print(f"目標分布: [0]: {targets[0]}, [1]: {targets[1]}, [2]: {targets[2]}, [3]: {targets[3]}")
    
    balanced_questions = []
    new_counts = [0, 0, 0, 0]
    
    for question in questions:
        original_index = question.get('answerIndex', 0)
        if not (0 <= original_index <= 3):
            original_index = 0
        
        best_index = 0
        min_ratio = float('inf')
        for idx in range(4):
            if new_counts[idx] < targets[idx]:
                ratio = new_counts[idx] / targets[idx] if targets[idx] > 0 else 0
                if ratio < min_ratio:
                    min_ratio = ratio
                    best_index = idx
        
        options = question.get('options', [])
        if len(options) == 4:
            correct_answer = options[original_index]
            other_options = [opt for i, opt in enumerate(options) if i != original_index]
            random.shuffle(other_options)
            new_options = other_options[:best_index] + [correct_answer] + other_options[best_index:]
            
            balanced_question = question.copy()
            balanced_question['options'] = new_options
            balanced_question['answerIndex'] = best_index
            balanced_questions.append(balanced_question)
            new_counts[best_index] += 1
        else:
            balanced_questions.append(question)
            if 0 <= original_index <= 3:
                new_counts[original_index] += 1
    
    print(f"均等化後の分布: [0]: {new_counts[0]}, [1]: {new_counts[1]}, [2]: {new_counts[2]}, [3]: {new_counts[3]}")
    return balanced_questions

# 処理対象のファイル
generated_dir = Path(__file__).parent / "generated"
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
    
    # 読み込み
    with open(filepath, 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    print(f"問題数: {len(questions)}問")
    
    # バックアップ
    backup_path = filepath.with_suffix('.json.bak')
    with open(backup_path, 'w', encoding='utf-8') as f:
        json.dump(questions, f, ensure_ascii=False, indent=2)
    print(f"バックアップ作成: {backup_path.name}")
    
    # 均等化
    balanced_questions = balance_answer_indices(questions)
    
    # 保存
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(balanced_questions, f, ensure_ascii=False, indent=2)
    
    print(f"✓ 完了: {filename}")

print(f"\n{'='*60}")
print("すべてのファイルの処理が完了しました！")
print(f"{'='*60}")
