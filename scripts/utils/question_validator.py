"""生成された問題の検証"""
import json


def validate_question(question: dict) -> tuple[bool, list[str]]:
    """
    問題の妥当性を検証する
    
    Args:
        question: 検証する問題の辞書
    
    Returns:
        (is_valid, errors) のタプル
    """
    errors = []
    
    # 必須フィールドのチェック
    required_fields = {
        'text': str,
        'options': list,
        'answerIndex': int,
        'explanation': str,
    }
    
    for field, field_type in required_fields.items():
        if field not in question:
            errors.append(f"必須フィールド '{field}' がありません")
        elif not isinstance(question[field], field_type):
            errors.append(f"'{field}' の型が正しくありません（期待: {field_type.__name__}）")
    
    # 選択肢のチェック
    if 'options' in question:
        if len(question['options']) != 4:
            errors.append("選択肢は4つである必要があります")
        elif not all(isinstance(opt, str) and opt.strip() for opt in question['options']):
            errors.append("すべての選択肢は空でない文字列である必要があります")
    
    # answerIndexのチェック
    if 'answerIndex' in question:
        if not (0 <= question['answerIndex'] <= 3):
            errors.append("answerIndexは0-3の範囲内である必要があります")
        elif 'options' in question and len(question['options']) == 4:
            # 選択肢のインデックスが有効か確認
            pass
    
    # 問題文のチェック
    if 'text' in question:
        if not question['text'].strip():
            errors.append("問題文が空です")
    
    # 解説のチェック
    if 'explanation' in question:
        if not question['explanation'].strip():
            errors.append("解説が空です")
        elif len(question['explanation']) < 50:
            errors.append("解説が短すぎます（50文字以上推奨）")
    
    return len(errors) == 0, errors


def validate_questions(questions: list) -> dict:
    """
    複数の問題を検証する
    
    Args:
        questions: 検証する問題のリスト
    
    Returns:
        検証結果の辞書
    """
    results = {
        'total': len(questions),
        'valid': 0,
        'invalid': 0,
        'errors': []
    }
    
    for i, question in enumerate(questions):
        is_valid, errors = validate_question(question)
        if is_valid:
            results['valid'] += 1
        else:
            results['invalid'] += 1
            results['errors'].append({
                'index': i,
                'errors': errors
            })
    
    return results
