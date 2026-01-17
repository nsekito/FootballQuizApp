# アプリ仕様書: Soccer Quiz Master

## 1. アプリ概要
サッカーの「知識」と「最新ニュース」の両方を楽しめるハイブリッド型クイズアプリ。
ユーザーが知識を深める「マスターモード」と、週明けの通勤時に試合結果を楽しく知る「ウィークリーモード」を提供する。
ポイントシステムとランク称号によりユーザーの継続率を高め、AdMobによる収益化を行う。

## 2. 技術スタック
- **Framework**: Flutter (Latest Stable)
- **Language**: Dart
- **State Management**: Flutter Riverpod (推奨)
- **Navigation**: GoRouter
- **Local Database**: SQLite (sqflite) or Drift - マスターデータおよび履歴用
- **Remote Data**: GitHub Raw / Firebase Storage - ニュースクイズ用JSON
- **Ads**: google_mobile_ads
- **Notifications**: flutter_local_notifications (更新通知用)

## 3. クイズモードとカテゴリ構成

### A. 【Killer Feature】Monday Match Recap (ウィークリー・マッチ・リキャップ)
- **概要**: 土日の試合結果を元にした時限式クイズ。毎週月曜朝に配信。
- **ターゲット**: 通勤・通学中のファン。ニュースを見る代わりにクイズで結果を知る。
- **出題内容**:
  - 勝敗 (例: 「昨日の大阪ダービー、制したのは？」)
  - 得点者 (例: 「後半ATに決勝ゴールを決めたのは？」)
  - 順位 (例: 「今節の結果、首位に浮上したのは？」)
- **システム**: サーバーからJSONを取得して表示。

### B. トレンド・ニュースクイズ (News)
- **概要**: 移籍市場、代表戦、大会情報などの時事クイズ。
- **フィルタ**: 地域 (国内 / 世界) × 年 (2025 / 2026...)

### C. マスターモード (常設クイズ)
条件を指定して挑戦するストック型クイズ。
1. **ルールクイズ**:
   - 難易度選択 (EASY, NORMAL, HARD, EXTREME)
2. **歴史クイズ**:
   - 地域選択 (日本 / 世界) -> 難易度選択
3. **チームクイズ**:
   - 国選択 (指定なし / 日本 / 伊 / 西 / 英)
   - 範囲選択 (J1全チーム / 海外Top3 / 指定なし)
     - *Logic*: 国で「日本」を選んだ場合、範囲は「J1」などが自動で候補になること。
   - 難易度選択

## 4. データ構造と生成・管理フロー

### データモデル (Question)

    class Question {
      final String id;
      final String text;          // 問題文
      final List<String> options; // 選択肢 (4択)
      final int answerIndex;      // 正解インデックス
      final String explanation;   // 解説 (正解理由 + 試合背景など詳細に)
      final String? trivia;       // 小ネタ・豆知識 (ユーザーの満足度向上用)
      final String category;      // rules, history, teams, match_recap, news
      final String difficulty;    // easy, normal, hard, extreme
      final String tags;          // 国名、リーグ名、年度など検索用タグ
    }

### 運用自動化システム (Admin Tools)
アプリ外でPythonスクリプトを使用し、データ作成を自動化する。

1. **Static Generator (常設クイズ用)**
   - Gemini APIを使用。「解説」と「豆知識」を必ず含めるプロンプトでJSON生成。
   - 生成後、SQLite DBに変換してアプリに同梱。
2. **Weekly Recap Generator (月曜クイズ用)**
   - Football API等から正確な試合結果データを取得。
   - 事実データ(Fact)をGeminiに渡し、ハルシネーションを防ぎつつクイズ文面を生成。

## 5. 画面遷移 (UI Flow)
1. **Home Screen**
   - 上部: **Weekly Challenge Card** (未プレイ時のみ強調表示)
   - 中部: 「現在のランク称号」と「所持GP」の表示
   - 下部: カテゴリ選択 (ルール / 歴史 / チーム / ニュース)
   - 最下部: バナー広告
2. **Configuration Screen**
   - カテゴリに応じた条件設定 (ドロップダウン/チップUI)
   - 「START」ボタン
3. **Quiz Screen**
   - 問題文、4択ボタン
   - 正解/不正解アニメーション
   - **解説ダイアログ**: 正誤にかかわらず表示。「解説」と「豆知識」を読ませる。
4. **Result Screen**
   - スコア表示、獲得GP表示、ランクアップ演出
   - **インタースティシャル広告** (結果表示の直前に挿入)

## 6. ゲーミフィケーションと収益化 (Economy)

### A. ポイントシステム (GP: Goal Points)
ユーザーのモチベーション維持のためのスコアシステム。
- **獲得**:
  - クイズ正解: +10 GP
  - 全問正解ボーナス: +50 GP
  - **動画広告視聴 (Reward Ad): +100 GP** (ホーム画面やリザルト画面から任意で視聴)

### B. ランク称号システム (User Rank)
累計GPに応じて称号が変化する。ガチャ機能は廃止し、このランク上げをメインの目的とする。
- **ランク一覧**:
  - 0 ~ 499 GP: **Academy (アカデミー生)**
  - 500 ~ 1999 GP: **Rookie (ルーキー)**
  - 2000 ~ 4999 GP: **Regular (レギュラー)**
  - 5000 ~ 9999 GP: **Fantasista (ファンタジスタ)**
  - 10000+ GP: **Legend (レジェンド)**
- **実装**: ローカルDB等で累計ポイントを保存・管理。

### C. 広告配置計画
1. **Banner Ad**: 各画面下部に常設。
2. **Interstitial Ad**: リザルト画面遷移時（頻度調整可能に）。
3. **Rewarded Ad**: 「ポイントをブーストして早くランクアップしたい」ユーザー向け。

## 7. 実装フェーズと進捗状況

### Phase 1 (Data) ✅ **完了**
- ✅ Pythonスクリプトによるデータ生成パイプラインの構築
  - Gemini APIを使用した問題生成スクリプト (`scripts/generate_static_questions.py`)
  - 問題の多様性確保機能（テーマ重複回避、カテゴリ別分散）
  - JSONからSQLite DBへの変換スクリプト (`scripts/json_to_db.py`)
  - 問題分布分析スクリプト (`scripts/analyze_question_distribution.py`)
- ✅ データモデル実装 (`lib/models/question.dart`)
- ✅ カテゴリ: rules, history, teams (各カテゴリ × 4難易度 × 50問 = 600問)

### Phase 2 (App Base) ✅ **完了**
- ✅ Flutterプロジェクト構築
- ✅ GoRouterによる画面遷移実装 (`lib/providers/router_provider.dart`)
- ✅ SQLite読み込み実装 (`lib/services/database_service.dart`)
- ✅ 画面実装:
  - `home_screen.dart` - ホーム画面（ランク表示、カテゴリ選択）
  - `configuration_screen.dart` - 設定画面（カテゴリ・難易度選択）
  - `quiz_screen.dart` - クイズ画面（問題表示、解説ダイアログ）
  - `result_screen.dart` - 結果画面（スコア、獲得GP表示）
  - `history_screen.dart` - 履歴画面
  - `statistics_screen.dart` - 統計画面

### Phase 3 (Logic) ✅ **完了**
- ✅ クイズ出題ロジック実装
  - 問題取得最適化 (`getQuestionsOptimized`)
  - テーマ多様性確保機能（出題時のテーマ重複回避）
  - 難易度バランス調整機能
- ✅ ポイント/ランク管理機能実装
  - ポイントシステム (`lib/utils/constants.dart`)
  - ランク称号システム (`lib/models/user_rank.dart`)
  - ユーザーデータ管理 (`lib/providers/user_data_provider.dart`)
- ✅ クイズ履歴管理 (`lib/services/quiz_history_service.dart`)

### Phase 4 (Online) ❌ **未実装**
- ❌ Weekly Recap機能 (HTTP通信)
- ❌ ニュースクイズ機能
- ❌ リモートデータ取得機能

### Phase 5 (Polish) ❌ **未実装**
- ❌ 広告実装 (google_mobile_ads)
  - Banner Ad
  - Interstitial Ad
  - Rewarded Ad
- ❌ 通知機能 (flutter_local_notifications)
- ❌ UIデザイン調整

## 8. 現在の実装状況サマリー

### 実装済み機能
- ✅ マスターモード（常設クイズ）の完全実装
  - ルールクイズ、歴史クイズ、チームクイズ
  - 難易度選択（EASY, NORMAL, HARD, EXTREME）
  - 問題の多様性確保（生成時・出題時の両方）
- ✅ ポイントシステムとランク称号システム
- ✅ クイズ履歴と統計機能
- ✅ データ生成パイプライン（Pythonスクリプト）

### 未実装機能
- ❌ Weekly Match Recap（月曜クイズ）
- ❌ ニュースクイズ
- ❌ 広告機能
- ❌ プッシュ通知

### 技術的な改善点
- ✅ 問題生成時のテーマ多様性確保（`gemini_client.py`）
- ✅ 出題時のテーマ重複回避（`database_service.dart`）
- ✅ 問題分布分析ツール
- ✅ Webプラットフォーム対応（完了）
  - 目的: 開発時の動作確認を高速化するため（`flutter run -d chrome`）
  - 本番リリースはモバイル端末のみを想定
  - 実装内容:
    - `sqflite_common_ffi_web`パッケージの追加（`pubspec.yaml`、バージョン: `^1.1.1`）
    - Web用データベースファクトリの初期化処理（`lib/main.dart`）
      - `databaseFactoryFfiWeb`を使用してWebプラットフォーム用のデータベースファクトリを設定
    - Webプラットフォーム用のデータベース初期化処理（`lib/services/database_service.dart`）
      - WebプラットフォームではIndexedDBを使用してデータベースを保存
      - アセットからデータベースファイル（`data/questions.db`）を読み込み、`writeDatabaseBytes`メソッドを使用してIndexedDBに書き込む
      - データベースが存在しない場合、または空の場合にアセットから自動的に読み込む
      - `writeDatabaseBytes`メソッドが存在しない場合のフォールバック処理を実装
    - 動作確認済み: Webブラウザで正常に問題が表示されることを確認