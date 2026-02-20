# アプリアイコン設定

このディレクトリには、アプリのランチャーアイコン用の元画像を配置します。

## 必要なファイル

- `app_icon.png` - 1024x1024ピクセルのPNG画像

## アイコンの要件

- **サイズ**: 1024x1024ピクセル（正方形）
- **形式**: PNG形式
- **背景**: 不透明推奨（Androidで一部のランチャーで透明背景が問題になる可能性があります）
- **デザイン**: 
  - iOSのアイコンは自動的に角丸になるため、四隅に重要な要素を配置しないでください
  - Androidは10%の余白を含めることを推奨します
  - 高品質な画像を使用してください

## アイコンの生成方法

1. `app_icon.png`をこのディレクトリに配置します
2. 以下のコマンドを実行します：
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

これにより、AndroidとiOS用のすべてのサイズのアイコンが自動生成されます。

## 生成されるアイコンのサイズ

### Android
- mipmap-mdpi: 48x48px
- mipmap-hdpi: 72x72px
- mipmap-xhdpi: 96x96px
- mipmap-xxhdpi: 144x144px
- mipmap-xxxhdpi: 192x192px

### iOS
- 20x20@2x (40x40px)
- 20x20@3x (60x60px)
- 29x29@1x (29x29px)
- 29x29@2x (58x58px)
- 29x29@3x (87x87px)
- 40x40@2x (80x80px)
- 40x40@3x (120x120px)
- 60x60@2x (120x120px)
- 60x60@3x (180x180px)
- 1024x1024@1x (1024x1024px) - App Store用
- iPad用のサイズも自動生成されます
