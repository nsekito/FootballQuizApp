import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class QuizChoiceCard extends StatefulWidget {
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
  State<QuizChoiceCard> createState() => _QuizChoiceCardState();
}

class _QuizChoiceCardState extends State<QuizChoiceCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shakeController;
  late AnimationController _particleController;
  bool _isPressed = false;
  bool _showParticles = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _shakeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(QuizChoiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 正解が表示されたときに回転アニメーションとパーティクル
    if (widget.isCorrect == true && oldWidget.isCorrect != true) {
      _controller.forward(from: 0);
      setState(() => _showParticles = true);
      _particleController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _showParticles = false);
        }
      });
    }
    // 不正解が表示されたときにシェイクアニメーション
    if (widget.isCorrect == false && oldWidget.isCorrect != false) {
      _shakeController.forward(from: 0);
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isCorrect == null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    IconData? icon;
    Color? iconColor;

    if (widget.isCorrect == true) {
      backgroundColor = const Color(0xFFC8E6C9);
      borderColor = AppColors.primary;
      icon = Icons.check_circle;
      iconColor = AppColors.success;
    } else if (widget.isCorrect == false) {
      backgroundColor = const Color(0xFFFFCDD2);
      borderColor = AppColors.error;
      icon = Icons.cancel;
      iconColor = AppColors.error;
    } else if (widget.isSelected) {
      backgroundColor = AppColors.selected;
      borderColor = AppColors.primary;
    } else {
      backgroundColor = AppColors.background;
      borderColor = Colors.grey.shade300;
    }

    // タップ時のスケール効果
    final scale = _isPressed ? 0.97 : 1.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // メインカード
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            // シェイクアニメーション（不正解時）
            final shakeOffset = widget.isCorrect == false
                ? 10.0 * math.sin(_shakeController.value * 2 * math.pi * 5)
                : 0.0;

            return Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 100),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    border: Border.all(color: borderColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: widget.isSelected || widget.isCorrect != null
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
                      onTap: widget.isCorrect == null ? widget.onTap : null,
                      onTapDown: _handleTapDown,
                      onTapUp: _handleTapUp,
                      onTapCancel: _handleTapCancel,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // 正解時の回転アニメーション付きアイコン
                            if (icon != null)
                              AnimatedRotation(
                                turns: widget.isCorrect == true ? 0.25 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.elasticOut,
                                child: Icon(icon, color: iconColor, size: 32),
                              ),
                            if (icon != null) const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: widget.isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ),
                            if (widget.isCorrect == true)
                              AnimatedOpacity(
                                opacity: widget.isCorrect == true ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(Icons.star,
                                    color: AppColors.accent, size: 24),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // パーティクル効果（正解時）
        if (_showParticles && widget.isCorrect == true)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _particleController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ParticlePainter(
                      progress: _particleController.value,
                      color: AppColors.success,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// パーティクル効果を描画するカスタムペインター
class _ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 1.0 - progress)
      ..style = PaintingStyle.fill;

    // パーティクルの数を定義
    const particleCount = 12;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi) / particleCount;
      final distance = progress * 50;
      final x = centerX + distance * math.cos(angle);
      final y = centerY + distance * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        4 * (1 - progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
