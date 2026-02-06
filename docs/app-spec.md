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
- **Remote Data**: GitHub Raw / Firebase Storage - Weekly Recap用JSON
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

### B. マスターモード (常設クイズ)
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
      final String category;      // rules, history, teams, match_recap
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
   - 上部: **Weekly Challenge Card (MATCH DAY)** (未プレイ時のみ強調表示)
   - 中部: 「現在のランク称号」と「所持GP」の表示
   - 下部: カテゴリ選択 (ルール / 歴史 / チーム)
   - 最下部: バナー広告
2. **Configuration Screen**
   - カテゴリに応じた条件設定 (ドロップダウン/チップUI)
   - 「START」ボタン
3. **Quiz Screen**
   - 問題文、4択ボタン
   - 正解/不正解アニメーション
   - **解説ダイアログ**: 正誤にかかわらず表示。「解説」と「豆知識」を読ませる。
4. **Result Screen**
   - スコア表示、獲得EXP・ポイント表示、ランクアップ演出
   - **リワード広告** (広告視聴でEXPとポイントを獲得)

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
2. **Rewarded Ad**: 「ポイントをブーストして早くランクアップしたい」ユーザー向け。
   - 結果画面: 広告視聴でEXPとポイントを獲得
   - MATCH DAY: 広告視聴で追加チャレンジ（週3回まで）

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

### Phase 4 (Online) ✅ **完了**
- ✅ Weekly Recap機能 (HTTP通信)
  - GitHub Rawからリモートデータ取得 (`lib/services/remote_data_service.dart`)
  - GitHub Actionsによる自動問題生成（毎週月曜日朝6時）
  - データ同期機能 (`lib/services/recap_data_service.dart`)
  - MATCH DAYのUI改善
    - プレイ回数の進捗表示（進捗バーと4つのドットインジケーター）
    - 残り回数の明確な表示
    - 上限到達時の週リセット情報表示（次回プレイ可能日、残り日数）
    - 報酬情報の改善（EXP ×5倍、ポイント ×5倍を明確に表示）
  - プレイ回数制限（週4回：無料1回 + 広告視聴3回）
  - 報酬倍率（EXP ×5倍、ポイント ×5倍）
- ✅ リモートデータ取得機能

### Phase 5 (Polish) 🔄 **部分的に完了**
- ✅ 広告実装 (google_mobile_ads)
  - Banner Ad: 各画面のフッターに実装済み (`lib/widgets/banner_ad_widget.dart`)
  - Rewarded Ad: 結果画面とMATCH DAYの追加チャレンジに実装済み (`lib/services/ad_service.dart`)
  - Interstitial Ad: 使用しない（離脱率が高いため）
- ✅ 通知機能 (flutter_local_notifications)
  - Weekly Recap新着通知機能 (`lib/services/notification_service.dart`)
  - 通知タップ時の画面遷移機能
  - 前回通知日時の保存・確認ロジック（重複防止）
- ❌ UIデザイン調整

## 8. 現在の実装状況サマリー

### 実装済み機能
- ✅ マスターモード（常設クイズ）の完全実装
  - ルールクイズ、歴史クイズ、チームクイズ
  - 難易度選択（EASY, NORMAL, HARD, EXTREME）
  - 問題の多様性確保（生成時・出題時の両方）
- ✅ Weekly Match Recap（MATCH DAY）
  - GitHub Actionsによる自動問題生成（毎週月曜日）
  - リモートデータ取得と同期機能
  - プレイ回数制限（週4回：無料1回 + 広告視聴3回）
  - 報酬倍率（EXP ×5倍、ポイント ×5倍）
  - UI改善（プレイ回数進捗表示、週リセット情報など）
- ✅ ポイントシステムとランク称号システム
- ✅ クイズ履歴と統計機能
- ✅ データ生成パイプライン（Pythonスクリプト）
- ✅ 広告機能
  - Banner Ad（各画面フッター）
  - Rewarded Ad（結果画面、MATCH DAY追加チャレンジ）
- ✅ プッシュ通知機能
  - Weekly Recap新着通知
  - 通知タップ時の画面遷移
- ✅ 昇格試験機能
  - 難易度アンロック機能
  - ポイント消費とクイズ合格によるアンロック

### 未実装機能
- ❌ UIデザイン調整

### 削除済み機能
- ❌ ニュースクイズ機能（削除済み）

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
- ✅ MATCH DAYのUI改善
  - プレイ回数の進捗表示（進捗バーと4つのドットインジケーター）
  - 残り回数の明確な表示
  - 上限到達時の週リセット情報表示（次回プレイ可能日、残り日数）
  - 報酬情報の改善（EXP ×5倍、ポイント ×5倍を明確に表示）
- ✅ 広告機能の実装
  - Banner AdとRewarded Adの実装
  - Webプラットフォーム対応（広告はスキップ）
  - 広告設定の一元管理（`lib/config/ad_config.dart`）
- ✅ プッシュ通知機能の実装
  - 通知サービスの実装（`lib/services/notification_service.dart`）
  - Weekly Recap新着通知の自動送信
  - 通知タップ時の画面遷移機能
  - 前回通知日時の保存・確認ロジック（重複防止）
- ✅ MATCH DAYのUI改善
  - プレイ回数の進捗表示（進捗バーと4つのドットインジケーター）
  - 残り回数の明確な表示
  - 上限到達時の週リセット情報表示（次回プレイ可能日、残り日数）
  - 報酬情報の改善（EXP ×5倍、ポイント ×5倍を明確に表示）
- ✅ 広告機能の実装
  - Banner AdとRewarded Adの実装
  - Webプラットフォーム対応（広告はスキップ）
  - 広告設定の一元管理（`lib/config/ad_config.dart`）
- ✅ プッシュ通知機能の実装
  - 通知サービスの実装（`lib/services/notification_service.dart`）
  - Weekly Recap新着通知の自動送信
  - 通知タップ時の画面遷移機能
  - 前回通知日時の保存・確認ロジック（重複防止）