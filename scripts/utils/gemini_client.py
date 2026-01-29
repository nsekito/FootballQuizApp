"""Gemini APIクライアント"""
import json
import re
import time
import sys
import random
from pathlib import Path

# サードパーティライブラリのインポート
try:
    from google import genai
except ImportError:
    print("エラー: google-genaiパッケージがインストールされていません。")
    print("以下のコマンドでインストールしてください:")
    print("  pip install google-genai")
    sys.exit(1)

# scripts/ディレクトリをパスに追加
scripts_dir = Path(__file__).parent.parent
sys.path.insert(0, str(scripts_dir))

from config import GEMINI_API_KEY, GEMINI_MODEL_NAME

# モデルを選択（config.pyから読み込み、デフォルト: gemini-3-pro-preview）
MODEL_NAME = GEMINI_MODEL_NAME

# APIクライアントを作成（モジュールレベルで初期化）
client = genai.Client(api_key=GEMINI_API_KEY)

# リトライ設定
MAX_RETRIES = 3  # 最大リトライ回数
BASE_DELAY = 1  # ベース待機時間（秒）


def generate_question(category: str, difficulty: str, tags: str = "", diversity_note: str = "") -> dict:
    """
    クイズ問題を1問生成する
    
    Args:
        category: カテゴリ（rules, history, teams）
        difficulty: 難易度（easy, normal, hard, extreme）
        tags: タグ（カンマ区切り）
        diversity_note: 多様性を確保するための追加ノート
    
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
  "trivia": "豆知識や小ネタ（150文字程度で充実した内容、ユーザーの満足度向上のため）",
  "referenceDate": "YYYYまたはYYYY-MM形式（問題の対象年月、オプション）"
}}

【問題作成の基本方針】
1. **知識・トリビアの習得を目的とする**
   - ユーザーがサッカー知識や興味深いトリビアを学べる問題を作成すること
   - 単なる記憶テストではなく、理解を深める問題を目指すこと

2. **明確な正解が1つだけ存在する問題**
   - 必ず事実に基づいた、明確に1つの正解のみが存在する問題を作成すること
   - 複数の解釈が可能な曖昧な問題は避けること
   - 「どちらも正解と取れる」ような選択肢は絶対に含めないこと

3. **ひっかけ問題の禁止**
   - 言葉のトリックや誤解を誘うようなひっかけ問題は作成しないこと
   - 問題文は明確で誤解の余地がないようにすること
   - 選択肢は正確で、正解以外は明確に間違いであること

4. **選択肢の品質**
   - 4つの選択肢はすべて同じ形式・同じ詳細レベルで作成すること
   - 正解以外の選択肢は、知識があれば明確に間違いと判断できるものにすること
   - 選択肢間で意味が重複したり、部分的に正しいものが含まれないようにすること

5. **解説とトリビアの充実**
   - explanationでは、なぜその答えが正しいかを具体的に説明すること
   - 関連する背景情報や歴史的経緯も含めること
   - triviaでは、問題に関連する興味深い豆知識や小ネタを提供すること
   - triviaは150文字程度（100-200文字の範囲）で充実した内容にすること
   - 単なる事実の羅列ではなく、読者が「へぇ、そうなんだ！」と思えるような興味深い情報を含めること

6. **問題の多様性と偏りの回避**
   - 同じテーマやトピックに偏らないよう、幅広い分野から問題を作成すること
   - ルールクイズの場合: オフサイド、ファウル、イエローカード、レッドカード、スローイン、コーナーキック、PK、延長戦、VARなど、様々なルールに分散させること
   - 歴史クイズの場合: 年代、大会、選手、チーム、出来事など、様々な観点から問題を作成すること
   - チームクイズの場合: 様々なチーム、リーグ、選手、スタジアムなどに分散させること
   - 難易度に応じて、基本的な知識から専門的な知識まで、幅広いレベルの問題を作成すること

【技術的な要件】
- 必ず4つの選択肢を含めること
- answerIndexは0-3の整数で、正解の選択肢のインデックス
- JSONのみを出力し、余計な説明は含めないこと
- 問題文、選択肢、解説はすべて日本語で記述すること
{diversity_note}
"""
    
    # リトライロジック付きでAPI呼び出し
    for attempt in range(MAX_RETRIES):
        try:
            response = client.models.generate_content(
                model=MODEL_NAME,
                contents=prompt
            )
            # レスポンスからJSONを抽出
            response_text = response.text.strip()
            
            # マークダウンコードブロックからJSONを抽出
            # ```json ... ``` の形式を探す
            json_match = re.search(r'```json\s*\n(.*?)\n```', response_text, re.DOTALL)
            if json_match:
                # JSONブロックが見つかった場合
                response_text = json_match.group(1).strip()
            else:
                # JSONブロックが見つからない場合、通常の``` ... ```を探す
                json_match = re.search(r'```\s*\n(.*?)\n```', response_text, re.DOTALL)
                if json_match:
                    response_text = json_match.group(1).strip()
                else:
                    # コードブロックがない場合、JSONオブジェクトの開始位置を探す
                    json_start = response_text.find('{')
                    json_end = response_text.rfind('}') + 1
                    if json_start != -1 and json_end > json_start:
                        response_text = response_text[json_start:json_end]
            
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
            
            # APIレート制限対策（少し待機）
            time.sleep(BASE_DELAY)
            return question_data
        
        except Exception as e:
            error_str = str(e)
            
            # クォータ超過エラー（429）の場合
            if '429' in error_str or 'quota' in error_str.lower() or 'Quota exceeded' in error_str:
                # リトライ待機時間を抽出（エラーメッセージから）
                retry_delay = BASE_DELAY * (2 ** attempt)  # 指数バックオフ
                
                # エラーメッセージからretry_delayを抽出を試みる
                if 'retry in' in error_str.lower() or 'retry_delay' in error_str.lower():
                    try:
                        # エラーメッセージから秒数を抽出
                        import re
                        match = re.search(r'(\d+\.?\d*)\s*秒', error_str)
                        if match:
                            retry_delay = float(match.group(1)) + 1  # 少し余裕を持たせる
                    except:
                        pass
                
                if attempt < MAX_RETRIES - 1:
                    print(f"クォータ制限に達しました。{retry_delay:.1f}秒待機して再試行します... (試行 {attempt + 1}/{MAX_RETRIES})")
                    time.sleep(retry_delay)
                    continue
                else:
                    print(f"エラー: クォータ制限に達しました。しばらく待ってから再実行してください。")
                    raise Exception(f"APIクォータ制限: {error_str}")
            
            # JSON解析エラーの場合
            elif isinstance(e, json.JSONDecodeError):
                print(f"JSON解析エラー: {e}")
                print(f"レスポンス: {response_text}")
                if attempt < MAX_RETRIES - 1:
                    print(f"{BASE_DELAY * (attempt + 1)}秒待機して再試行します...")
                    time.sleep(BASE_DELAY * (attempt + 1))
                    continue
                raise
            
            # その他のエラー
            else:
                if attempt < MAX_RETRIES - 1:
                    print(f"エラーが発生しました: {e}")
                    print(f"{BASE_DELAY * (attempt + 1)}秒待機して再試行します...")
                    time.sleep(BASE_DELAY * (attempt + 1))
                    continue
                raise
    
    # すべてのリトライが失敗した場合
    raise Exception("問題生成に失敗しました（最大リトライ回数に達しました）")


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
    
    return balanced_questions


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
    import datetime
    questions = []
    start_time = datetime.datetime.now()
    
    # 既に生成した問題のテーマを記録（重複回避用）
    generated_themes = []
    
    print(f"\n開始時刻: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"生成予定: {count}問")
    print("-" * 60)
    
    for i in range(count):
        question_start = datetime.datetime.now()
        print(f"[{i+1}/{count}] 生成開始: {question_start.strftime('%H:%M:%S')}", end=" ... ")
        
        try:
            # 既に生成した問題のテーマ情報をプロンプトに追加（多様性確保）
            diversity_note = ""
            if generated_themes:
                diversity_note = f"\n\n【重要】既に生成した問題のテーマ（重複を避けること）:\n"
                diversity_note += "\n".join([f"- {theme}" for theme in generated_themes[-10:]])  # 直近10件のみ
                diversity_note += "\n上記とは異なるテーマやトピックで問題を作成してください。"
            
            question = generate_question(category, difficulty, tags, diversity_note)
            
            # 生成された問題のテーマを抽出（問題文の最初の30文字をキーワードとして使用）
            theme_keyword = question.get('text', '')[:30].strip()
            generated_themes.append(theme_keyword)
            
            questions.append(question)
            question_end = datetime.datetime.now()
            elapsed = (question_end - question_start).total_seconds()
            print(f"完了 ({elapsed:.1f}秒)")
        except Exception as e:
            question_end = datetime.datetime.now()
            elapsed = (question_end - question_start).total_seconds()
            print(f"失敗 ({elapsed:.1f}秒): {e}")
            continue
        
        # 10問ごとに進捗を表示
        if (i + 1) % 10 == 0:
            elapsed_total = (datetime.datetime.now() - start_time).total_seconds()
            avg_time = elapsed_total / (i + 1)
            remaining = (count - i - 1) * avg_time
            print(f"進捗: {i+1}/{count}問完了 | 平均: {avg_time:.1f}秒/問 | 残り時間見積もり: {remaining/60:.1f}分")
    
    end_time = datetime.datetime.now()
    total_elapsed = (end_time - start_time).total_seconds()
    print("-" * 60)
    print(f"完了時刻: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"合計時間: {total_elapsed/60:.1f}分 ({total_elapsed:.1f}秒)")
    print(f"成功: {len(questions)}問 / {count}問")
    
    # answerIndexの分布を均等化
    print("\nanswerIndexの分布を均等化中...")
    questions = balance_answer_indices(questions)
    
    # 分布を確認して表示
    counts = [0, 0, 0, 0]
    for q in questions:
        idx = q.get('answerIndex', 0)
        if 0 <= idx <= 3:
            counts[idx] += 1
    print(f"均等化後の分布: [0]: {counts[0]}, [1]: {counts[1]}, [2]: {counts[2]}, [3]: {counts[3]}")
    
    return questions


def generate_weekly_recap_questions_batch(
    date: str,
    league_type: str,
    count: int = 10
) -> list:
    """
    Grounding機能を使用して試合結果を取得し、クイズ問題を一括生成
    
    Args:
        date: 日付（YYYY-MM-DD形式、例: "2025-01-12"）
        league_type: "j1" または "europe"
        count: 生成する問題数（デフォルト: 10）
    
    Returns:
        生成された問題のリスト
    """
    # リーグタイプに応じた設定
    if league_type == "j1":
        league_name = "J1リーグ"
        tags = "japan,j1,2025"
        fallback_source = "J1リーグ各チームの公式サイトやニュース"
    else:  # europe
        league_name = "ヨーロッパサッカー（プレミアリーグ、ラ・リーガ、ブンデスリーガ、セリエA）"
        tags = "europe,premier_league,la_liga,bundesliga,serie_a,2025"
        fallback_source = "各リーグやチームの公式サイト、ニュース"
    
    prompt = f"""
{date}（昨日）の{league_name}の試合結果を検索して、以下の形式でクイズ問題を{count}問一括生成してください。

【試合結果がない場合のフォールバック】
試合がない週や試合結果が見つからない場合は、{fallback_source}から最新のニュース（移籍、選手情報、チーム情報など）を検索して問題を作成してください。

【出力形式】
以下のJSON配列形式で、{count}問すべてを一度に出力してください：
[
  {{
    "text": "問題文（4択問題）",
    "options": ["選択肢1", "選択肢2", "選択肢3", "選択肢4"],
    "answerIndex": 0,
    "explanation": "詳しい解説（試合の詳細またはニュースの背景を含む）",
    "trivia": "豆知識や小ネタ（150文字程度）",
    "category": "match_recap",
    "difficulty": "normal",
    "tags": "{tags}"
  }},
  ...
]

【重要】
- 検索結果に基づいた事実のみを使用すること
- 試合結果があれば勝敗、得点者、順位変動などから問題を作成
- 試合結果がなければ、ニュースから問題を作成
- ハルシネーションを避けるため、検索結果の情報のみを使用すること
- 必ず{count}問を生成すること
- JSON配列形式で出力すること（単一のJSONオブジェクトではなく）
"""
    
    # リトライロジック付きでAPI呼び出し
    for attempt in range(MAX_RETRIES):
        try:
            # 新しいAPIを使用（google_searchツールを有効化）
            response = client.models.generate_content(
                model=MODEL_NAME,
                contents=prompt,
                config={
                    "tools": [{"google_search": {}}],  # Grounding機能を有効化
                }
            )
            
            # レスポンスからJSONを抽出
            response_text = response.text.strip()
            
            # マークダウンコードブロックからJSONを抽出
            # ```json ... ``` の形式を探す
            json_match = re.search(r'```json\s*\n(.*?)\n```', response_text, re.DOTALL)
            if json_match:
                # JSONブロックが見つかった場合
                response_text = json_match.group(1).strip()
            else:
                # JSONブロックが見つからない場合、通常の``` ... ```を探す
                json_match = re.search(r'```\s*\n(.*?)\n```', response_text, re.DOTALL)
                if json_match:
                    response_text = json_match.group(1).strip()
                else:
                    # コードブロックがない場合、JSON配列の開始位置を探す
                    json_start = response_text.find('[')
                    json_end = response_text.rfind(']') + 1
                    if json_start != -1 and json_end > json_start:
                        response_text = response_text[json_start:json_end]
                    else:
                        # それでも見つからない場合は、説明文を除去してから試す
                        # 最初の[から最後の]までを抽出
                        if '[' in response_text:
                            response_text = response_text[response_text.find('['):]
                            if ']' in response_text:
                                response_text = response_text[:response_text.rfind(']') + 1]
            
            # JSON配列をパース
            questions_data = json.loads(response_text)
            
            # リストでない場合はリストに変換
            if not isinstance(questions_data, list):
                questions_data = [questions_data]
            
            # 問題数の確認
            if len(questions_data) < count:
                print(f"警告: 要求された{count}問に対して{len(questions_data)}問しか生成されませんでした")
            
            # 各問題のバリデーション
            validated_questions = []
            for i, question_data in enumerate(questions_data[:count]):
                # 必須フィールドの検証
                required_fields = ['text', 'options', 'answerIndex', 'explanation']
                missing_fields = [f for f in required_fields if f not in question_data]
                if missing_fields:
                    print(f"警告: 問題{i+1}に必須フィールドがありません: {missing_fields}。スキップします。")
                    continue
                
                # 選択肢が4つあるか確認
                if len(question_data.get('options', [])) != 4:
                    print(f"警告: 問題{i+1}の選択肢が4つではありません。スキップします。")
                    continue
                
                # answerIndexが0-3の範囲内か確認
                if not (0 <= question_data.get('answerIndex', -1) <= 3):
                    print(f"警告: 問題{i+1}のanswerIndexが0-3の範囲外です。スキップします。")
                    continue
                
                # デフォルト値の設定
                question_data.setdefault('category', 'match_recap')
                question_data.setdefault('difficulty', 'normal')
                question_data.setdefault('tags', tags)
                question_data.setdefault('trivia', '')
                
                validated_questions.append(question_data)
            
            if len(validated_questions) == 0:
                raise ValueError("有効な問題が1問も生成されませんでした")
            
            print(f"成功: {len(validated_questions)}問を生成しました")
            return validated_questions
        
        except json.JSONDecodeError as e:
            print(f"JSON解析エラー: {e}")
            print(f"レスポンス（最初の500文字）: {response_text[:500]}")
            if attempt < MAX_RETRIES - 1:
                print(f"{BASE_DELAY * (attempt + 1)}秒待機して再試行します...")
                time.sleep(BASE_DELAY * (attempt + 1))
                continue
            raise
        
        except Exception as e:
            error_str = str(e)
            
            # クォータ超過エラー（429）の場合
            if '429' in error_str or 'quota' in error_str.lower() or 'Quota exceeded' in error_str:
                retry_delay = BASE_DELAY * (2 ** attempt)
                if attempt < MAX_RETRIES - 1:
                    print(f"クォータ制限に達しました。{retry_delay:.1f}秒待機して再試行します... (試行 {attempt + 1}/{MAX_RETRIES})")
                    time.sleep(retry_delay)
                    continue
                else:
                    print(f"エラー: クォータ制限に達しました。しばらく待ってから再実行してください。")
                    raise Exception(f"APIクォータ制限: {error_str}")
            
            # その他のエラー
            if attempt < MAX_RETRIES - 1:
                print(f"エラーが発生しました: {e}")
                print(f"{BASE_DELAY * (attempt + 1)}秒待機して再試行します...")
                time.sleep(BASE_DELAY * (attempt + 1))
                continue
            raise
    
    # すべてのリトライが失敗した場合
    raise Exception("問題生成に失敗しました（最大リトライ回数に達しました）")
