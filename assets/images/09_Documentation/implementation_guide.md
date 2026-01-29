# SoccerQuiz アプリ 実装ガイド

**作成日:** 2026年1月20日  
**バージョン:** 1.0  
**対象:** Flutter + Cursor 開発環境

このガイドは、AI Driveからダウンロードした素材をFlutterプロジェクトに組み込むための詳細な手順書です。

---

## 📥 ダウンロードリンク

**全素材一括ダウンロード:**  
https://www.genspark.ai/aidrive/files/SoccerQuiz_Assets

**フォルダ別ダウンロード:**
- アイコン: https://www.genspark.ai/aidrive/files/SoccerQuiz_Assets/01_Icons
- ボタン: https://www.genspark.ai/aidrive/files/SoccerQuiz_Assets/02_Buttons
- 背景: https://www.genspark.ai/aidrive/files/SoccerQuiz_Assets/03_Backgrounds
- カード: https://www.genspark.ai/aidrive/files/SoccerQuiz_Assets/04_Cards
- バッジ: https://www.genspark.ai/aidrive/files/SoccerQuiz_Assets/05_Badges
- ランク: https://www.genspark.ai/aidrive/files/SoccerQuiz_Assets/06_Ranks
- 状態: https://www.genspark.ai/aidrive/files/SoccerQuiz_Assets/07_States
- アプリ: https://www.genspark.ai/aidrive/files/SoccerQuiz_Assets/08_App

---

## 🎨 カラーパレット（コピペ用）

```dart
// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // メインカラー
  static const primary = Color(0xFF4A7C59);        // 深い緑
  static const accent = Color(0xFFF5A623);         // ゴールド
  static const background = Color(0xFFF5F3EF);     // オフホワイト
  static const textDark = Color(0xFF2C2C2C);       // 濃いグレー
  static const textLight = Color(0xFF808080);      // 薄いグレー

  // カテゴリ別カラー
  static const categoryRules = Color(0xFFE3F2FD);  // 淡い青
  static const categoryHistory = Color(0xFFFFF9E6); // 淡い黄色
  static const categoryTeam = Color(0xFFF3E5F5);   // 淡い紫
  static const categoryNews = Color(0xFFFFF3E0);   // 淡いオレンジ

  // 難易度別カラー
  static const difficultyEasy = Color(0xFF81C784);    // 明るい緑
  static const difficultyNormal = Color(0xFF42A5F5);  // ブルー
  static const difficultyHard = Color(0xFFFFA726);    // オレンジ
  static const difficultyExtreme = Color(0xFFE53935); // 赤

  // 状態カラー
  static const success = Color(0xFF4CAF50);  // 正解
  static const error = Color(0xFFD32F2F);    // 不正解
  static const selected = Color(0xFFE8F5E9); // 選択中
}
```

---

## ⚙️ pubspec.yaml 設定

```yaml
name: soccer_quiz
description: サッカークイズアプリ

flutter:
  assets:
    - assets/icons/
    - assets/buttons/
    - assets/backgrounds/
    - assets/cards/
    - assets/badges/
    - assets/ranks/
    - assets/states/
    - assets/app/

  fonts:
    - family: NotoSansJP
      fonts:
        - asset: fonts/NotoSansJP-Regular.ttf
        - asset: fonts/NotoSansJP-Bold.ttf
          weight: 700

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.5

# アプリアイコン自動生成設定
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/app/app_icon.png"
  adaptive_icon_background: "#4A7C59"
  adaptive_icon_foreground: "assets/app/app_icon.png"

# スプラッシュ画面自動生成設定
flutter_native_splash:
  color: "#4A7C59"
  image: assets/app/splash_screen.png
  android: true
  ios: true
```

---

## 📱 実装例

### 1. ボタンの実装

```dart
// Primaryボタン
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
  ),
  onPressed: () {
    // ボタンの処理
  },
  child: Text('チャレンジする', 
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
)
```

### 2. ヘッダー背景の実装

```dart
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/backgrounds/header_background_pattern.png'),
      repeat: ImageRepeat.repeat,
    ),
  ),
  child: AppBar(
    title: Text('Soccer Quiz'),
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
)
```

### 3. クイズ選択肢カードの実装

```dart
class QuizChoiceCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback onTap;

  const QuizChoiceCard({
    required this.text,
    required this.isSelected,
    this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    IconData? icon;
    Color? iconColor;

    if (isCorrect == true) {
      backgroundColor = Color(0xFFC8E6C9);
      borderColor = AppColors.primary;
      icon = Icons.check_circle;
      iconColor = AppColors.success;
    } else if (isCorrect == false) {
      backgroundColor = Color(0xFFFFCDD2);
      borderColor = Color(0xFFD32F2F);
      icon = Icons.cancel;
      iconColor = AppColors.error;
    } else if (isSelected) {
      backgroundColor = Color(0xFFE8F5E9);
      borderColor = AppColors.primary;
    } else {
      backgroundColor = AppColors.background;
      borderColor = Colors.grey[300]!;
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected || isCorrect != null
            ? [BoxShadow(color: borderColor.withOpacity(0.3), 
                blurRadius: 8, offset: Offset(0, 4))]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCorrect == null ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                if (icon != null) Icon(icon, color: iconColor, size: 32),
                if (icon != null) SizedBox(width: 12),
                Expanded(
                  child: Text(text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                if (isCorrect == true)
                  Icon(Icons.star, color: AppColors.accent, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 🔧 アプリアイコン・スプラッシュ設定

### 自動生成コマンド

```bash
# パッケージ取得
flutter pub get

# アプリアイコン生成
flutter pub run flutter_launcher_icons

# スプラッシュ画面生成
flutter pub run flutter_native_splash:create

# クリーン＆ビルド
flutter clean
flutter pub get
flutter run
```

---

## ⚠️ 切り出しが必要な素材

以下の素材は複数の要素が1枚にまとめられているため、実装前に個別画像に切り出してください:

1. **icon_set_16_grid.png** → 16個のアイコン（各128x128px）
2. **badges_set1_category.png** → 4個のバッジ
3. **badges_set2_achievement.png** → 4個のバッジ
4. **quiz_choice_cards_4states.png** → 4状態
5. **statistics_summary_cards.png** → 4種類のカード
6. **loading_animation_sprite.png** → 4フレーム

**推奨ツール:** Figma、Photoshop、または以下のPythonスクリプト

```python
from PIL import Image

# 16アイコングリッドを切り出し
img = Image.open('icon_set_16_grid.png')
width, height = img.size
icon_size = width // 4

icon_names = [
    'whistle', 'trophy', 'jersey', 'calendar',
    'clock', 'chart', 'check', 'cross',
    'star', 'shield', 'flag', 'play',
    'bulb', 'calendar_ball', 'arrow_left', 'close'
]

for i in range(16):
    row = i // 4
    col = i % 4
    left = col * icon_size
    top = row * icon_size
    right = left + icon_size
    bottom = top + icon_size
    
    icon = img.crop((left, top, right, bottom))
    icon.save(f'icon_{icon_names[i]}.png')
```

---

## 📖 追加リソース

- **Flutter公式ドキュメント:** https://flutter.dev/docs
- **カラーパレットジェネレーター:** https://coolors.co/
- **画像圧縮:** https://tinypng.com/
- **Googleフォント（Noto Sans JP）:** https://fonts.google.com/noto/specimen/Noto+Sans+JP

---

## ✅ チェックリスト

実装時のチェック項目:

- [ ] 全素材をダウンロード済み
- [ ] assetsフォルダに配置済み
- [ ] pubspec.yamlを設定済み
- [ ] app_colors.dartを作成済み
- [ ] グリッド画像を切り出し済み
- [ ] アプリアイコンを設定済み
- [ ] スプラッシュ画面を設定済み
- [ ] 実機で動作確認済み

---

## 🚀 次のステップ

1. **素材のダウンロード** - AI Driveから全素材を取得
2. **Flutterプロジェクトに配置** - assetsフォルダへ
3. **pubspec.yaml設定** - assets、fonts、アイコン設定
4. **カラーパレット定義** - app_colors.dart作成
5. **画面実装** - Cursorで各画面を作成
6. **テスト** - 実機で確認

---

**頑張ってください！⚽✨**

**作成:** AI Assistant  
**最終更新:** 2026年1月20日
