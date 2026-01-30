import 'package:flutter/material.dart';

/// グロー効果付きボタンウィジェット
class GlowButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color glowColor;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double glowIntensity;

  const GlowButton({
    super.key,
    required this.child,
    this.onPressed,
    required this.glowColor,
    this.borderRadius = 16,
    this.padding,
    this.backgroundColor,
    this.foregroundColor,
    this.glowIntensity = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: glowIntensity),
            blurRadius: 15,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: child,
      ),
    );
  }
}
