import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/user_data_provider.dart';
import '../providers/quiz_history_provider.dart';
import '../models/user_rank.dart';
import '../constants/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/glow_button.dart';
import '../widgets/responsive_container.dart';
import '../widgets/banner_ad_widget.dart';
import '../providers/ad_provider.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final int score;
  final int total;
  final int earnedExp;
  final int earnedPoints;
  final String category;
  final String difficulty;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.earnedExp,
    required this.earnedPoints,
    required this.category,
    required this.difficulty,
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
  bool _rewardsClaimed = false; // 報酬が獲得済みかどうか
  bool _isLoadingAd = false; // 広告読み込み中かどうか
  bool _isAdReady = false; // 広告が読み込まれているかどうか

  // 獲得expとポイントを取得（widgetから受け取る）
  int get _earnedExp => widget.earnedExp;
  int get _earnedPoints => widget.earnedPoints;

  @override
  void initState() {
    super.initState();
    _checkRankUp();
    _saveHistory(); // ポイントとexpは広告視聴後に加算
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
    // 広告を事前に読み込む
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _rankUpAnimationController.dispose();
    _bounceAnimationController.dispose();
    _sparkleAnimationController.dispose();
    // 広告サービスはシングルトンなので、ここでは破棄しない
    super.dispose();
  }

  void _checkRankUp() {
    final totalExp = ref.read(totalExpProvider);
    _previousRank = UserRank.fromExp(totalExp);
    _currentRank = UserRank.fromExp(totalExp + _earnedExp);
    _rankUp = _previousRank != _currentRank;
  }

  /// リワード広告を読み込む
  Future<void> _loadRewardedAd() async {
    if (_rewardsClaimed) return;

    setState(() {
      _isLoadingAd = true;
    });

    final adService = ref.read(adServiceProvider);
    await adService.loadRewardedAd(
      onRewarded: (rewardAmount, rewardType) {
        // 広告視聴完了時の処理は_showRewardedAdで行う
      },
      onError: (error) {
        debugPrint('リワード広告の読み込みに失敗しました: $error');
        if (mounted) {
          setState(() {
            _isLoadingAd = false;
            _isAdReady = false;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isLoadingAd = false;
        _isAdReady = adService.isRewardedAdReady;
      });
    }
  }

  /// リワード広告を表示する
  Future<void> _showRewardedAd() async {
    if (_rewardsClaimed || _isLoadingAd) return;

    final adService = ref.read(adServiceProvider);

    // 広告が読み込まれていない場合、読み込みを試みる
    if (!adService.isRewardedAdReady) {
      await _loadRewardedAd();
      if (!adService.isRewardedAdReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('広告の読み込みに失敗しました。しばらくしてから再度お試しください。'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    final success = await adService.showRewardedAd(
      onRewarded: (rewardAmount, rewardType) async {
        // 広告視聴完了後、報酬を付与
        await _claimRewards(withAd: true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  '報酬を獲得しました！+${AppConstants.expRewardedAd} EXP +${AppConstants.pointsRewardedAd} PT'),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      onError: (error) {
        debugPrint('リワード広告の表示に失敗しました: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('広告の表示に失敗しました'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('広告を表示できませんでした。しばらくしてから再度お試しください。'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _claimRewards({bool withAd = false}) async {
    if (_rewardsClaimed) return;

    try {
      // expとポイントを加算
      await ref.read(totalExpProvider.notifier).addExp(_earnedExp);
      await ref.read(totalPointsProvider.notifier).addPoints(_earnedPoints);

      // 広告視聴の場合、追加報酬を加算
      if (withAd) {
        await ref
            .read(totalExpProvider.notifier)
            .addExp(AppConstants.expRewardedAd);
        await ref
            .read(totalPointsProvider.notifier)
            .addPoints(AppConstants.pointsRewardedAd);
      }

      setState(() {
        _rewardsClaimed = true;
        _currentRank = ref.read(userRankProvider);
        _isAdReady = false; // 広告は使用済み
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
          child: ResponsiveContainer(
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

                // 獲得expとポイント表示
                GlassMorphismWidget(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '獲得経験値',
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
                                    end: _earnedExp.toDouble(),
                                  ),
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, animatedExp, child) {
                                    return Text(
                                      '+${animatedExp.toInt()} EXP',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.blue.shade600,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
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
                                    end: _earnedPoints.toDouble(),
                                  ),
                                  duration: const Duration(milliseconds: 1500),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, animatedPoints, child) {
                                    return Text(
                                      '+${animatedPoints.toInt()} PT',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.stitchEmerald,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!_rewardsClaimed) ...[
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),
                        // 広告視聴ボタン
                        SizedBox(
                          width: double.infinity,
                          child: GlowButton(
                            glowColor: AppColors.stitchEmerald,
                            onPressed:
                                _isLoadingAd || !_isAdReady || _rewardsClaimed
                                    ? null
                                    : _showRewardedAd,
                            backgroundColor: AppColors.stitchEmerald,
                            foregroundColor: Colors.white,
                            borderRadius: 12,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isLoadingAd)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                else
                                  const Icon(Icons.play_circle_outline,
                                      size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  _isLoadingAd
                                      ? '広告を読み込み中...'
                                      : !_isAdReady
                                          ? '広告を準備中...'
                                          : '広告を見て報酬を獲得',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 広告を見ずにトップに戻るボタン
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              context.go('/');
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'トップに戻る（報酬は入手できません）',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '報酬を獲得しました',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ランクアップ演出
                if (_rankUp && _currentRank != null) ...[
                  AnimatedBuilder(
                    animation: Listenable.merge([
                      _rankUpAnimationController,
                      _bounceAnimationController,
                    ]),
                    builder: (context, child) {
                      final scaleValue = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _rankUpAnimationController,
                        curve: Curves.elasticOut,
                      )).value;

                      final bounceValue = Tween<double>(
                        begin: 0.0,
                        end: 10.0,
                      ).animate(CurvedAnimation(
                        parent: _bounceAnimationController,
                        curve: Curves.easeInOut,
                      )).value;

                      final opacityValue = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).animate(CurvedAnimation(
                        parent: _rankUpAnimationController,
                        curve: Curves.easeIn,
                      )).value;

                      return Opacity(
                        opacity: opacityValue,
                        child: Transform.scale(
                          scale: scaleValue,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.amber.shade300,
                                  Colors.orange.shade400,
                                  Colors.pink.shade300,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.amber.withValues(alpha: 0.5),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                  blurRadius: 50,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                // キラキラ効果
                                AnimatedBuilder(
                                  animation: _sparkleAnimationController,
                                  builder: (context, child) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      clipBehavior: Clip.none,
                                      children: [
                                        Transform.translate(
                                          offset: Offset(
                                            bounceValue * 0.5,
                                            -bounceValue,
                                          ),
                                          child: Transform.rotate(
                                            angle: _sparkleAnimationController.value * 2 * math.pi * 0.1,
                                            child: _RankBadgeWidget(
                                              rank: _currentRank!,
                                              size: 140,
                                            ),
                                          ),
                                        ),
                                        // キラキラパーティクル
                                        ...List.generate(8, (index) {
                                          final angle = (index / 8) * 2 * math.pi;
                                          final radius = 90.0 + bounceValue * 2;
                                          final sparkleOpacity = (0.4 + 0.6 * math.sin(_sparkleAnimationController.value * 2 * math.pi + index)).clamp(0.0, 1.0);
                                          final sparkleRadius = radius * (1 + 0.2 * math.sin(_sparkleAnimationController.value * 2 * math.pi * 2 + index));
                                          return Positioned(
                                            left: sparkleRadius * math.cos(angle),
                                            top: sparkleRadius * math.sin(angle),
                                            child: Opacity(
                                              opacity: sparkleOpacity,
                                              child: Transform.rotate(
                                                angle: _sparkleAnimationController.value * 2 * math.pi,
                                                child: Icon(
                                                  Icons.star,
                                                  color: Colors.white,
                                                  size: 18 + bounceValue * 0.3,
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 24),
                                // グラデーションテキスト「ランクアップ！」
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.amber.shade300,
                                      Colors.orange.shade600,
                                      Colors.pink.shade400,
                                      Colors.purple.shade400,
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'ランクアップ！',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // ランク変化の表示
                                AnimatedOpacity(
                                  opacity: _rankUpAnimationController.value > 0.5 ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 500),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _previousRank?.japaneseName ?? '',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: AnimatedBuilder(
                                          animation: _sparkleAnimationController,
                                          builder: (context, child) {
                                            return Transform.rotate(
                                              angle: _sparkleAnimationController.value * 2 * math.pi,
                                              child: Icon(
                                                Icons.arrow_forward,
                                                color: Colors.amber.shade700,
                                                size: 24,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            Colors.amber.shade400,
                                            Colors.orange.shade600,
                                          ],
                                        ).createShader(bounds),
                                        child: Text(
                                          _currentRank?.japaneseName ?? '',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
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
                    },
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
                      Builder(
                        builder: (context) {
                          // 報酬獲得前は前のランク、獲得後は現在のランクを表示
                          final displayRank = _rewardsClaimed ? _currentRank : _previousRank;
                          if (displayRank != null) {
                            return _RankBadgeWidget(
                              rank: displayRank,
                              size: 128,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 24),
                      Builder(
                        builder: (context) {
                          final displayRank = _rewardsClaimed ? _currentRank : _previousRank;
                          return Text(
                            displayRank?.japaneseName ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          final displayRank = _rewardsClaimed ? _currentRank : _previousRank;
                          return Text(
                            displayRank?.englishName ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade500,
                              letterSpacing: 1.2,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Text(
                              '累計EXP: ${NumberFormat('#,###').format(totalExp)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.stitchEmerald
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(20)),
                            ),
                            child: Text(
                              '累計PT: ${NumberFormat('#,###').format(totalPoints)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.stitchEmerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 報酬獲得済みの場合のみボタンを表示
                if (_rewardsClaimed) ...[
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
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
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

  static const String _rankIconsPath = 'assets/images/rank_icons';

  /// ランクに応じたボーダーの色を返す
  List<Color> _getRankBorderColors(UserRank rank) {
    switch (rank) {
      case UserRank.ballPicker:
      case UserRank.coneSetter:
      case UserRank.waterCarrier:
      case UserRank.bibDistributor:
      case UserRank.trainee:
      case UserRank.benchPlayer:
        return [Colors.grey.shade400, Colors.grey.shade600];
      case UserRank.substitute:
      case UserRank.starter:
        return [Colors.blue.shade300, Colors.blue.shade600];
      case UserRank.numberTen:
      case UserRank.captain:
        return [Colors.green.shade300, Colors.green.shade600];
      case UserRank.domesticMVP:
      case UserRank.overseasTransfer:
        return [Colors.amber.shade300, Colors.orange.shade600];
      case UserRank.worldClass:
        return [Colors.purple.shade300, Colors.purple.shade600];
      case UserRank.ballonDor:
        return [Colors.deepOrange.shade300, Colors.deepOrange.shade700];
      case UserRank.legend:
        return [Colors.red.shade300, Colors.red.shade700];
    }
  }

  /// ランクに応じたグロー効果の色を返す
  Color _getRankGlowColor(UserRank rank) {
    switch (rank) {
      case UserRank.ballPicker:
      case UserRank.coneSetter:
      case UserRank.waterCarrier:
      case UserRank.bibDistributor:
      case UserRank.trainee:
      case UserRank.benchPlayer:
        return Colors.grey.shade400;
      case UserRank.substitute:
      case UserRank.starter:
        return Colors.blue.shade400;
      case UserRank.numberTen:
      case UserRank.captain:
        return Colors.green.shade400;
      case UserRank.domesticMVP:
      case UserRank.overseasTransfer:
        return Colors.amber.shade400;
      case UserRank.worldClass:
        return Colors.purple.shade400;
      case UserRank.ballonDor:
        return Colors.deepOrange.shade400;
      case UserRank.legend:
        return Colors.red.shade400;
    }
  }

  /// 枠付きランクアイコンを構築する共通ウィジェット
  Widget _buildRankIconWithFrame(String imagePath, double size, UserRank rank) {
    final borderColors = _getRankBorderColors(rank);
    final glowColor = _getRankGlowColor(rank);
    final borderWidth = size * 0.05; // サイズの5%をボーダー幅とする

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: borderWidth,
          color: borderColors[0],
        ),
        boxShadow: [
          // 外側のグロー効果（複数レイヤー）
          BoxShadow(
            color: glowColor.withValues(alpha: 0.6),
            blurRadius: size * 0.15,
            spreadRadius: size * 0.05,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: size * 0.25,
            spreadRadius: size * 0.1,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.2),
            blurRadius: size * 0.35,
            spreadRadius: size * 0.15,
          ),
          // 内側の影（深みを出す）
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: size * 0.1,
            spreadRadius: -size * 0.05,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: borderWidth * 0.5,
              color: borderColors[1],
            ),
          ),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                _FallbackRankBadge(rank: rank, size: size),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildRankIconWithFrame(
      '$_rankIconsPath/${rank.name}.png',
      size,
      rank,
    );
  }
}

/// ランクアイコン画像がない場合のフォールバック表示
class _FallbackRankBadge extends StatelessWidget {
  final UserRank rank;
  final double size;

  const _FallbackRankBadge({required this.rank, required this.size});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData iconData;

    switch (rank) {
      case UserRank.ballPicker:
      case UserRank.coneSetter:
      case UserRank.waterCarrier:
      case UserRank.bibDistributor:
      case UserRank.trainee:
      case UserRank.benchPlayer:
        badgeColor = Colors.grey.shade400;
        iconData = Icons.sports_soccer;
        break;
      case UserRank.substitute:
      case UserRank.starter:
        badgeColor = Colors.blue.shade400;
        iconData = Icons.star;
        break;
      case UserRank.numberTen:
      case UserRank.captain:
        badgeColor = Colors.green.shade400;
        iconData = Icons.emoji_events;
        break;
      case UserRank.domesticMVP:
      case UserRank.overseasTransfer:
        badgeColor = Colors.amber.shade400;
        iconData = Icons.workspace_premium;
        break;
      case UserRank.worldClass:
        badgeColor = Colors.purple.shade400;
        iconData = Icons.auto_awesome;
        break;
      case UserRank.ballonDor:
        badgeColor = Colors.deepOrange.shade400;
        iconData = Icons.auto_awesome;
        break;
      case UserRank.legend:
        badgeColor = Colors.red.shade400;
        iconData = Icons.auto_awesome;
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
