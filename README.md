# Soccer Quiz Master

AI-powered soccer quiz app with weekly match recap and master mode quizzes.

## 概要

サッカーの「知識」と「最新ニュース」の両方を楽しめるハイブリッド型クイズアプリ。
ユーザーが知識を深める「マスターモード」と、週明けの通勤時に試合結果を楽しく知る「ウィークリーモード」を提供します。

## 技術スタック

- **Framework**: Flutter (Latest Stable)
- **Language**: Dart
- **State Management**: Flutter Riverpod
- **Navigation**: GoRouter
- **Local Database**: SQLite (sqflite)
- **Remote Data**: HTTP (GitHub Raw / Firebase Storage)
- **Ads**: google_mobile_ads
- **Notifications**: flutter_local_notifications

## プロジェクト構造

```
lib/
├── main.dart              # アプリエントリーポイント
├── models/                # データモデル
│   ├── question.dart      # クイズ問題モデル
│   └── user_rank.dart     # ユーザーランクモデル
├── screens/               # 画面ウィジェット
├── providers/             # Riverpodプロバイダー
├── services/              # ビジネスロジック・サービス層
├── utils/                 # ユーティリティ・定数
│   └── constants.dart     # アプリ定数
└── widgets/               # 再利用可能なウィジェット
```

## セットアップ

1. Flutter SDKをインストール（`C:\src\flutter`に配置）
2. 依存関係をインストール:
   ```bash
   flutter pub get
   ```
3. アプリを実行:
   ```bash
   flutter run
   ```

## 問題生成（Pythonスクリプト）

### venv環境の準備

```powershell
cd scripts
py -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 問題生成コマンド

**すべてのカテゴリ・難易度を生成（合計600問）:**
```powershell
python generate_static_questions.py
```

**テストモード（各難易度5問のみ）:**
```powershell
python generate_static_questions.py --test
```

**特定のカテゴリのみ生成:**
```powershell
# ルールクイズ（合計200問: easy/normal/hard/extreme × 50問）
python generate_static_questions.py --category rules

# 歴史クイズ（合計200問）
python generate_static_questions.py --category history

# チームクイズ（合計200問）
python generate_static_questions.py --category teams
```

**特定の難易度のみ生成:**
```powershell
python generate_static_questions.py --difficulty easy
python generate_static_questions.py --difficulty normal
python generate_static_questions.py --difficulty hard
python generate_static_questions.py --difficulty extreme
```

**カスタム生成数:**
```powershell
# 各難易度10問ずつ（合計40問）
python generate_static_questions.py --category rules --count 10
```

### JSONからデータベースへの変換

```powershell
# データベーススキーマを作成して変換（既存DBを削除した場合）
python json_to_db.py generated/all_questions_YYYYMMDD_HHMMSS.json --create-schema

# 既存のデータベースに追加（既存の問題は置き換え）
python json_to_db.py generated/all_questions_YYYYMMDD_HHMMSS.json --replace
```

### 問題分布の確認

```powershell
# データベース内の問題分布を分析
python analyze_question_distribution.py

# データベースの内容を確認
python check_db.py
```

詳細は [scripts/README.md](scripts/README.md) を参照してください。

## リモートデータ設定（Phase 4）

### GitHub Rawの設定

アプリがリモートデータ（Weekly Recap、ニュースクイズ）を取得するには、GitHubリポジトリの設定が必要です。

1. **GitHubリポジトリの準備**
   - リポジトリを公開（Public）にする必要があります
   - または、GitHub Personal Access Tokenを使用してPrivateリポジトリにもアクセス可能（実装が必要）

2. **定数の設定**
   `lib/utils/constants.dart` の以下の定数を実際の値に変更してください：
   ```dart
   static const String githubRepoOwner = 'your-username'; // GitHubユーザー名
   static const String githubRepoName = 'FootballQuizApp'; // リポジトリ名
   static const String githubBranch = 'main'; // ブランチ名
   ```

3. **データファイルの配置**
   - Weekly Recap: `data/weekly_recap/YYYY-MM-DD.json`
   - ニュースクイズ: `data/news/YYYY/domestic.json` または `data/news/YYYY/world.json`
   
   詳細は各ディレクトリの `README.md` を参照してください。

4. **データの取得URL**
   GitHub Raw URLの形式：
   ```
   https://raw.githubusercontent.com/{OWNER}/{REPO}/{BRANCH}/data/{PATH}
   ```
   
   例：
   - Weekly Recap: `https://raw.githubusercontent.com/your-username/FootballQuizApp/main/data/weekly_recap/2025-01-13.json`
   - ニュースクイズ: `https://raw.githubusercontent.com/your-username/FootballQuizApp/main/data/news/2025/domestic.json`

### テスト用データ

テスト用のサンプルデータが `data/` ディレクトリに含まれています：
- `data/weekly_recap/2025-01-13.json` - Weekly Recapのサンプル
- `data/news/2025/domestic.json` - ニュースクイズのサンプル

これらのファイルをGitHubリポジトリにコミット・プッシュすると、アプリからアクセス可能になります。

## 実装フェーズ

1. **Phase 1 (Data)**: Pythonスクリプトによるデータ生成パイプラインの構築
2. **Phase 2 (App Base)**: Flutterプロジェクト構築、画面遷移、SQLite読み込み実装
3. **Phase 3 (Logic)**: クイズ出題ロジック、ポイント/ランク管理機能の実装
4. **Phase 4 (Online)**: Weekly Recap機能 (HTTP通信) の実装
5. **Phase 5 (Polish)**: 広告実装、UIデザイン調整

詳細な仕様は [docs/app-spec.md](docs/app-spec.md) を参照してください。
