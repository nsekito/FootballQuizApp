import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_data_provider.dart';
import '../providers/quiz_history_provider.dart';
import '../models/user_rank.dart';
import '../constants/app_colors.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/glow_button.dart';
import '../widgets/responsive_container.dart';
import '../widgets/banner_ad_widget.dart';
import '../constants/game_config.dart';
import '../utils/rewarded_ad_helper.dart';
import '../providers/sound_service_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final int score;
  final int total;
  final int earnedExp;
  final int earnedPoints;
  final String category;
  final String difficulty;
  final bool isMatchDay;
  final bool isDailyQuiz;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.earnedExp,
    required this.earnedPoints,
    required this.category,
    required this.difficulty,
    this.isMatchDay = false,
    this.isDailyQuiz = false,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen>
    with TickerProviderStateMixin {
  UserRank? _previousRank;
  UserRank? _currentRank;
  bool _rankUp = false;
  late AnimationController _animationController;
  late AnimationController _rankUpAnimationController;
  late AnimationController _bounceAnimationController;
  late AnimationController _sparkleAnimationController;
  late final RewardedAdHelper _adHelper;
  bool _rewardsClaimed = false;
  late final List<_ConfettiParticle> _confettiParticles;

  bool get _isPerfect => widget.score == widget.total && widget.total > 0;
  int get _earnedExp => widget.earnedExp;
  int get _earnedPoints => widget.earnedPoints;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(soundServiceProvider).playQuizResultScreen());
    });
    _adHelper = RewardedAdHelper(
      ref: ref,
      onStateChanged: () => setState(() {}),
      isMounted: () => mounted,
    );
    _checkRankUp();
    _saveHistory();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rankUpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _sparkleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        if (_rankUp) {
          _rankUpAnimationController.forward();
          _bounceAnimationController.repeat(reverse: true);
        }
      }
    });
    _adHelper.loadRewardedAd();
    _confettiParticles = _isPerfect
        ? List.generate(60, (_) => _ConfettiParticle.random())
        : const [];
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rankUpAnimationController.dispose();
    _bounceAnimationController.dispose();
    _sparkleAnimationController.dispose();
    super.dispose();
  }

  void _checkRankUp() {
    final totalExp = ref.read(totalExpProvider);
    _previousRank = UserRank.fromExp(totalExp);
    _currentRank = UserRank.fromExp(totalExp + _earnedExp);
    _rankUp = _previousRank != _currentRank;
  }

  Future<void> _showRewardedAd() async {
    if (_rewardsClaimed) return;
    await _adHelper.showRewardedAd(
      context: context,
      onRewarded: () async {
        await _claimRewards(withAd: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('報酬を獲得しました！'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  Future<void> _claimRewards({bool withAd = false}) async {
    if (_rewardsClaimed) return;

    try {
      var finalExp = _earnedExp;
      var finalPoints = _earnedPoints;

      if (withAd) {
        final adBonusExp = math.max(0, (_earnedExp * adBonus.resultScreenMultiplier).floor());
        final adBonusPoints = math.max(0, (_earnedPoints * adBonus.resultScreenMultiplier).floor());
        finalExp += adBonusExp;
        finalPoints += adBonusPoints;
      }

      await ref.read(totalExpProvider.notifier).addExp(finalExp);
      await ref.read(totalPointsProvider.notifier).addPoints(finalPoints);

      setState(() {
        _rewardsClaimed = true;
        _currentRank = ref.read(userRankProvider);
        _adHelper.isAdReady = false;
      });
    } catch (e) {
      debugPrint('報酬の獲得に失敗しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('報酬の獲得に失敗しました'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
    final accuracy =
        widget.total > 0 ? (widget.score / widget.total * 100) : 0.0;
    final totalExp = ref.watch(totalExpProvider);
    final displayRank = _rewardsClaimed ? _currentRank : _previousRank;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.stitchBackgroundLight,
        body: Stack(
          children: [
            SingleChildScrollView(
              child: ResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderSection(accuracy),
                    const SizedBox(height: 32),
                    _buildScoreGaugeSection(accuracy),
                    if (displayRank != null) ...[
                      const SizedBox(height: 32),
                      _buildRankSection(totalExp, displayRank),
                    ],
                    const SizedBox(height: 32),
                    _buildRewardsSection(),
                    const SizedBox(height: 40),
                    _buildActionSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            if (_isPerfect)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _sparkleAnimationController,
                    builder: (context, child) => CustomPaint(
                      painter: _FallingConfettiPainter(
                        particles: _confettiParticles,
                        progress: _sparkleAnimationController.value,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }

  String _getPerformanceLabel(double accuracy) {
    if (accuracy >= 100) return 'PERFECT CLEAR';
    if (accuracy >= 80) return 'EXCELLENT';
    if (accuracy >= 60) return 'GREAT';
    if (accuracy >= 40) return 'GOOD';
    return 'KEEP GOING';
  }

  Widget _buildHeaderSection(double accuracy) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.only(top: 24, bottom: 24, left: 16, right: 16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: CustomPaint(
                  painter: _ConfettiPatternPainter(),
                ),
              ),
            ),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.celebration,
                    color: AppColors.resultPrimary,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '結果発表',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.resultPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: AppColors.resultPrimary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getPerformanceLabel(accuracy),
                          style: const TextStyle(
                            color: AppColors.resultPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreGaugeSection(double accuracy) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassMorphismWidget(
        borderRadius: 16,
        borderColor: AppColors.resultPrimary.withValues(alpha: 0.2),
        padding: const EdgeInsets.all(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
        child: Column(
          children: [
            Text(
              '今回のスコア',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: accuracy),
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeOutCubic,
              builder: (context, animatedAccuracy, child) {
                return SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(160, 160),
                        painter: _CircularGaugePainter(
                          percentage: animatedAccuracy,
                          backgroundColor: const Color(0xFFE2E8F0),
                          fillColor: AppColors.resultPrimary,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                                begin: 0.0,
                                end: widget.score.toDouble()),
                            duration: const Duration(milliseconds: 1500),
                            curve: Curves.easeOutCubic,
                            builder: (context, animatedScore, child) {
                              return Text(
                                '${animatedScore.toInt()}',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              );
                            },
                          ),
                          Text(
                            '/ ${widget.total}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankSection(int totalExp, UserRank displayRank) {
    final expToNext = displayRank.expToNextRank(totalExp);
    final isMaxRank = expToNext == null;

    double progress;
    if (isMaxRank) {
      progress = 1.0;
    } else {
      final currentMin = displayRank.minExp;
      final nextRankIndex = displayRank.rankIndex + 1;
      final nextRankMinExp = ranks[nextRankIndex].requiredExp;
      final range = nextRankMinExp - currentMin;
      progress =
          range > 0 ? ((totalExp - currentMin) / range).clamp(0.0, 1.0) : 1.0;
    }

    String? nextRankLabel;
    if (!isMaxRank && displayRank.rankIndex + 1 < UserRank.values.length) {
      nextRankLabel = UserRank.values[displayRank.rankIndex + 1].japaneseName;
    }

    Widget content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _bounceAnimationController,
                builder: (context, child) {
                  final bounceValue = _rankUp
                      ? Tween<double>(begin: 0.0, end: -10.0)
                          .animate(CurvedAnimation(
                            parent: _bounceAnimationController,
                            curve: Curves.easeInOut,
                          ))
                          .value
                      : 0.0;
                  return Transform.translate(
                    offset: Offset(0, bounceValue),
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            AppColors.resultPrimary,
                            AppColors.resultAccentGreen,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                AppColors.resultPrimary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/images/rank_icons/${displayRank.name}.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.school,
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_rankUp)
                Positioned(
                  bottom: -8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.resultAccentGreen,
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.resultAccentGreen
                              .withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      'RANK UP!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            displayRank.japaneseName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isMaxRank ? 'レベルMax' : '次のランクまで $expToNext XP',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9999),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, animatedProgress, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: animatedProgress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.resultPrimary,
                            AppColors.resultAccentGreen,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayRank.japaneseName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                isMaxRank
                    ? '${displayRank.englishName} (Level Max)'
                    : nextRankLabel ?? '',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color:
                      isMaxRank ? AppColors.resultAccentGreen : Colors.grey.shade400,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (_rankUp) {
      return AnimatedBuilder(
        animation: _rankUpAnimationController,
        builder: (context, child) {
          final scaleValue = Tween<double>(begin: 0.8, end: 1.0)
              .animate(CurvedAnimation(
                parent: _rankUpAnimationController,
                curve: Curves.elasticOut,
              ))
              .value;
          final opacityValue = Tween<double>(begin: 0.0, end: 1.0)
              .animate(CurvedAnimation(
                parent: _rankUpAnimationController,
                curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
              ))
              .value;
          return Opacity(
            opacity: opacityValue,
            child: Transform.scale(
              scale: scaleValue,
              child: content,
            ),
          );
        },
      );
    }

    return content;
  }

  Widget _buildRewardsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildRewardCard(
              icon: Icons.trending_up,
              accentColor: AppColors.resultPrimary,
              label: 'EXPERIENCE',
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: _earnedExp.toDouble()),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, animatedExp, child) {
                  return Text(
                    '+${animatedExp.toInt()} EXP',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildRewardCard(
              icon: Icons.monetization_on,
              accentColor: AppColors.resultAccentGreen,
              label: 'POINTS',
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: _earnedPoints.toDouble()),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, animatedPoints, child) {
                  return Text(
                    '+${animatedPoints.toInt()} PT',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard({
    required IconData icon,
    required Color accentColor,
    required String label,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 4, color: accentColor),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Column(
                children: [
                  Icon(icon, color: accentColor, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (!_rewardsClaimed) ...[
            GlowButton(
              glowColor: AppColors.resultAccentGreen,
              onPressed:
                  _adHelper.isLoadingAd || !_adHelper.isAdReady || _rewardsClaimed
                      ? null
                      : _showRewardedAd,
              backgroundColor: AppColors.resultAccentGreen,
              foregroundColor: Colors.white,
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_adHelper.isLoadingAd)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    const Icon(Icons.play_circle, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    _adHelper.isLoadingAd
                        ? '広告を読み込み中...'
                        : !_adHelper.isAdReady
                            ? '広告を準備中...'
                            : '広告を見て報酬を2倍にする',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home, size: 20, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'トップへ戻る（報酬は獲得できません）',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.resultAccentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.resultAccentGreen.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.resultAccentGreen, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '報酬を獲得しました',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.resultAccentGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlowButton(
              glowColor: AppColors.resultPrimary,
              onPressed: () => context.go('/'),
              backgroundColor: AppColors.resultPrimary,
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
          ],
        ],
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double percentage;
  final Color backgroundColor;
  final Color fillColor;
  static const double strokeWidth = 12;

  _CircularGaugePainter({
    required this.percentage,
    required this.backgroundColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    if (percentage > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      final sweepAngle = 2 * math.pi * (percentage / 100);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) =>
      percentage != oldDelegate.percentage;
}

class _ConfettiPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bluePaint = Paint()..color = AppColors.resultPrimary;
    final greenPaint = Paint()..color = AppColors.resultAccentGreen;
    const spacing = 20.0;
    const dotRadius = 1.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, bluePaint);
      }
    }
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, greenPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConfettiParticle {
  final double x;
  final double phase;
  final double speed;
  final double size;
  final Color color;
  final double rotation;
  final double wobbleAmount;

  const _ConfettiParticle({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
    required this.wobbleAmount,
  });

  static const _colors = [
    AppColors.resultPrimary,
    AppColors.resultAccentGreen,
    Color(0xFFFFD700),
    Color(0xFFFF6B6B),
    Color(0xFFAB47BC),
  ];

  factory _ConfettiParticle.random() {
    final r = math.Random();
    return _ConfettiParticle(
      x: r.nextDouble(),
      phase: r.nextDouble(),
      speed: 0.6 + r.nextDouble() * 0.8,
      size: 4 + r.nextDouble() * 6,
      color: _colors[r.nextInt(_colors.length)],
      rotation: r.nextDouble() * math.pi * 2,
      wobbleAmount: 0.01 + r.nextDouble() * 0.025,
    );
  }
}

class _FallingConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _FallingConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.phase) % 1.0;
      final y = t * 1.4 - 0.2;
      final x = p.x + math.sin(t * math.pi * 4 + p.rotation) * p.wobbleAmount;
      final opacity = (1.0 - (y - 0.8).clamp(0.0, 0.4) / 0.4).clamp(0.0, 0.7);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(progress * math.pi * 3 * p.speed + p.rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(1),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FallingConfettiPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
