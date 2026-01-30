import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// AppBarの背景パターンとオーバーレイを表示するウィジェット
class AppBarBackgroundWidget extends StatelessWidget {
  final Widget child;

  const AppBarBackgroundWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // カスタムペインターで描画した背景パターン
        CustomPaint(
          painter: _AppBarPatternPainter(
            color: Colors.white.withValues(alpha: 0.1),
          ),
          size: Size.infinite,
        ),
        // オーバーレイ
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.95),
                AppColors.primary,
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// AppBar用の背景パターンを描画するカスタムペインター
class _AppBarPatternPainter extends CustomPainter {
  final Color color;

  _AppBarPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 斜めの線パターン
    const spacing = 20.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // ドットパターンも追加
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    const dotSpacing = 30.0;
    for (double y = 0; y < size.height; y += dotSpacing) {
      for (double x = 0; x < size.width; x += dotSpacing) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// AppBarを背景付きで構築するヘルパー関数
PreferredSizeWidget buildAppBarWithBackground({
  required String title,
  List<Widget>? actions,
}) {
  return AppBar(
    title: Text(title),
    backgroundColor: Colors.transparent,
    elevation: 0,
    actions: actions,
    flexibleSpace: const AppBarBackgroundWidget(
      child: SizedBox.shrink(),
    ),
  );
}
