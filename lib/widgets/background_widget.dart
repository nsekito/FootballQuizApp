import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// アプリ全体で使用する背景画像ウィジェット
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
        // 背景画像
        Positioned.fill(
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              'assets/images/03_Backgrounds/header_background_pattern.png',
              repeat: ImageRepeat.repeat,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        // コンテンツ
        child,
      ],
    );
  }
}
