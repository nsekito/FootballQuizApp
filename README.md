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
3. エミュレータの起動（Androidエミュレータを使用する場合）:
   ```bash
   # 利用可能なエミュレータを確認
   flutter emulators
   
   # エミュレータを起動（例: Medium_Phone_API_36.1）
   flutter emulators --launch Medium_Phone_API_36.1
   ```
   
   エミュレータが起動するまで少し時間がかかります。起動後、以下のコマンドで利用可能なデバイスを確認できます：
   ```bash
   flutter devices
   ```
4. アプリを実行:
   ```bash
   # デバイスが1つのみの場合
   flutter run
   
   # 特定のデバイスを指定する場合
   flutter run -d <device_id>
   ```

## スクリプト

Pythonスクリプトの詳細は [scripts/README.md](scripts/README.md) を参照してください。

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
