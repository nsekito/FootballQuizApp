import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// グリッドパターンの背景を描画するウィジェット
class GridPatternBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double dotSize;
  final double spacing;

  const GridPatternBackground({
    super.key,
    required this.child,
    this.opacity = 0.4,
    this.dotSize = 1.0,
    this.spacing = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);

    return Stack(
      children: [
        // 背景色
        Container(
          color: isDark ? AppColors.stitchBackgroundDark : AppColors.stitchBackgroundLight,
        ),
        // グリッドパターン
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              painter: _GridPatternPainter(
                color: dotColor,
                dotSize: dotSize,
                spacing: spacing,
              ),
            ),
          ),
        ),
        // コンテンツ
        child,
      ],
    );
  }
}

/// グリッドパターンを描画するカスタムペインター
class _GridPatternPainter extends CustomPainter {
  final Color color;
  final double dotSize;
  final double spacing;

  _GridPatternPainter({
    required this.color,
    required this.dotSize,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // ラジアルグラデーションのドットパターンを描画
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(
          Offset(x, y),
          dotSize,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
