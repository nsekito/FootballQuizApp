import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// アプリ全体で使用する背景パターンウィジェット
class AppBackgroundWidget extends StatelessWidget {
  final Widget child;
  final double opacity;

  const AppBackgroundWidget({
    super.key,
    required this.child,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景色
        Container(
          color: AppColors.background,
        ),
        // カスタムペインターで描画した背景パターン
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              painter: _BackgroundPatternPainter(
                color: AppColors.primary.withValues(alpha: 0.05),
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

/// 背景パターンを描画するカスタムペインター
class _BackgroundPatternPainter extends CustomPainter {
  final Color color;

  _BackgroundPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 斜めの線パターン（サッカーフィールド風）
    const spacing = 30.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // ドットパターンも追加
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    const dotSpacing = 25.0;
    for (double y = 0; y < size.height; y += dotSpacing) {
      for (double x = 0; x < size.width; x += dotSpacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
