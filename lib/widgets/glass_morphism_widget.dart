import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// ガラスモーフィズム効果を持つコンテナウィジェット
class GlassMorphismWidget extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  final List<BoxShadow>? boxShadow;

  const GlassMorphismWidget({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.backgroundColor,
    this.borderColor,
    this.blurSigma = 12,
    this.padding,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.stitchCardDark : AppColors.stitchCardLight);
    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.2));

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: border,
              width: 1,
            ),
            boxShadow: boxShadow ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
