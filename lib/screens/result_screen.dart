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
import '../services/ad_service.dart';
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
    with SingleTickerProviderStateMixin {
  UserRank? _previousRank;
  UserRank? _currentRank;
  bool _rankUp = false;
  late AnimationController _animationController;
  bool _showContent = false;
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
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });
    // 広告を事前に読み込む
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _animationController.dispose();
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
              content: Text('報酬を獲得しました！+${AppConstants.expRewardedAd} EXP +${AppConstants.pointsRewardedAd} PT'),
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
        await ref.read(totalExpProvider.notifier).addExp(AppConstants.expRewardedAd);
        await ref.read(totalPointsProvider.notifier).addPoints(AppConstants.pointsRewardedAd);
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
    final accuracy = widget.total > 0 ? (widget.score / widget.total * 100) : 0.0;
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
                      GlowButton(
                        glowColor: Colors.amber.shade400,
                        onPressed: _isLoadingAd || !_isAdReady || _rewardsClaimed
                            ? null
                            : _showRewardedAd,
                        backgroundColor: Colors.amber.shade400,
                        foregroundColor: Colors.white,
                        borderRadius: 12,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoadingAd)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            else
                              const Icon(Icons.play_circle_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _isLoadingAd
                                  ? '広告を読み込み中...'
                                  : !_isAdReady
                                      ? '広告を準備中...'
                                      : '広告を見て報酬を獲得',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (!_isLoadingAd && _isAdReady) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '+${AppConstants.expRewardedAd} EXP +${AppConstants.pointsRewardedAd} PT',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // 広告を見ずにトップに戻るボタン
                      OutlinedButton(
                        onPressed: () {
                          context.go('/');
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '広告を見ずにトップに戻る',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
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
                            borderRadius: const BorderRadius.all(Radius.circular(20)),
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
                            color: AppColors.stitchEmerald.withValues(alpha: 0.1),
                            borderRadius: const BorderRadius.all(Radius.circular(20)),
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

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData iconData;

    switch (rank) {
      // ランク1-5: 初期段階（グレー系）
      case UserRank.ballPicker:
      case UserRank.coneSetter:
      case UserRank.bibDistributor:
      case UserRank.eternalBench:
      case UserRank.stoppageTimePlayer:
        badgeColor = Colors.grey.shade400;
        iconData = Icons.sports_soccer;
        break;
      // ランク6-7: 中級段階初期（ブルー系）
      case UserRank.starterCandidate:
      case UserRank.localCelebrity:
        badgeColor = Colors.blue.shade400;
        iconData = Icons.star;
        break;
      // ランク8-10: 中級段階後期（グリーン系）
      case UserRank.j3RisingStar:
      case UserRank.j2NuclearStriker:
      case UserRank.j1Regular:
        badgeColor = Colors.green.shade400;
        iconData = Icons.emoji_events;
        break;
      // ランク11-12: 上級段階初期（ゴールド系）
      case UserRank.nationalSecretWeapon:
      case UserRank.worldCupWarrior:
        badgeColor = Colors.amber.shade400;
        iconData = Icons.workspace_premium;
        break;
      // ランク13-15: 上級段階後期（パープル/レッド系）
      case UserRank.overseasSamurai:
        badgeColor = Colors.purple.shade400;
        iconData = Icons.auto_awesome;
        break;
      case UserRank.ballonDor:
        badgeColor = Colors.deepOrange.shade400;
        iconData = Icons.auto_awesome;
        break;
      case UserRank.soccerGod:
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
