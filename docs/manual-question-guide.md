# 手動問題作成ガイド

このガイドでは、gensparkのチャットを使用して手動で問題を作成し、データベースに取り込む方法を説明します。

## 概要

ルールクイズ、歴史クイズ、チームクイズの問題は、gensparkのチャットを使用して手動で作成します。作成したJSONファイルを`json_to_db.py`スクリプトでデータベースに取り込みます。

## プロンプトテンプレート

以下のプロンプトテンプレートをgensparkのチャットに貼り付けて使用します。

```
あなたはサッカークイズの問題作成の専門家です。
以下のルールとフォーマットに従って、クイズ問題を作成してください。

---

# 出力ルール

1. 出力はJSON配列のみ。JSON以外のテキスト（挨拶、説明文など）は一切出力しない
2. optionsの先頭（index 0）に必ず正解を配置し、answerIndexは常に0とする
3. tagsは問題の内容に応じて3〜5個程度つける
4. explanationは正解の理由や背景を含めた解説を書く（2〜3文程度）
5. triviaは150文字程度で「へぇ〜」と思える豆知識を書く（回答者が友達に自慢できるような内容）
6. 事実に基づいた問題を作成し、不確かな情報は必ず検索して裏取りする
7. 同カテゴリ内で問題の内容が重複しないようにする
8. 問題の難易度は指定されたdifficultyに合わせる
   - easy: サッカーを始めた子どもを持つパパママでも答えられる基本問題（少年サッカーの観戦・準備で実際に疑問に思うレベル）
     - ルールクイズにおいては、サッカーを始めた子どもを持つパパママでも答えられる基本問題（少年サッカーの観戦・準備で実際に疑問に思うレベル）
   - normal: そこそこのサッカーファンなら答えられる中級問題
   - hard: コアファンや審判資格保持者でも迷う上級問題
9. ルールの出典はIFAB「サッカー競技規則」（Laws of the Game）を基準とし、大会固有ルールの場合はその旨を明記する
10. **重要**: JSON内の文字列値にダブルクォート（`"`）が含まれる場合は、必ずバックスラッシュでエスケープして`\"`としてください。エスケープされていないダブルクォートがあるとJSONパースエラーになります

---

# JSONスキーマ

```json
[
  {
    "id": "q_00001",
    "quizType": "",
    "difficulty": "",
    "region": null,
    "league": null,
    "team": null,
    "teamId": null,
    "category": "",
    "categoryId": "",
    "tags": [],
    "text": "",
    "options": ["正解", "不正解1", "不正解2", "不正解3"],
    "answerIndex": 0,
    "explanation": "",
    "trivia": "",
    "referenceDate": ""
  }
]
```

---

# フィールド定義

| フィールド | 型 | 説明 |
|---|---|---|
| id | string | q_{5桁連番}（例: q_00001） |
| quizType | string | team / history / rule / weekly |
| difficulty | string | easy / normal / hard |
| region | string or null | japan / world / null |
| league | string or null | j1 / j2 / spain / italy 等 / null |
| team | string or null | 表示用チーム名（日本語） |
| teamId | string or null | システム用チームID（英字） |
| category | string | 表示用カテゴリ名 |
| categoryId | string | システム用カテゴリID |
| tags | string[] | フリータグ 3〜5個 |
| text | string | 問題文 |
| options | string[4] | 選択肢4つ。index 0が必ず正解 |
| answerIndex | number | 常に0 |
| explanation | string | 正解の解説 |
| trivia | string | 豆知識（150文字程度） |
| referenceDate | string | YYYY-MM-DD形式 |

---

# クイズ種別ごとのフィールド使用パターン

## team（チームクイズ）
全フィールド使用。region, league, team, teamId を必ず設定。

## history（歴史クイズ）
region を設定（japan / world）。league, team, teamId は null。

## rule（ルールクイズ）
region, league, team, teamId は null。将来的にregionが追加される可能性あり。

## weekly（週間マッチクイズ）
region, league を設定。team, teamId は null。
追加フィールド weeklyMeta を含める：
```json
"weeklyMeta": {
  "matchweek": 1,
  "matchDate": "2026-02-08",
  "publishDate": "2026-02-10",
  "expiryDate": "2026-02-16",
  "season": "2026"
}
```

---

# チームクイズ カテゴリ一覧（標準テンプレート）

## Easy
| categoryId | category | 方向性 |
|---|---|---|
| stadium | ホームスタジアム | 本拠地の名前、所在地、収容人数、愛称 |
| club-basics | チーム基本情報 | 設立年、クラブカラー、正式名称、運営法人 |
| mascot | マスコット | マスコットの名前、モチーフ、背番号、特徴 |
| legends | 有名OB・レジェンド | 誰もが知る元所属の有名選手 |
| titles | タイトル・主要成績 | リーグ優勝年、カップ戦優勝歴 |
| current-players | 現所属の有名選手 | 背番号、代表選手、注目選手 |
| uniform-emblem | ユニフォーム・エンブレム | ホームの色、エンブレムのモチーフ、メーカー |
| hometown | ホームタウン・地域 | ホームタウンの都市、地域の特徴、最寄り駅 |
| derby-rival | ライバル・ダービー | ダービーの名称、対戦相手、歴史 |
| nickname-chant | クラブの愛称・チャント | チームの通称、有名な応援歌、スローガン |

## Normal
| categoryId | category | 方向性 |
|---|---|---|
| transfers | 移籍・加入経歴 | 選手の前所属クラブ、移籍先 |
| season-records | シーズン記録 | 特定シーズンの順位、得点王 |
| managers | 監督の歴史 | 歴代監督、就任年、戦術スタイル |
| squad-numbers | 背番号の歴史 | 歴代の背番号を着けた選手 |
| classic-matches | 名勝負・名シーン | 印象的な試合の結果や得点者 |
| individual-records | 得点記録・個人記録 | 通算得点ランキング、出場記録 |
| foreign-players | 外国人選手 | 歴代の助っ人外国人 |
| academy | 下部組織・ユース出身 | アカデミー出身の選手 |
| sponsors | スポンサー・パートナー | ユニフォームスポンサー、命名権 |
| promotion-relegation | 昇格・降格の歴史 | 降格年、昇格を決めた試合 |

## Hard
| categoryId | category | 方向性 |
|---|---|---|
| birthday-birthplace | 選手の誕生日・出身地 | 選手の誕生日、出身県 |
| pets-private | 選手のペット・私生活 | 飼っているペットの名前や種類 |
| hobbies-skills | 選手の趣味・特技 | 趣味、好きな食べ物、特技 |
| debut-first-goal | デビュー戦・初ゴール | プロ初出場の相手、初得点 |
| goal-celebrations | ゴールパフォーマンス | ゴール後のパフォーマンス |
| training-facilities | 練習場・施設 | 練習場の場所、クラブハウスの特徴 |
| supporter-culture | サポーター文化 | ゴール裏の特徴、コレオの歴史 |
| player-relationships | 選手間の人間関係 | 仲が良い選手同士、あだ名の由来 |
| club-trivia | クラブの裏話・トリビア | クラブにまつわる意外なエピソード |
| historical-data | 歴史的データ・数字 | 最多連勝記録、最年少出場記録 |

---

# ルールクイズ カテゴリ一覧

## Easy（サッカーパパママ向け）
| categoryId | category | 方向性 |
|---|---|---|
| basic-rules | 基本ルール | 1チームの人数、試合時間、ハーフタイム、キックオフの仕組み |
| throw-in | スローイン | 両手で投げる、足は地面につける、投げ方の反則（ファウルスロー） |
| goal-kick-corner | ゴールキック・CK | どちらになる条件、蹴る位置、相手はどこまで近づけるか |
| offside-basics | オフサイドって何？ | 「なぜ今の止められたの？」を解消する最低限の仕組み |
| fouls-freekick | ファウルとフリーキック | 手で押した・足を引っかけた→笛が鳴る理由、直接FK/間接FKの見分け方 |
| yellow-red | イエローカード・レッドカード | どんな行為でもらうか、累積、退場後どうなるか |
| penalty-kick | ペナルティキック | PKになる条件、蹴る場所、GK以外はエリアに入れない |
| player-equipment | 選手の服装・用具 | すね当て義務、スパイクの決まり、ユニフォームの番号、GKの色 |
| referee-signals | 審判の合図 | 笛・旗の意味、主審と副審（線審）の役割、よく見るジェスチャー |
| pitch-markings | フィールドのライン | センターサークル、ペナルティエリア、各ラインの名前と意味 |

## Normal（中級サッカーファン向け）
| categoryId | category | 方向性 |
|---|---|---|
| var-technology | VAR・テクノロジー | VARの介入条件、ゴールラインテクノロジーの仕組み |
| penalty-rules | PK・DOGSO | PKの細かいルール、DOGSO/SPA、PK戦の手順 |
| offside-advanced | オフサイド応用 | 戻りオフサイド、意図的なプレーの解釈、GKとの関係 |
| advantage-play | アドバンテージ | アドバンテージ適用の条件、遅延カードの仕組み |
| substitution-rules | 交代・登録ルール | 脳震盪交代、再入場不可、コンペティション別の交代枠 |
| referee-system | 審判制度 | 主審/副審/第4審の役割分担、追加副審の導入 |
| gk-rules | GKの特別ルール | バックパス、6秒ルール、ペナルティエリア外の扱い |
| restart-rules | リスタート・再開 | ドロップボール、FK時の壁の距離、クイックリスタートの条件 |
| handball-interpretation | ハンドの解釈 | 「不自然な手の位置」の定義、攻撃側ハンドの扱い、偶発的ハンド |
| time-rules | 時間に関するルール | アディショナルタイム、飲水タイム、クーリングブレイク、延長戦の仕組み |

## Hard（コアファン・審判資格保持者向け）
| categoryId | category | 方向性 |
|---|---|---|
| rule-history | ルール改正の歴史 | バックパスルール導入年、オフサイドルールの変遷、延長Vゴール廃止 |
| rare-situations | レアケース・珍ルール | 間接FK→直接ゴール、主審にボールが当たった場合、同時反則 |
| competition-regulations | 大会固有レギュレーション | W杯・CL・Jリーグ特有のルール（登録人数、外国人枠、ホームアウェイ） |
| disciplinary-rules | 懲戒・累積・出場停止 | 累積警告の基準、出場停止の適用範囲、異議による加重処分 |
| ifab-laws | IFAB・競技規則の条文 | 第○条の内容、IFABの構成、競技規則の正式名称や改定プロセス |
| offside-edge-cases | オフサイドの境界判定 | 体の部位による判定、半自動オフサイドの仕組み、意図的プレーと偏向の違い |
| penalty-shootout-detail | PK戦の詳細規定 | ABBAの試験導入、蹴る順番の決め方、負傷時の対応、GK交代の条件 |
| multi-ball-system | マルチボールシステム | ボール交換の基準、試合球の個数、濡れたボールの扱い |
| temporary-dismissal | 一時的退場・シンビン | シンビン制度の対象、適用される大会、復帰の条件 |
| law-amendments-recent | 直近の競技規則改正 | 2024/25改正点、キックオフ時の新ルール、交代手続きの変更など |

---

# 歴史クイズ カテゴリ一覧

## Easy（ライトファン向け）
| categoryId | category | 方向性（japan） | 方向性（world） |
|---|---|---|---|
| world-cup-basics | W杯の基本 | 日本代表のW杯初出場年、開催国、GL突破回数 | 優勝回数最多の国、開催国、有名な決勝戦 |
| iconic-players | 伝説の選手 | キング・カズ、中田英寿、本田圭佑など誰もが知る選手 | ペレ、マラドーナ、メッシなど世界的スーパースター |
| tournament-history | 大会の歴史 | Jリーグ開幕年、天皇杯の歴史、アジアカップ | W杯・EURO・コパアメリカ・CLの基本的な歴史 |
| national-team-moments | 代表チームの名場面 | ドーハの悲劇、ジョホールバルの歓喜 | マラカナンの悲劇、ミラクル・オブ・ベルン |
| famous-goals | 歴史的ゴール | 中田英寿のW杯初得点、三浦知良のアジアカップ | マラドーナの5人抜き、ジダンのボレー |
| league-origins | リーグの誕生 | Jリーグの発足経緯、前身の日本サッカーリーグ(JSL) | プレミア・リーガ・セリエA・ブンデスの成り立ち |
| champion-teams | 優勝チーム | Jリーグ初代王者、連覇を達成したクラブ | W杯・CL優勝チームの基本知識 |
| host-countries | 開催国・開催地 | 2002年日韓W杯の開催都市、国立競技場 | W杯開催国の変遷、五大陸持ち回り |
| awards-ballon-dor | 個人賞・MVP | Jリーグ MVP、日本年間最優秀選手 | バロンドール、FIFA最優秀選手賞 |
| rule-milestones | ルール変革の節目 | Jリーグの延長Vゴール制度、2ステージ制 | バックパスルール導入、VAR元年 |

## Normal（中級サッカーファン向け）
| categoryId | category | 方向性（japan） | 方向性（world） |
|---|---|---|---|
| transfers-moves | 移籍の歴史 | 日本人選手の海外移籍史、Jリーグ大型移籍 | 歴代最高額移籍、衝撃の移籍劇 |
| tactical-evolution | 戦術の変遷 | 日本代表のフォーメーション変遷、Jクラブの戦術革新 | トータルフットボール、カテナチオ、ティキタカ |
| coaching-legends | 名将列伝 | オフト、トルシエ、オシム、岡田武史 | ファーガソン、グアルディオラ、サッキ |
| rivalry-derbies | 歴史的ライバル対決 | 静岡ダービー、多摩川クラシコ、国立の名勝負 | エル・クラシコ、オールドファーム、スーペルクラシコ |
| scandal-controversy | 事件・スキャンダル | ドーピング問題、八百長疑惑、Jクラブの経営危機 | カルチョポリ、FIFAゲート、ハンドオブゴッド |
| records-stats | 記録・データ | J1通算最多得点、最多出場、連勝記録 | W杯通算最多得点、CL連覇記録 |
| continental-cups | 大陸間・国際大会 | ACL・アジアカップでの日本勢の成績 | CL・リベルタドーレス・クラブW杯の歴史 |
| womens-football | 女子サッカーの歴史 | なでしこジャパンW杯優勝、WEリーグ発足 | 女子W杯の歴史、アメリカ女子代表の黄金期 |
| youth-development | 育成・若手の歴史 | 高校サッカー・ユース年代の名勝負、飛び級選手 | ラ・マシア、アヤックス育成、若手の台頭 |
| expansion-globalization | サッカーの拡大・国際化 | Jリーグのクラブ数拡大、地域密着の歩み | プレミアの商業化、中東マネー、MLS成長 |

## Hard（コアファン向け）
| categoryId | category | 方向性（japan） | 方向性（world） |
|---|---|---|---|
| pre-jleague | Jリーグ以前・黎明期 | JSL時代、天皇杯の戦前史、東京五輪のサッカー | W杯初期（1930年代）、戦前のサッカー史 |
| forgotten-episodes | 忘れられたエピソード | 知られざる代表戦の裏話、幻のゴール | 歴史に埋もれた名試合、消えたクラブの物語 |
| geopolitics-football | サッカーと社会・政治 | サッカーと地域振興、Jリーグ百年構想の背景 | サッカー戦争、アパルトヘイトと南ア、冷戦期の東西対決 |
| kit-badge-history | ユニフォーム・エンブレムの変遷 | 日本代表ユニフォームの変遷、Jクラブのエンブレム改定史 | 名門クラブのエンブレム由来、ユニフォーム史 |
| stadium-history | スタジアムの歴史 | 国立競技場の変遷、Jクラブの専用スタジアム建設史 | ウェンブリー、マラカナン、サンティアゴ・ベルナベウの改築史 |
| referee-history | 審判の歴史 | 日本人国際審判の活躍、Jリーグの判定をめぐる事件 | W杯の誤審事件、VAR導入までの経緯 |
| club-founding | クラブ創設の物語 | Jクラブの母体企業・市民クラブの成り立ち | 世界最古のクラブ、名門の創設秘話 |
| calendar-dates | この日に何が起きた？ | 特定の日付に起きたJリーグ・代表の歴史的出来事 | 特定の日付に起きたW杯・欧州サッカーの歴史的出来事 |
| numbers-trivia | 数字にまつわるトリビア | 「10番」の系譜、背番号にまつわる逸話、記録の数字 | 「背番号14」の意味、記録の数字、試合のスコア |
| what-if | もしも・ターニングポイント | 「もしあの判定がなければ」日本サッカーの分岐点 | 「もしマラドーナのハンドが取り消されていたら」歴史のif |

---

# 今回の作成依頼

- quizType: {quizType}
- region: {region}
- league: {league}
- team: {team}
- teamId: {teamId}
- difficulty: {difficulty}
- category: {category}
- categoryId: {categoryId}
- referenceDate: {referenceDate}
- 作成問題数: {count}問
- ID採番: q_{startNumber} から連番
```

## 使い方

### 1. プロンプトの準備

プロンプトテンプレートの末尾の `# 今回の作成依頼` 部分だけを書き換えて実行します。

**例：柏レイソル / easy / ホームスタジアム / 10問**

```
- quizType: team
- region: japan
- league: j1
- team: 柏レイソル
- teamId: kashiwa
- difficulty: easy
- category: ホームスタジアム
- categoryId: stadium
- referenceDate: 2026-02-07
- 作成問題数: 10問
- ID採番: q_00001 から連番
```

**例：ルールクイズ / easy / 10問**

```
- quizType: rule
- region: null
- league: null
- team: null
- teamId: null
- difficulty: easy
- category: 基本ルール
- categoryId: basic-rules
- referenceDate: 2026-02-07
- 作成問題数: 10問
- ID採番: q_10001 から連番
```

**例：歴史クイズ / easy / japan / 10問**

```
- quizType: history
- region: japan
- league: null
- team: null
- teamId: null
- difficulty: easy
- category: W杯の基本
- categoryId: world-cup-basics
- referenceDate: 2026-03-02
- 作成問題数: 10問
- ID採番: h_00001 から連番
```

**例：歴史クイズ / normal / world / 10問**

```
- quizType: history
- region: world
- league: null
- team: null
- teamId: null
- difficulty: normal
- category: 移籍の歴史
- categoryId: transfers-moves
- referenceDate: 2026-03-02
- 作成問題数: 10問
- ID採番: h_10001 から連番
```

### 2. 問題生成

1. gensparkのチャットを開く
2. プロンプトテンプレートを貼り付け
3. `# 今回の作成依頼` 部分を編集
4. 送信して問題を生成
5. 生成されたJSON配列をコピー

### 3. JSONファイルの保存

1. 適切なディレクトリに移動
   - チームクイズ: `data/manual_questions/team/japan/j1/` など
   - 歴史クイズ: `data/manual_questions/history/japan/` など
   - ルールクイズ: `data/manual_questions/rule/`
   - 週間マッチクイズ: `data/manual_questions/weekly/`

2. JSONファイルを作成
   - ファイル名は `{quizType}_{difficulty}_{YYYYMMDD}.json` 形式
   - 例: `team_easy_20260207.json`

3. 生成されたJSON配列をファイルに保存

### 4. データベースへの取り込み

```powershell
# ルールクイズの場合（初回は--create-schemaが必要）
python scripts/json_to_db.py data/manual_questions/rule/rule_easy_20260207.json --create-schema --replace

# チームクイズの場合
python scripts/json_to_db.py data/manual_questions/team/japan/j1/team_normal_20260207.json --replace

# 歴史クイズの場合
python scripts/json_to_db.py data/manual_questions/history/japan/history_easy_20260207.json --replace

# 複数ファイルを一度に取り込む場合
python scripts/json_to_db.py data/manual_questions/rule/rule_easy_20260207.json --replace
python scripts/json_to_db.py data/manual_questions/rule/rule_normal_20260207.json --replace
python scripts/json_to_db.py data/manual_questions/rule/rule_hard_20260207.json --replace
```

### 5. 動作確認

アプリを起動して、取り込んだ問題が正しく表示されるか確認します。

## ファイル名規約

**形式:** `{quizType}_{difficulty}_{YYYYMMDD}.json`

- `quizType`: `team`, `history`, `rule`, `weekly`
- `difficulty`: `easy`, `normal`, `hard`
- `YYYYMMDD`: 作成日（例: `20260207`）

**例:**
- `team_easy_20260207.json`
- `history_normal_20260207.json`
- `rule_hard_20260207.json`

## 注意事項

1. **IDの重複チェック**
   - 同じIDの問題が既に存在する場合、`--replace`オプションで置き換えられます
   - IDは `q_{5桁連番}` 形式で、連番を適切に管理してください

2. **ファイル名とJSON内容の一致**
   - ファイル名から`quizType`と`difficulty`が自動検出されます
   - JSON内の`quizType`と`difficulty`がファイル名と一致しない場合は警告が表示されます

3. **tagsフィールド**
   - tagsは配列形式で記述してください
   - データベースに保存する際に自動的にカンマ区切り文字列に変換されます

4. **weeklyMetaフィールド**
   - weeklyクイズの場合のみ`weeklyMeta`オブジェクトを含めてください
   - データベースに保存する際に自動的にJSON文字列に変換されます

5. **既存データとの互換性**
   - 新しいスキーマのフィールドはすべてオプショナルです
   - 既存のデータベースにも新しいフィールドが追加されます（NULL値）

## チームクイズ全300問の作成例

柏レイソル全300問を作る場合は、以下の30回の実行で完成します。

| 回 | difficulty | categoryId | ID開始 |
|---|---|---|---|
| 1 | easy | stadium | q_00001 |
| 2 | easy | club-basics | q_00011 |
| 3 | easy | mascot | q_00021 |
| 4 | easy | legends | q_00031 |
| 5 | easy | titles | q_00041 |
| 6 | easy | current-players | q_00051 |
| 7 | easy | uniform-emblem | q_00061 |
| 8 | easy | hometown | q_00071 |
| 9 | easy | derby-rival | q_00081 |
| 10 | easy | nickname-chant | q_00091 |
| 11 | normal | transfers | q_00101 |
| 12 | normal | season-records | q_00111 |
| 13 | normal | managers | q_00121 |
| 14 | normal | squad-numbers | q_00131 |
| 15 | normal | classic-matches | q_00141 |
| 16 | normal | individual-records | q_00151 |
| 17 | normal | foreign-players | q_00161 |
| 18 | normal | academy | q_00171 |
| 19 | normal | sponsors | q_00181 |
| 20 | normal | promotion-relegation | q_00191 |
| 21 | hard | birthday-birthplace | q_00201 |
| 22 | hard | pets-private | q_00211 |
| 23 | hard | hobbies-skills | q_00221 |
| 24 | hard | debut-first-goal | q_00231 |
| 25 | hard | goal-celebrations | q_00241 |
| 26 | hard | training-facilities | q_00251 |
| 27 | hard | supporter-culture | q_00261 |
| 28 | hard | player-relationships | q_00271 |
| 29 | hard | club-trivia | q_00281 |
| 30 | hard | historical-data | q_00291 |

各回で10問ずつ作成し、新しいチャットを開いて量産を始められます。
