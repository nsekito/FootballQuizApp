"""Gemini APIクライアント"""
import google.generativeai as genai
import json
import time
import sys
from pathlib import Path

# scripts/ディレクトリをパスに追加
scripts_dir = Path(__file__).parent.parent
sys.path.insert(0, str(scripts_dir))

from config import GEMINI_API_KEY

# Gemini APIを初期化
genai.configure(api_key=GEMINI_API_KEY)

# モデルを選択（gemini-2.5-flash: 高速、gemini-2.5-pro: 高品質）
# gemini-proは非推奨のため、gemini-2.5-flashまたはgemini-2.5-proを使用
MODEL_NAME = 'gemini-2.5-flash'  # 高速でコスト効率が良い
# MODEL_NAME = 'gemini-2.5-pro'  # より高品質な生成が必要な場合

model = genai.GenerativeModel(MODEL_NAME)


def generate_question(category: str, difficulty: str, tags: str = "") -> dict:
    """
    クイズ問題を1問生成する
    
    Args:
        category: カテゴリ（rules, history, teams）
        difficulty: 難易度（easy, normal, hard, extreme）
        tags: タグ（カンマ区切り）
    
    Returns:
        生成された問題の辞書
    """
    # カテゴリに応じたプロンプトを構築
    category_prompts = {
        'rules': 'サッカーのルールに関する問題',
        'history': 'サッカーの歴史に関する問題',
        'teams': 'サッカーチームに関する問題',
    }
    
    difficulty_prompts = {
        'easy': '初心者向けの簡単な問題',
        'normal': '中級者向けの標準的な問題',
        'hard': '上級者向けの難しい問題',
        'extreme': '最上級者向けの非常に難しい問題',
    }
    
    prompt = f"""
以下の条件でサッカーのクイズ問題を1問生成してください。

カテゴリ: {category_prompts.get(category, category)}
難易度: {difficulty_prompts.get(difficulty, difficulty)}
タグ: {tags if tags else '指定なし'}

以下のJSON形式で出力してください：
{{
  "text": "問題文（4択問題）",
  "options": ["選択肢1", "選択肢2", "選択肢3", "選択肢4"],
  "answerIndex": 0,
  "explanation": "詳しい解説（正解の理由や背景を含む）",
  "trivia": "豆知識や小ネタ（ユーザーの満足度向上のため）"
}}

重要:
- 必ず4つの選択肢を含めること
- answerIndexは0-3の整数で、正解の選択肢のインデックス
- explanationは詳しく、なぜその答えが正しいかを説明すること
- triviaは面白い豆知識や小ネタを含めること
- JSONのみを出力し、余計な説明は含めないこと
"""
    
    try:
        response = model.generate_content(prompt)
        # レスポンスからJSONを抽出
        response_text = response.text.strip()
        
        # マークダウンコードブロックを除去
        if response_text.startswith('```json'):
            response_text = response_text[7:]
        if response_text.startswith('```'):
            response_text = response_text[3:]
        if response_text.endswith('```'):
            response_text = response_text[:-3]
        response_text = response_text.strip()
        
        # JSONをパース
        question_data = json.loads(response_text)
        
        # 必須フィールドの検証
        required_fields = ['text', 'options', 'answerIndex', 'explanation']
        for field in required_fields:
            if field not in question_data:
                raise ValueError(f"必須フィールド '{field}' がありません")
        
        # 選択肢が4つあるか確認
        if len(question_data['options']) != 4:
            raise ValueError("選択肢は4つである必要があります")
        
        # answerIndexが0-3の範囲内か確認
        if not (0 <= question_data['answerIndex'] <= 3):
            raise ValueError("answerIndexは0-3の範囲内である必要があります")
        
        return question_data
    
    except json.JSONDecodeError as e:
        print(f"JSON解析エラー: {e}")
        print(f"レスポンス: {response_text}")
        raise
    except Exception as e:
        print(f"エラーが発生しました: {e}")
        raise
    
    finally:
        # APIレート制限対策（少し待機）
        time.sleep(1)


def generate_questions_batch(category: str, difficulty: str, count: int, tags: str = "") -> list:
    """
    複数のクイズ問題を生成する
    
    Args:
        category: カテゴリ
        difficulty: 難易度
        count: 生成する問題数
        tags: タグ
    
    Returns:
        生成された問題のリスト
    """
    questions = []
    for i in range(count):
        print(f"生成中: {category}/{difficulty} - {i+1}/{count}")
        try:
            question = generate_question(category, difficulty, tags)
            questions.append(question)
        except Exception as e:
            print(f"問題生成に失敗しました（スキップ）: {e}")
            continue
    
    return questions
