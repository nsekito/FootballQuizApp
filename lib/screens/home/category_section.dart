import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

/// ホーム画面のカテゴリ選択セクション。
class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'SELECT QUIZ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.techIndigo.withValues(alpha: 0.4),
              letterSpacing: 1.2,
            ),
          ),
        ),
        CategoryButton(
          title: 'ルールクイズ',
          subtitle: '基本からマニアックな規定まで',
          icon: Icons.gavel,
          iconBgColor: Colors.blue,
          iconColor: AppColors.techBlue,
          onTap: () => context.push('/configuration?category=${AppConstants.categoryRules}'),
        ),
        const SizedBox(height: 12),
        CategoryButton(
          title: '歴史クイズ',
          subtitle: '伝説のプレーヤーと大会の記録',
          icon: Icons.auto_stories,
          iconBgColor: Colors.amber,
          iconColor: Colors.amber.shade500,
          onTap: () => context.push('/configuration?category=${AppConstants.categoryHistory}'),
        ),
        const SizedBox(height: 12),
        CategoryButton(
          title: 'チームクイズ',
          subtitle: '欧州・国内リーグのクラブ知識',
          icon: Icons.groups,
          iconBgColor: Colors.purple,
          iconColor: Colors.purple.shade500,
          onTap: () => context.push('/configuration?category=${AppConstants.categoryTeams}'),
        ),
      ],
    );
  }
}

/// カテゴリ選択のタップ可能なボタン。
class CategoryButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<CategoryButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.techGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isHovered
                    ? widget.iconColor
                    : widget.iconBgColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                    color: widget.iconColor.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: _isHovered ? Colors.white : widget.iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.techIndigo,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.slate200,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
