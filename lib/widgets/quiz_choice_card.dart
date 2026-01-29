import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class QuizChoiceCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback onTap;

  const QuizChoiceCard({
    super.key,
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
      backgroundColor = const Color(0xFFC8E6C9);
      borderColor = AppColors.primary;
      icon = Icons.check_circle;
      iconColor = AppColors.success;
    } else if (isCorrect == false) {
      backgroundColor = const Color(0xFFFFCDD2);
      borderColor = AppColors.error;
      icon = Icons.cancel;
      iconColor = AppColors.error;
    } else if (isSelected) {
      backgroundColor = AppColors.selected;
      borderColor = AppColors.primary;
    } else {
      backgroundColor = AppColors.background;
      borderColor = Colors.grey.shade300;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected || isCorrect != null
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCorrect == null ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (icon != null) Icon(icon, color: iconColor, size: 32),
                if (icon != null) const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
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
