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

## 実装フェーズ

1. **Phase 1 (Data)**: Pythonスクリプトによるデータ生成パイプラインの構築
2. **Phase 2 (App Base)**: Flutterプロジェクト構築、画面遷移、SQLite読み込み実装
3. **Phase 3 (Logic)**: クイズ出題ロジック、ポイント/ランク管理機能の実装
4. **Phase 4 (Online)**: Weekly Recap機能 (HTTP通信) の実装
5. **Phase 5 (Polish)**: 広告実装、UIデザイン調整

詳細な仕様は [docs/app-spec.md](docs/app-spec.md) を参照してください。
