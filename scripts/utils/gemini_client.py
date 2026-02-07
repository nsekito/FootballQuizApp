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


def generate_weekly_recap_questions_batch(
    region: str,
    reference_date: str,
    matchweek: int = None,
    publish_date: str = None,
    expiry_date: str = None,
    season: str = None,
    start_number: int = 1
) -> list:
    """
    Grounding機能を使用して最新のサッカー情報を取得し、weeklyクイズ問題を30問一括生成
    
    Args:
        region: "japan" または "world"
        reference_date: 参照日（YYYY-MM-DD形式、例: "2026-02-07"）
        matchweek: 節数（オプション、該当しない場合はNone）
        publish_date: 公開日（YYYY-MM-DD形式、例: "2026-02-10"）
        expiry_date: 有効期限（YYYY-MM-DD形式、例: "2026-02-16"）
        season: シーズン（年、例: "2026"）
        start_number: IDの開始番号（デフォルト: 1）
    
    Returns:
        生成された問題のリスト（30問）
    """
    # プロンプトテンプレート
    prompt_template = """# Weekly サッカークイズ生成プロンプト

あなたはサッカークイズの問題作成の専門家です。
最新のサッカー情報をWeb検索で収集し、以下のルールとフォーマットに従ってweeklyクイズ問題を30問作成してください。

---

## 基本パラメータ

- region: {region}
- referenceDate: {referenceDate}
- matchweek: {matchweek}
- publishDate: {publishDate}
- expiryDate: {expiryDate}
- season: {season}
- ID採番: w_{startNumber} から連番
- 作成問題数: 30問

---

## 情報収集ルール

1. まずWeb検索を行い、{referenceDate} を含む直近1週間のサッカー情報を収集する
2. 検索は以下の優先順で行い、十分な情報が集まるまで複数回検索する
3. 収集した情報の事実確認を必ず行い、複数ソースで裏取りする
4. 速報段階で確定していない情報（移籍の噂レベル等）はクイズにしない
5. 検索で十分な情報が得られなかったカテゴリは、得られたカテゴリに問題数を振り替える

### regionごとの検索キーワード方針

#### japan

- Jリーグ（J1・J2）の試合結果、順位表
- ルヴァンカップ、天皇杯、ACLの結果
- Jリーグ公式、スポーツナビ、Football-LAB、ゲキサカ等を参照
- 日本代表関連のニュース
- 選手の移籍・契約更新情報
- クラブの経営・運営に関するニュース

#### world

- プレミアリーグ、ラ・リーガ、セリエA、ブンデスリーガ、リーグ・アンの試合結果
- UEFAチャンピオンズリーグ、ヨーロッパリーグの結果
- 海外日本人選手の出場・成績
- ESPN、BBC Sport、Transfermarkt、UEFA公式等を参照
- 主要な移籍・契約関連のニュース

---

## カテゴリ一覧

### japan

| categoryId | category | 方向性 |
|---|---|---|
| weekly-jp-match | 試合・結果 | 試合結果、スコア、得点者、アシスト、出場選手。試合がない週は代表戦・カップ戦・プレシーズンマッチも対象 |
| weekly-jp-standings | 順位・スタッツ | 順位表、勝ち点、得点ランキング、個人スタッツ。シーズン外は最終順位や年間表彰・各種アワードも対象 |
| weekly-jp-player | 選手の動向 | 移籍・契約更新・記録達成・ケガ・復帰・代表選出・海外挑戦 |
| weekly-jp-club | クラブ・リーグの動向 | 監督交代・新体制・スタジアム・スポンサー・新ユニフォーム・キャンプ・ACL・カップ戦運営 |
| weekly-jp-buzz | 今週の注目ニュース | VAR・判定・番狂わせ・規約改定・話題になった出来事全般 |

### world

| categoryId | category | 方向性 |
|---|---|---|
| weekly-world-match | 試合・結果 | 欧州主要リーグ・CL・ELなどのスコア、勝敗、得点者。試合がない週はプレシーズン・代表戦も対象 |
| weekly-world-standings | 順位・スタッツ | リーグ順位、得点王争い、CL/EL勝ち抜け状況。シーズン外は最終順位や各種アワードも対象 |
| weekly-world-player | 選手の動向 | 移籍・移籍金・記録達成・ケガ・復帰・代表関連 |
| weekly-world-japanese | 海外日本人選手 | 日本人選手の出場・ゴール・アシスト・移籍・契約更新・新天地での活躍 |
| weekly-world-buzz | 今週の注目ニュース | 監督解任・番狂わせ・VAR騒動・FIFA/UEFA決定事項・大会抽選・W杯関連 |

---

## 問題数の配分

30問を5カテゴリに配分する。検索で得られた情報量に応じて柔軟に調整する。

| カテゴリ | 基本配分 | 調整方針 |
|---|---|---|
| match | 10問 | 試合が少ない週・シーズン外は減らし他に振り替える |
| standings | 6問 | リーグが動いていない時期はアワード・年間成績系で補う |
| player / japanese | 5問 | japanはplayer、worldはjapanese。移籍期間は増やしてよい |
| club / player | 5問 | japanはclub、worldはplayer |
| buzz | 4問 | 調整枠。他カテゴリの過不足を吸収する |

**配分ルール:**

- 検索結果を見て、情報が豊富なカテゴリに多く配分してよい
- ただし1カテゴリ最低2問は確保する
- 1カテゴリ最大12問を超えない
- 合計は必ず30問にする

---

## 難易度の配分

| difficulty | 問題数 | 方針 |
|---|---|---|
| easy | 12問 | ニュースの見出しレベルで答えられる。「〇〇 vs △△の勝者は？」のような基本問題 |
| normal | 12問 | 試合を観たり記事を読んでいれば答えられる。「得点者は誰？」「何分のゴール？」レベル |
| hard | 6問 | 細かいスタッツや経緯まで追っていないと答えられない。「通算何得点目？」「前回達成したのはいつ？」レベル |

各カテゴリ内でeasy/normal/hardが偏らないように分散させる。

---

## 出力ルール

1. 出力はJSON配列のみ。JSON以外のテキスト（挨拶、説明文、検索過程の報告など）は一切出力しない
2. optionsの先頭（index 0）に必ず正解を配置し、answerIndexは常に0とする
3. tagsは問題の内容に応じて3〜5個程度つける
4. explanationは正解の理由や背景を含めた解説を書く（2〜3文程度）
5. triviaは150文字程度で「へぇ〜」と思える豆知識を書く（回答者が友達に自慢できるような内容）
6. 事実に基づいた問題のみ作成し、検索で裏取りできなかった情報は使わない
7. 同カテゴリ内で問題の内容が重複しないようにする
8. leagueフィールドにはその問題が関連するリーグIDを設定する（j1 / j2 / j3 / premier / laliga / seriea / bundesliga / ligue1 / ucl / uel 等）。複数リーグにまたがる場合や特定リーグに紐づかない場合は null
9. 不正解の選択肢はもっともらしいが明確に誤りであるものにする。紛らわしすぎて議論になるような選択肢は避ける

---

## JSONスキーマ

```json
[
  {{
    "id": "w_00001",
    "quizType": "weekly",
    "difficulty": "easy",
    "region": "{region}",
    "league": null,
    "team": null,
    "teamId": null,
    "category": "試合・結果",
    "categoryId": "{category_id_example}",
    "tags": ["tag1", "tag2", "tag3"],
    "text": "問題文",
    "options": ["正解", "不正解1", "不正解2", "不正解3"],
    "answerIndex": 0,
    "explanation": "解説文",
    "trivia": "豆知識",
    "referenceDate": "{referenceDate}",
    "weeklyMeta": {{
      "matchweek": {matchweekExample},
      "matchDate": null,
      "publishDate": "{publishDate}",
      "expiryDate": "{expiryDate}",
      "season": "{season}"
    }}
  }}
]
```

**注意:** 
- idは w_{startNumber} から連番で採番してください（例: w_00001, w_00002, ..., w_00030）
- matchweekは数値またはnullです（該当しない場合は null）
- categoryIdはカテゴリ一覧のcategoryIdの値を使用してください（japanの場合は weekly-jp-*、worldの場合は weekly-world-*）

---

## フィールド定義

| フィールド | 型 | 説明 |
|---|---|---|
| id | string | w_で始まる5桁の連番（例: w_00001） |
| quizType | string | 常に "weekly" |
| difficulty | string | easy / normal / hard |
| region | string | japan / world |
| league | string or null | j1 / j2 / j3 / premier / laliga / seriea / bundesliga / ligue1 / ucl / uel 等。特定リーグに紐づかない場合は null |
| team | string or null | 常に null |
| teamId | string or null | 常に null |
| category | string | カテゴリ一覧の category の値 |
| categoryId | string | カテゴリ一覧の categoryId の値 |
| tags | string[] | フリータグ 3〜5個 |
| text | string | 問題文 |
| options | string[4] | 選択肢4つ。index 0が必ず正解 |
| answerIndex | number | 常に0 |
| explanation | string | 正解の解説（2〜3文） |
| trivia | string | 豆知識（150文字程度） |
| referenceDate | string | {referenceDate} の値をそのまま設定 |
| weeklyMeta.matchweek | number or null | 節数。該当しない場合は null |
| weeklyMeta.matchDate | string or null | 問題に関連する試合日（YYYY-MM-DD）。試合に紐づかない場合は null |
| weeklyMeta.publishDate | string | {publishDate} の値をそのまま設定 |
| weeklyMeta.expiryDate | string | {expiryDate} の値をそのまま設定 |
| weeklyMeta.season | string | {season} の値をそのまま設定 |

---

## 作成手順

1. Web検索で {referenceDate} を含む直近1週間の {region} に関するサッカー情報を収集する
2. 収集した情報を5つのカテゴリに分類する
3. 情報量に応じて各カテゴリの問題数を決定する（配分ルールに従う）
4. 難易度配分に従って各問題の難易度を決定する
5. 問題を作成し、事実確認のため再度検索して裏取りする
6. JSON配列のみを出力する
"""
    
    # matchweekの文字列表現（プロンプト用）
    matchweek_str = str(matchweek) if matchweek is not None else "null"
    
    # matchweekの例（JSONスキーマ用）
    matchweek_example = matchweek if matchweek is not None else "null"
    
    # categoryIdの例（JSONスキーマ用）
    if region == "japan":
        category_id_example = "weekly-jp-match"
    else:  # world
        category_id_example = "weekly-world-match"
    
    # startNumberを5桁ゼロ埋め形式に変換
    start_number_str = f"{start_number:05d}"
    
    # プロンプトにパラメータを埋め込む
    prompt = prompt_template.format(
        region=region,
        referenceDate=reference_date,
        matchweek=matchweek_str,
        matchweekExample=matchweek_example,
        publishDate=publish_date or "",
        expiryDate=expiry_date or "",
        season=season or "",
        startNumber=start_number_str,
        category_id_example=category_id_example
    )
    
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
            
            # 問題数の確認（30問期待）
            expected_count = 30
            if len(questions_data) < expected_count:
                print(f"警告: 要求された{expected_count}問に対して{len(questions_data)}問しか生成されませんでした")
            
            # 各問題のバリデーションとフィールド補完
            validated_questions = []
            for i, question_data in enumerate(questions_data[:expected_count]):
                # 必須フィールドの検証
                required_fields = ['text', 'options', 'answerIndex', 'explanation', 'quizType', 'region', 'categoryId', 'referenceDate', 'weeklyMeta']
                missing_fields = [f for f in required_fields if f not in question_data]
                if missing_fields:
                    print(f"警告: 問題{i+1}に必須フィールドがありません: {missing_fields}。スキップします。")
                    continue
                
                # 選択肢が4つあるか確認
                if len(question_data.get('options', [])) != 4:
                    print(f"警告: 問題{i+1}の選択肢が4つではありません。スキップします。")
                    continue
                
                # answerIndexが0であることを確認（プロンプトで0に固定）
                if question_data.get('answerIndex', -1) != 0:
                    print(f"警告: 問題{i+1}のanswerIndexが0ではありません。0に修正します。")
                    question_data['answerIndex'] = 0
                
                # quizTypeが"weekly"であることを確認
                if question_data.get('quizType') != 'weekly':
                    print(f"警告: 問題{i+1}のquizTypeが'weekly'ではありません。修正します。")
                    question_data['quizType'] = 'weekly'
                
                # regionが正しいことを確認
                if question_data.get('region') != region:
                    print(f"警告: 問題{i+1}のregionが'{region}'ではありません。修正します。")
                    question_data['region'] = region
                
                # tagsが配列形式であることを確認（文字列の場合は分割）
                tags_value = question_data.get('tags', [])
                if isinstance(tags_value, str):
                    # カンマ区切りの文字列を配列に変換
                    question_data['tags'] = [tag.strip() for tag in tags_value.split(',') if tag.strip()]
                elif not isinstance(tags_value, list):
                    question_data['tags'] = []
                
                # teamとteamIdは常にnull
                question_data['team'] = None
                question_data['teamId'] = None
                
                # referenceDateが正しいことを確認
                if question_data.get('referenceDate') != reference_date:
                    print(f"警告: 問題{i+1}のreferenceDateが'{reference_date}'ではありません。修正します。")
                    question_data['referenceDate'] = reference_date
                
                # weeklyMetaの検証と補完
                weekly_meta = question_data.get('weeklyMeta', {})
                if not isinstance(weekly_meta, dict):
                    weekly_meta = {}
                
                # weeklyMetaの必須フィールドを補完
                weekly_meta.setdefault('matchweek', matchweek)
                weekly_meta.setdefault('matchDate', None)
                weekly_meta.setdefault('publishDate', publish_date)
                weekly_meta.setdefault('expiryDate', expiry_date)
                weekly_meta.setdefault('season', season)
                question_data['weeklyMeta'] = weekly_meta
                
                # デフォルト値の設定
                question_data.setdefault('difficulty', 'normal')
                question_data.setdefault('category', 'match_recap')
                question_data.setdefault('trivia', '')
                question_data.setdefault('league', None)
                
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
