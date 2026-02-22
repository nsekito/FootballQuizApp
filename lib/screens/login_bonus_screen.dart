import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/login_bonus_provider.dart';
import '../providers/ad_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/responsive_container.dart';
import '../widgets/grid_pattern_background.dart';

class LoginBonusScreen extends ConsumerStatefulWidget {
  const LoginBonusScreen({super.key});

  @override
  ConsumerState<LoginBonusScreen> createState() => _LoginBonusScreenState();
}

class _LoginBonusScreenState extends ConsumerState<LoginBonusScreen>
    with TickerProviderStateMixin {
  bool _isLoadingAd = false;
  bool _isAdReady = false;
  late AnimationController _animationController;
  late AnimationController _bounceAnimationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _bounceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
    _loadRewardedAd();
    // 画面が開かれたときに状態をリフレッシュ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loginBonusStatusProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceAnimationController.dispose();
    super.dispose();
  }

  /// リワード広告を読み込む
  Future<void> _loadRewardedAd() async {
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
    if (_isLoadingAd) return;

    final adService = ref.read(adServiceProvider);

    // 広告が読み込まれていない場合、読み込みを試みる
    if (!adService.isRewardedAdReady) {
      await _loadRewardedAd();
      if (!adService.isRewardedAdReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('広告の読み込みに失敗しました。しばらくしてから再度お試しください。'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final loginBonusNotifier = ref.read(loginBonusStatusProvider.notifier);

    final success = await adService.showRewardedAd(
      onRewarded: (rewardAmount, rewardType) async {
        // ポイントを2倍にする
        try {
          await loginBonusNotifier.multiplyPointsWithAd();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ポイントが2倍になりました！'),
                backgroundColor: AppColors.success,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint('ポイントの2倍処理に失敗しました: $e');
        }
      },
      onError: (error) {
        debugPrint('リワード広告の表示に失敗しました: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('広告の表示に失敗しました: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );

    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('広告の表示に失敗しました。しばらくしてから再度お試しください。'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ログインボーナスを受け取る
  Future<void> _claimLoginBonus() async {
    final loginBonusNotifier = ref.read(loginBonusStatusProvider.notifier);
    try {
      final loginBonusNotifier = ref.read(loginBonusStatusProvider.notifier);
      final result = await loginBonusNotifier.claimLoginBonus();
      final points = result['points'] as int;
      final exp = result['exp'] as int;
      
      if (mounted) {
        _bounceAnimationController.forward(from: 0.0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$pointsポイント獲得しました！'),
            backgroundColor: AppColors.success,
            duration: const Duration(milliseconds: 1500), // 表示時間を短く（1.5秒）
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 100, // ボタンの上に表示
              left: 20,
              right: 20,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginBonusStatus = ref.watch(loginBonusStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.stitchBackgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'ログインボーナス',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.2,
            color: AppColors.slate500,
          ),
        ),
        centerTitle: true,
      ),
      body: GridPatternBackground(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                
                // 連続日数バッジとヒーローセクション
                _buildStreakHeroSection(loginBonusStatus),
                
                const SizedBox(height: 24),
                
                // 進捗バー
                _buildProgressBar(loginBonusStatus),
                
                const SizedBox(height: 24),
                
                // 7日間のカレンダーグリッド
                _buildCalendarGrid(loginBonusStatus),
                
                const SizedBox(height: 24),
                
                // アクションボタン
                _buildActionButtons(loginBonusStatus),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 連続日数バッジとヒーローセクション
  Widget _buildStreakHeroSection(LoginBonusStatus status) {
    return Column(
      children: [
        // 連続日数バッジ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${status.streakDays}日連続達成中',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // ヒーロータイトル
        Text(
          '${status.streakDays}日間',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 48,
            letterSpacing: -1,
            color: AppColors.textDark,
          ),
        ),
        Text(
          '連続ログイン！',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 36,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  /// 進捗バー
  Widget _buildProgressBar(LoginBonusStatus status) {
    final progress = status.streakDays / 7.0;
    final remainingDays = 7 - status.streakDays;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '現在の進捗',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.textDark.withValues(alpha: 0.6),
                ),
              ),
              Text(
                '${status.streakDays} / 7 日',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.textDark.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.slate200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remainingDays > 0
                ? 'あと$remainingDays日でグランドプライズ！'
                : 'グランドプライズ達成！',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  /// 7日間のカレンダーグリッド
  Widget _buildCalendarGrid(LoginBonusStatus status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // 1-6日目を3x2グリッドで表示
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final day = index + 1;
              return _buildDayCard(day, status);
            },
          ),
          const SizedBox(height: 12),
          // 7日目を全幅で表示
          _buildDay7Card(status),
        ],
      ),
    );
  }

  /// 日付カード（1-6日目）
  Widget _buildDayCard(int day, LoginBonusStatus status) {
    final points = _getPointsForDay(day);
    final isCurrentDay = day == status.streakDays;
    final isPastDay = day < status.streakDays;
    
    Color textColor;
    IconData iconData;
    Color iconColor;
    double opacity = 1.0;
    
    if (isCurrentDay) {
      textColor = AppColors.accent;
      iconData = Icons.stars;
      iconColor = AppColors.accent;
    } else if (isPastDay) {
      textColor = AppColors.textDark;
      iconData = Icons.check_circle;
      iconColor = AppColors.success;
      opacity = 0.6;
    } else {
      textColor = AppColors.textLight;
      iconData = Icons.circle;
      iconColor = AppColors.textLight.withValues(alpha: 0.3);
    }

    return Opacity(
      opacity: opacity,
      child: GlassMorphismWidget(
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '$day日目',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isCurrentDay ? AppColors.accent : textColor.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPastDay
                    ? AppColors.success.withValues(alpha: 0.2)
                    : (isCurrentDay
                        ? AppColors.accent.withValues(alpha: 0.2)
                        : AppColors.slate200),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                '$points pt',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 7日目の特別カード（全幅）
  Widget _buildDay7Card(LoginBonusStatus status) {
    return GlassMorphismWidget(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.card_giftcard,
              color: AppColors.accent,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7日目マイルストーン',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: AppColors.textDark.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'グランドプライズ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                '10',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
                ),
              ),
              Text(
                'ポイント',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.textDark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 日数に応じたポイントを取得
  int _getPointsForDay(int day) {
    switch (day) {
      case 1:
      case 2:
      case 3:
        return 1;
      case 4:
        return 4;
      case 5:
      case 6:
        return 1;
      case 7:
        return 10;
      default:
        return 1;
    }
  }

  /// アクションボタン
  Widget _buildActionButtons(LoginBonusStatus status) {
    return Column(
      children: [
        // 報酬を受け取るボタン（受け取り可能な場合のみ）
        if (status.canClaim && !status.hasClaimedToday)
          _buildClaimButton(),
        
        // 動画ボタン（受け取り済みで広告未視聴の場合のみ）
        if (status.hasClaimedToday && !status.hasWatchedAd) ...[
          const SizedBox(height: 16),
          _buildVideoButton(),
        ],
        
        // 完了メッセージ（広告視聴済みの場合）
        if (status.hasClaimedToday && status.hasWatchedAd)
          _buildCompletedMessage(status),
      ],
    );
  }

  /// 受け取りボタン
  Widget _buildClaimButton() {
    return AnimatedBuilder(
      animation: _bounceAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_bounceAnimationController.value * 0.1),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _claimLoginBonus,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.success.withValues(alpha: 0.2),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.card_giftcard, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '報酬を受け取る',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 動画ボタン
  Widget _buildVideoButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isAdReady ? _showRewardedAd : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.difficultyNormal,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          shadowColor: AppColors.difficultyNormal.withValues(alpha: 0.3),
        ),
        child: _isLoadingAd
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '動画を見てポイント2倍 (x2)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 完了メッセージ
  Widget _buildCompletedMessage(LoginBonusStatus status) {
    return GlassMorphismWidget(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '広告視聴済み（${status.points * 2}ポイント獲得）',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
