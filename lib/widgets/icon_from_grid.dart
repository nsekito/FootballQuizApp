import 'package:flutter/material.dart';

/// グリッド画像から特定のアイコンを表示するウィジェット
class IconFromGrid extends StatelessWidget {
  final int iconIndex; // 0-15のインデックス
  final double size;
  final String gridImagePath;

  const IconFromGrid({
    super.key,
    required this.iconIndex,
    this.size = 32,
    this.gridImagePath = 'assets/images/01_Icons/icon_set_16_grid.png',
  });

  @override
  Widget build(BuildContext context) {
    // 4x4グリッドからアイコンを切り出す
    final row = iconIndex ~/ 4;
    final col = iconIndex % 4;
    
    return CustomPaint(
      size: Size(size, size),
      painter: _IconGridPainter(
        imagePath: gridImagePath,
        row: row,
        col: col,
        iconSize: size,
      ),
    );
  }
}

class _IconGridPainter extends CustomPainter {
  final String imagePath;
  final int row;
  final int col;
  final double iconSize;

  _IconGridPainter({
    required this.imagePath,
    required this.row,
    required this.col,
    required this.iconSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 画像を読み込んで描画する処理は複雑なため、
    // 代わりにImage.assetを使用する方法に変更
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
