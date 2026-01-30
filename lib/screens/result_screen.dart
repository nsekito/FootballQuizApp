import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/user_data_provider.dart';
import '../providers/quiz_history_provider.dart';
import '../models/user_rank.dart';
import '../constants/app_colors.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/glow_button.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final int score;
  final int total;
  final int earnedPoints;
  final String category;
  final String difficulty;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.earnedPoints,
    required this.category,
    required this.difficulty,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with SingleTickerProviderStateMixin {
  UserRank? _previousRank;
  UserRank? _currentRank;
  bool _rankUp = false;
  late AnimationController _animationController;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    _checkRankUp();
    _addPoints();
    _saveHistory();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkRankUp() {
    final totalPoints = ref.read(totalPointsProvider);
    _previousRank = UserRank.fromPoints(totalPoints);
    _currentRank = UserRank.fromPoints(totalPoints + widget.earnedPoints);
    _rankUp = _previousRank != _currentRank;
  }

  Future<void> _addPoints() async {
    await ref.read(totalPointsProvider.notifier).addPoints(widget.earnedPoints);
    setState(() {
      _currentRank = ref.read(userRankProvider);
    });
  }

  Future<void> _saveHistory() async {
    try {
      final historyService = ref.read(quizHistoryServiceProvider);
      final history = QuizHistory(
        category: widget.category,
        difficulty: widget.difficulty,
        score: widget.score,
        total: widget.total,
        earnedPoints: widget.earnedPoints,
        completedAt: DateTime.now(),
      );
      await historyService.saveHistory(history);

      ref.invalidate(quizHistoryListProvider);
      ref.invalidate(quizStatisticsProvider);
    } catch (e) {
      debugPrint('履歴の保存に失敗しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('履歴の保存に失敗しましたが、クイズ結果は正常に記録されました。'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.total > 0 ? (widget.score / widget.total * 100) : 0.0;
    final totalPoints = ref.watch(totalPointsProvider);

    return Scaffold(
      backgroundColor: AppColors.stitchBackgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.stitchEmerald.withValues(alpha: 0.9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '結果',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: GridPatternBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // スコア表示
              GlassMorphismWidget(
                borderRadius: 24,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: widget.score.toDouble()),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedScore, child) {
                        return Text(
                          '${animatedScore.toInt()}',
                          style: const TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: AppColors.stitchEmerald,
                            letterSpacing: -2,
                          ),
                        );
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          ' / ${widget.total}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '正答率: ${accuracy.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 獲得ポイント表示
              GlassMorphismWidget(
                borderRadius: 16,
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '獲得ポイント',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0.0,
                            end: widget.earnedPoints.toDouble(),
                          ),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedPoints, child) {
                            return Text(
                              '+${animatedPoints.toInt()} GP',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.stitchEmerald,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade400.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ランクアップ演出
              if (_rankUp && _currentRank != null) ...[
                AnimatedOpacity(
                  opacity: _showContent ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedScale(
                    scale: _showContent ? 1.0 : 0.8,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                    child: GlassMorphismWidget(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(32),
                      backgroundColor: Colors.amber.shade50.withValues(alpha: 0.6),
                      child: Column(
                        children: [
                          AnimatedRotation(
                            turns: _showContent ? 0.0 : 0.5,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            child: _RankBadgeWidget(
                              rank: _currentRank!,
                              size: 100,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'ランクアップ！',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_previousRank?.japaneseName} → ${_currentRank?.japaneseName}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 現在のランク表示
              GlassMorphismWidget(
                borderRadius: 24,
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Text(
                      '現在のランク',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_currentRank != null)
                      _RankBadgeWidget(
                        rank: _currentRank!,
                        size: 128,
                      ),
                    const SizedBox(height: 24),
                    Text(
                      _currentRank?.japaneseName ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentRank?.englishName ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.stitchEmerald.withValues(alpha: 0.1),
                        borderRadius: const BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Text(
                        '累計: ${NumberFormat('#,###').format(totalPoints)} GP',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.stitchEmerald,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ホームに戻るボタン
              GlowButton(
                glowColor: AppColors.stitchEmerald,
                onPressed: () => context.go('/'),
                backgroundColor: AppColors.stitchEmerald,
                foregroundColor: Colors.white,
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ホームに戻る',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // もう一度挑戦ボタン
              OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(
                    color: AppColors.stitchEmerald,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'もう一度挑戦',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ランクバッジを表示するウィジェット
class _RankBadgeWidget extends StatelessWidget {
  final UserRank rank;
  final double size;

  const _RankBadgeWidget({
    required this.rank,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData iconData;

    switch (rank) {
      case UserRank.academy:
        badgeColor = Colors.grey.shade400;
        iconData = Icons.school;
        break;
      case UserRank.rookie:
        badgeColor = Colors.blue.shade400;
        iconData = Icons.star;
        break;
      case UserRank.regular:
        badgeColor = Colors.green.shade400;
        iconData = Icons.emoji_events;
        break;
      case UserRank.fantasista:
        badgeColor = Colors.amber.shade400;
        iconData = Icons.auto_awesome;
        break;
      case UserRank.legend:
        badgeColor = Colors.purple.shade400;
        iconData = Icons.workspace_premium;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            badgeColor,
            badgeColor.withValues(alpha: 0.7),
            badgeColor.withValues(alpha: 0.5),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}
