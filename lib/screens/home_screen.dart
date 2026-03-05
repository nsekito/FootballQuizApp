import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_data_provider.dart';
import '../providers/sample_data_provider.dart';
import '../providers/recap_data_provider.dart';
import '../providers/database_provider.dart';
import '../constants/app_constants.dart';
import '../utils/unlock_key_utils.dart';
import '../utils/app_date_utils.dart';
import '../constants/app_colors.dart';
import '../models/user_rank.dart';
import '../models/promotion_exam.dart';
import '../widgets/responsive_container.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/rank_icon_widget.dart';
import 'home/category_section.dart';
import '../providers/notification_provider.dart';
import '../providers/admin_mode_provider.dart';
import '../providers/login_bonus_provider.dart';
import '../constants/game_config.dart';
import '../utils/rewarded_ad_helper.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  bool _hasSyncedRecap = false;
  late final RewardedAdHelper _adHelper;
  bool _isRankIconExpanded = false;
  int _refreshKey = 0;
  String? _lastRoutePath;
  bool _hasShownLoginBonusDialog = false;
  bool _isFromTitleScreen = false;

  @override
  void initState() {
    super.initState();
    _adHelper = RewardedAdHelper(
      ref: ref,
      onStateChanged: () => setState(() {}),
      isMounted: () => mounted,
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasSyncedRecap) {
        _hasSyncedRecap = true;
        _syncWeeklyRecapData(ref);
      }
      // 初回表示時、タイトル画面からの遷移かどうかを判定
      final routerState = GoRouterState.of(context);
      final currentLocation = routerState.uri.toString();
      if (currentLocation == '/' || currentLocation.startsWith('/?')) {
        // 前のルートがタイトル画面かどうかを確認（initStateでは前のルートが取得できないため、buildで判定）
        _isFromTitleScreen = true; // 初回はタイトル画面からの遷移とみなす
      }
    });
    _adHelper.loadRewardedAd();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 画面が戻ってきたときにFutureBuilderを再構築
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _refreshKey++;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // アプリがフォアグラウンドに戻った時にリフレッシュ
    if (state == AppLifecycleState.resumed && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _refreshKey++;
          });
        }
      });
    }
  }

  int _getDaysUntilNextWeek(DateTime date, {bool isMaxReached = false}) {
    final now = DateTime.now();
    final nextPlayableDate =
        _getNextPlayableDate(date, isMaxReached: isMaxReached);
    final difference = nextPlayableDate.difference(now);
    final days = difference.inDays;
    return days + (difference.inHours % 24 > 0 ? 1 : 0);
  }

  DateTime _getNextPlayableDate(DateTime date, {bool isMaxReached = false}) {
    if (isMaxReached) {
      return AppDateUtils.getWeekStartDate(date);
    } else {
      return AppDateUtils.getNextWeekStartDate(date);
    }
  }

  /// MATCH DAYの詳細なステータス情報を取得（リーグタイプ別）
  Future<Map<String, dynamic>> _getMatchDayDetailedStatus() async {
    final databaseService = ref.read(databaseServiceProvider);
    final j1PlayCount = await databaseService
        .getMatchDayPlayCountByLeagueType(AppConstants.leagueTypeJ1);
    final europePlayCount = await databaseService
        .getMatchDayPlayCountByLeagueType(AppConstants.leagueTypeEurope);
    final totalPlayCount = j1PlayCount + europePlayCount;
    final j1CanPlay = await databaseService
        .canPlayMatchDayByLeagueType(AppConstants.leagueTypeJ1);
    final europeCanPlay = await databaseService
        .canPlayMatchDayByLeagueType(AppConstants.leagueTypeEurope);
    final canPlay = j1CanPlay || europeCanPlay;

    final now = DateTime.now();
    final weekStart = AppDateUtils.getWeekStartDate(now);
    final weekEnd = AppDateUtils.getWeekEndDate(now);
    final isMaxReached = totalPlayCount >= MATCHDAY.maxPlaysPerWeek;
    final nextPlayableDate =
        _getNextPlayableDate(now, isMaxReached: isMaxReached);
    final daysUntilNextWeek =
        _getDaysUntilNextWeek(now, isMaxReached: isMaxReached);
    final remainingPlays = MATCHDAY.maxPlaysPerWeek - totalPlayCount;

    return {
      'canPlay': canPlay,
      'playCount': totalPlayCount,
      'j1PlayCount': j1PlayCount,
      'europePlayCount': europePlayCount,
      'j1CanPlay': j1CanPlay,
      'europeCanPlay': europeCanPlay,
      'remainingPlays': remainingPlays,
      'weekStart': weekStart,
      'weekEnd': weekEnd,
      'nextWeekStart': nextPlayableDate, // 次回プレイ可能日
      'daysUntilNextWeek': daysUntilNextWeek,
      'isFreePlay': totalPlayCount == 0,
      'isMaxReached': isMaxReached,
      'multiplier': totalPlayCount < MATCHDAY.playMultipliers.length
          ? MATCHDAY.playMultipliers[totalPlayCount]
          : MATCHDAY.playMultipliers.last,
    };
  }

  Future<void> _showRewardedAdForMatchDay() async {
    await _adHelper.showRewardedAd(
      context: context,
      onRewarded: () async {
        if (!mounted) return;
        context
            .push('/configuration?category=${AppConstants.categoryMatchRecap}');
        _adHelper.loadRewardedAd();
      },
    );
  }

  Future<void> _handleMatchDayTap(BuildContext context) async {
    final databaseService = ref.read(databaseServiceProvider);
    final j1PlayCount = await databaseService
        .getMatchDayPlayCountByLeagueType(AppConstants.leagueTypeJ1);
    final europePlayCount = await databaseService
        .getMatchDayPlayCountByLeagueType(AppConstants.leagueTypeEurope);
    final totalPlayCount = j1PlayCount + europePlayCount;
    final j1CanPlay = await databaseService
        .canPlayMatchDayByLeagueType(AppConstants.leagueTypeJ1);
    final europeCanPlay = await databaseService
        .canPlayMatchDayByLeagueType(AppConstants.leagueTypeEurope);
    final canPlay = j1CanPlay || europeCanPlay;

    if (!mounted) return;

    if (!canPlay) {
      // 今週のプレイ回数が上限に達している場合
      if (!mounted) return;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('今週のMATCH DAYのプレイ回数が上限に達しています（J1・Europeそれぞれ3回ずつ）'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    if (totalPlayCount == 0) {
      // 無料でプレイ可能（1回目）
      if (!mounted) return;
      if (!context.mounted) return;
      context
          .push('/configuration?category=${AppConstants.categoryMatchRecap}');
    } else if (totalPlayCount < MATCHDAY.maxPlaysPerWeek) {
      // 2回目以降は広告視聴で追加チャレンジ
      if (!mounted) return;
      await _showRewardedAdForMatchDay();
    }
  }

  @override
  Widget build(BuildContext context) {
    // サンプルデータの初期化を確認
    ref.watch(sampleDataInitializedProvider);

    final totalExp = ref.watch(totalExpProvider);
    final totalPoints = ref.watch(totalPointsProvider);
    final userRank = ref.watch(userRankProvider);

    // ログインボーナスの状態を監視
    final loginBonusStatus = ref.watch(loginBonusStatusProvider);
    final canClaim =
        loginBonusStatus.canClaim && !loginBonusStatus.hasClaimedToday;

    // ログインボーナスを受け取れる状態になったら、ポップアップを表示
    // タイトル画面からの遷移時のみ表示
    if (canClaim && !_hasShownLoginBonusDialog && _isFromTitleScreen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // 再度チェック（状態が変わっている可能性があるため）
          final currentStatus = ref.read(loginBonusStatusProvider);
          final currentCanClaim =
              currentStatus.canClaim && !currentStatus.hasClaimedToday;
          if (currentCanClaim && _isFromTitleScreen) {
            _hasShownLoginBonusDialog = true;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _showLoginBonusDialog();
              }
            });
          }
        }
      });
    }

    // ログインボーナスを受け取った後は、フラグをリセット（次回リセット時に再表示できるように）
    if (!canClaim && _hasShownLoginBonusDialog) {
      // 受け取った後は、次回リセット時に再表示できるようにフラグをリセット
      // ただし、少し遅延させてからリセット（ダイアログが閉じた後）
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _hasShownLoginBonusDialog = false;
          }
        });
      });
    }

    // ルートが変更された場合（結果画面から戻った時など）にリフレッシュ
    final routerState = GoRouterState.of(context);
    final currentLocation = routerState.uri.toString();
    if (currentLocation != _lastRoutePath) {
      final previousLocation = _lastRoutePath;
      _lastRoutePath = currentLocation;
      
      // タイトル画面からの遷移かどうかを判定
      if (previousLocation == '/title' && (currentLocation == '/' || currentLocation.startsWith('/?'))) {
        _isFromTitleScreen = true;
      } else {
        _isFromTitleScreen = false;
      }
      
      // ホーム画面に戻ってきた時にリフレッシュ
      if (currentLocation == '/' || currentLocation.startsWith('/?')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _refreshKey++;
            });
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.techWhite,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ヘッダー
                _buildHeader(context),

                // メインコンテンツ
                Expanded(
                  child: SingleChildScrollView(
                    child: ResponsiveContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Featured Card (MATCH DAY)
                          _buildFeaturedCard(context),
                          const SizedBox(height: 24),

                          // ユーザー情報カード
                          _buildUserInfoCard(
                              context, ref, totalExp, totalPoints, userRank),
                          const SizedBox(height: 24),

                          // 昇格試験セクション
                          _buildPromotionExamSection(context, ref),
                          const SizedBox(height: 24),

                          const CategorySection(),
                          const SizedBox(height: 24),

                          // 履歴と統計
                          _buildQuestionUnlockSection(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 拡大時のオーバーレイ
          if (_isRankIconExpanded) _buildExpandedRankOverlay(userRank),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: const Border(
          bottom: BorderSide(color: AppColors.slate100, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOCCER',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.techIndigo,
                ),
              ),
              Text(
                'QUIZ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.techBlue,
                ),
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  SizedBox(
                    width: 6,
                    height: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.techGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Server Status: Online',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              // 管理者設定ボタン（管理者権限がある場合のみ表示）
              if (ref.watch(isAdminProvider))
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => context.push('/admin-settings'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.stitchEmerald,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.slate100,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                      BorderSide(color: AppColors.slate200)),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.slate500,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      key: ValueKey(_refreshKey), // キーを追加して再構築を強制
      future: _getMatchDayDetailedStatus(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        final canPlay = data['canPlay'] as bool;
        final playCount = data['playCount'] as int;
        final daysUntilNextWeek = data['daysUntilNextWeek'] as int;
        final nextWeekStart = data['nextWeekStart'] as DateTime;
        final isMaxReached = data['isMaxReached'] as bool;

        return AbsorbPointer(
          absorbing: !canPlay, // プレイ不可の場合はタップを無効化
          child: GestureDetector(
            onTap: canPlay ? () => _handleMatchDayTap(context) : null,
            child: Container(
              constraints: const BoxConstraints(minHeight: 280),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.techBlue.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(24)),
                child: Stack(
                  children: [
                    // スタジアム背景画像
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/03_Backgrounds/stadium_background.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 画像が存在しない場合はグラデーションを表示
                          debugPrint('スタジアム画像の読み込みエラー: $error');
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.techBlue.withValues(alpha: 0.2),
                                  AppColors.techIndigo.withValues(alpha: 0.6),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // オーバーレイ（テキストの可読性を向上）
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    // 右側の矢印アイコン（プレイ可能時のみ表示）
                    if (canPlay)
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Icon(
                            Icons.chevron_right,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 28,
                          ),
                        ),
                      ),
                    // コンテンツ
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.blue.shade100,
                                Colors.cyan.shade200,
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'MATCH DAY',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.0,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 3),
                                    blurRadius: 12,
                                    color: Colors.black,
                                  ),
                                  Shadow(
                                    offset: Offset(0, 6),
                                    blurRadius: 20,
                                    color: Colors.black87,
                                  ),
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 状態に応じた情報表示
                          if (isMaxReached) ...[
                            // 上限到達時
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade400
                                    .withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.orange.shade200,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '今週のプレイ回数が上限に達しています',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 1),
                                              blurRadius: 4,
                                              color: Colors.black
                                                  .withValues(alpha: 0.8),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '次回プレイ可能: ${AppDateUtils.formatDateJapanese(nextWeekStart)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 1),
                                              blurRadius: 3,
                                              color: Colors.black
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (daysUntilNextWeek > 0) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: Colors.white
                                              .withValues(alpha: 0.8),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'あと$daysUntilNextWeek日',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            shadows: [
                                              Shadow(
                                                offset: const Offset(0, 1),
                                                blurRadius: 3,
                                                color: Colors.black
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              gradient: canPlay
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.shade400
                                            .withValues(alpha: 0.2),
                                        Colors.cyan.shade400
                                            .withValues(alpha: 0.1),
                                        AppColors.techBlue
                                            .withValues(alpha: 0.15),
                                      ],
                                    )
                                  : null,
                              color: canPlay ? null : Colors.grey.shade300,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(16)),
                              border: canPlay
                                  ? Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      width: 1.5,
                                    )
                                  : null,
                              boxShadow: canPlay
                                  ? [
                                      BoxShadow(
                                        color: Colors.blue.shade400
                                            .withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                        spreadRadius: 2,
                                      ),
                                      BoxShadow(
                                        color: Colors.cyan.shade300
                                            .withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 1,
                                      ),
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // メインテキストとアイコン
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      isMaxReached
                                          ? 'プレイ不可'
                                          : (playCount == 0
                                              ? 'START MISSION'
                                              : '広告を見てプレイ'),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: canPlay
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                        letterSpacing: 1.0,
                                        shadows: canPlay
                                            ? [
                                                Shadow(
                                                  offset: const Offset(0, 2),
                                                  blurRadius: 6,
                                                  color: Colors.black
                                                      .withValues(alpha: 0.5),
                                                ),
                                                Shadow(
                                                  offset: const Offset(0, 1),
                                                  blurRadius: 3,
                                                  color: Colors.blue.shade900
                                                      .withValues(alpha: 0.3),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (canPlay) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.play_circle_filled,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ],
                                  ],
                                ),
                                if (!isMaxReached) ...[
                                  const SizedBox(height: 6),
                                  // サブテキスト（倍率とプレイ回数）
                                  Text(
                                    '倍率: ${(data['multiplier'] as double).toStringAsFixed(1)}x | プレイ回数: $playCount/${MATCHDAY.maxPlaysPerWeek}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: canPlay
                                          ? Colors.white.withValues(alpha: 0.9)
                                          : Colors.grey.shade500,
                                      shadows: canPlay
                                          ? [
                                              Shadow(
                                                offset: const Offset(0, 1),
                                                blurRadius: 3,
                                                color: Colors.black
                                                    .withValues(alpha: 0.4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserInfoCard(
    BuildContext context,
    WidgetRef ref,
    int totalExp,
    int totalPoints,
    UserRank userRank,
  ) {
    final progressValue = userRank.maxExp != null
        ? (totalExp - userRank.minExp) / (userRank.maxExp! - userRank.minExp)
        : 1.0;
    final progressPercent = (progressValue * 100).clamp(0.0, 100.0).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: AppColors.techBlue.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isRankIconExpanded = !_isRankIconExpanded;
                      });
                    },
                    child: RankIconWidget(
                      rank: userRank,
                      size: 80.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${_calculateLevel(totalExp)}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.techBlue,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        userRank.japaneseName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.techIndigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat('#,###').format(totalExp),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'EXP',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                NumberFormat('#,###').format(totalPoints),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.techIndigo,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'PT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.slate400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.slate200.withValues(alpha: 0.5),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progressValue.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.techBlue, AppColors.techGreen],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                userRank.maxExp != null
                    ? 'Next: ${_getNextRankName(userRank)}'
                    : '最高ランク達成',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
              if (userRank.maxExp != null)
                Text(
                  '$progressPercent% Complete',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// ログインボーナスポップアップダイアログを表示
  void _showLoginBonusDialog() {
    final loginBonusStatus = ref.read(loginBonusStatusProvider);

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0, // 黒い影を削除
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.orange.shade300,
              width: 2,
            ),
            // オレンジのグローのみ、黒い影は削除
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.4),
                blurRadius: 30,
                spreadRadius: 3,
                offset: const Offset(0, 0), // 影のオフセットを0にして上部の黒い影を防ぐ
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ギフトアイコン（グロー効果付き）
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    color: Colors.orange.shade700,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                // タイトル（ポップなフォント）
                Text(
                  'ログインボーナス',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                // 獲得ポイント表示（グラデーション付き、ポップなフォント）
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.shade400,
                      Colors.orange.shade700,
                      Colors.red.shade600,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    '${loginBonusStatus.points}ポイント',
                    style: GoogleFonts.mPlusRounded1c(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '獲得可能',
                  style: GoogleFonts.mPlusRounded1c(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 36),
                // ポイントゲットボタン（オレンジ/赤のグラデーション、大きく）
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _claimLoginBonusFromDialog(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.orange.shade600,
                              Colors.red.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.card_giftcard, size: 28, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              'ポイントゲット',
                              style: GoogleFonts.mPlusRounded1c(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // 広告を見て2倍ボタン（黄色/オレンジのグラデーション、大きく）
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _claimLoginBonusWithAd(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle, size: 28, color: Colors.white),
                            const SizedBox(width: 12),
                            Text(
                              '広告を見て2倍',
                              style: GoogleFonts.mPlusRounded1c(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// ダイアログからログインボーナスを受け取る処理
  Future<void> _claimLoginBonusFromDialog(BuildContext dialogContext) async {
    try {
      final loginBonusNotifier = ref.read(loginBonusStatusProvider.notifier);
      final result = await loginBonusNotifier.claimLoginBonus();
      final points = result['points'] as int;

      // ダイアログを閉じる
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      // 成功メッセージを表示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$pointsポイント獲得しました！'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: 100,
              left: 20,
              right: 20,
            ),
          ),
        );
      }
    } catch (e) {
      // エラーが発生した場合はダイアログを閉じずにエラーメッセージを表示
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 広告を見て2倍ボタンの処理（受け取り→広告→2倍）
  Future<void> _claimLoginBonusWithAd(BuildContext dialogContext) async {
    try {
      final loginBonusNotifier = ref.read(loginBonusStatusProvider.notifier);

      // まずログインボーナスを受け取る
      final result = await loginBonusNotifier.claimLoginBonus();
      final points = result['points'] as int;

      // ダイアログを閉じる
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      // 広告を表示
      await _adHelper.showRewardedAd(
        context: context,
        onRewarded: () async {
          try {
            // 広告視聴後、ポイントを2倍にする
            await loginBonusNotifier.multiplyPointsWithAd();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${points * 2}ポイント獲得しました！（広告視聴で2倍）'),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(
                    bottom: 100,
                    left: 20,
                    right: 20,
                  ),
                ),
              );
            }
            _adHelper.loadRewardedAd();
          } catch (e) {
            debugPrint('ポイントの2倍処理に失敗しました: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ポイントの2倍処理に失敗しました: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      );
    } catch (e) {
      // エラーが発生した場合はダイアログを閉じずにエラーメッセージを表示
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPromotionExamSection(BuildContext context, WidgetRef ref) {
    final totalPoints = ref.watch(totalPointsProvider);
    final userRank = ref.watch(userRankProvider);
    final unlockedDifficulties = ref.watch(unlockedDifficultiesProvider);

    // アンロック可能な昇格試験を取得
    final availableExams = <Map<String, dynamic>>[];

    // 各カテゴリと難易度の組み合わせをチェック
    final categories = [
      AppConstants.categoryRules,
      AppConstants.categoryHistory,
      AppConstants.categoryTeams,
    ];

    for (final category in categories) {
      // EASY→NORMAL
      final normalKey = UnlockKeyUtils.generateUnlockKey(
        category: category,
        difficulty: AppConstants.difficultyNormal,
        tags: category == AppConstants.categoryTeams ? 'teams,japan' : category,
      );
      if (!unlockedDifficulties.contains(normalKey)) {
        final exam = PromotionExam.easyToNormal(
          category: category,
          tags:
              category == AppConstants.categoryTeams ? 'teams,japan' : category,
        );
        if (userRank.index >= exam.requiredRank.index &&
            totalPoints >= exam.requiredPoints) {
          availableExams.add({
            'exam': exam,
            'category': category,
            'tags': category == AppConstants.categoryTeams
                ? 'teams,japan'
                : category,
            'targetDifficulty': AppConstants.difficultyNormal,
          });
        }
      }

      // NORMAL→HARD
      final hardKey = UnlockKeyUtils.generateUnlockKey(
        category: category,
        difficulty: AppConstants.difficultyHard,
        tags: category == AppConstants.categoryTeams ? 'teams,japan' : category,
      );
      if (!unlockedDifficulties.contains(hardKey) &&
          unlockedDifficulties.contains(normalKey)) {
        final exam = PromotionExam.normalToHard(
          category: category,
          tags:
              category == AppConstants.categoryTeams ? 'teams,japan' : category,
        );
        if (userRank.index >= exam.requiredRank.index &&
            totalPoints >= exam.requiredPoints) {
          availableExams.add({
            'exam': exam,
            'category': category,
            'tags': category == AppConstants.categoryTeams
                ? 'teams,japan'
                : category,
            'targetDifficulty': AppConstants.difficultyHard,
          });
        }
      }

      // HARD→EXTREME
      final extremeKey = UnlockKeyUtils.generateUnlockKey(
        category: category,
        difficulty: AppConstants.difficultyExtreme,
        tags: category == AppConstants.categoryTeams ? 'teams,japan' : category,
      );
      if (!unlockedDifficulties.contains(extremeKey) &&
          unlockedDifficulties.contains(hardKey)) {
        final exam = PromotionExam.hardToExtreme(
          category: category,
          tags:
              category == AppConstants.categoryTeams ? 'teams,japan' : category,
        );
        if (userRank.index >= exam.requiredRank.index &&
            totalPoints >= exam.requiredPoints) {
          availableExams.add({
            'exam': exam,
            'category': category,
            'tags': category == AppConstants.categoryTeams
                ? 'teams,japan'
                : category,
            'targetDifficulty': AppConstants.difficultyExtreme,
          });
        }
      }
    }

    if (availableExams.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            '昇格試験',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.techIndigo.withValues(alpha: 0.4),
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...availableExams.take(3).map((examData) {
          final exam = examData['exam'] as PromotionExam;
          final category = examData['category'] as String;
          final tags = examData['tags'] as String;
          final targetDifficulty = examData['targetDifficulty'] as String;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                final uri = Uri(
                  path: '/promotion-exam',
                  queryParameters: {
                    'category': category,
                    'tags': tags,
                    'targetDifficulty': targetDifficulty,
                  },
                );
                context.push(uri.toString());
              },
              child: GlassMorphismWidget(
                borderRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school,
                        color: Colors.amber.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exam.getTitle(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.techIndigo,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '必要ポイント: ${NumberFormat('#,###').format(exam.requiredPoints)} PT',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuestionUnlockSection(BuildContext context) {
    return _buildHistoryStatsButton(
      context,
      Icons.lock_open,
      '問題開放',
      Colors.purple.shade500,
      () => context.push('/question-unlock'),
    );
  }

  Widget _buildHistoryStatsButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: AppColors.techBlue.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.techIndigo,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateLevel(int totalExp) {
    // 簡単なレベル計算（500expごとにレベルアップ）
    return (totalExp / 500).floor() + 1;
  }

  String _getNextRankName(UserRank userRank) {
    const allRanks = UserRank.values;

    final currentIndex = allRanks.indexOf(userRank);
    if (currentIndex >= 0 && currentIndex < allRanks.length - 1) {
      return allRanks[currentIndex + 1].japaneseName;
    }
    return 'サッカーの神';
  }

  /// Weekly Recapデータをバックグラウンドで同期
  /// タイトル画面で既にダウンロード済みの場合はスキップ
  Future<void> _syncWeeklyRecapData(WidgetRef ref) async {
    try {
      final recapDataService = ref.read(recapDataServiceProvider);
      final latestMonday = AppDateUtils.getLatestMondayString();

      // 既に同期済みかチェック（タイトル画面で既にダウンロード済みの場合はスキップ）
      final isSynced = await recapDataService.isWeeklyRecapSynced(
        date: latestMonday,
      );

      if (isSynced) {
        debugPrint('Weekly Recap ($latestMonday) は既に同期済みのためスキップ');
        return;
      }

      final syncedCount = await recapDataService.syncWeeklyRecapToDatabase();

      // 新しいデータが同期された場合、通知を送信
      if (syncedCount > 0) {
        final notificationService = ref.read(notificationServiceProvider);

        // 通知権限を確認してから送信
        final hasPermission = await notificationService.isPermissionGranted();
        if (hasPermission) {
          // J1とヨーロッパの両方のデータがある場合は、両方の通知を送信
          // ただし、同じ日付の通知は1回だけ送信される（NotificationService内で制御）
          await notificationService.showWeeklyRecapNotification(
            date: latestMonday,
            leagueType: 'j1',
          );
          await notificationService.showWeeklyRecapNotification(
            date: latestMonday,
            leagueType: 'europe',
          );
        }
      }
    } catch (e) {
      // エラーは無視（ネットワークエラーなどは正常）
      // デバッグ時のみログ出力
      debugPrint('Weekly Recap自動同期エラー: $e');
    }
  }

  /// 拡大されたランクアイコンを表示するオーバーレイ
  Widget _buildExpandedRankOverlay(UserRank userRank) {
    // 画面サイズを取得
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = (screenWidth * 0.75).clamp(200.0, 350.0);

    return GestureDetector(
      onTap: () {
        setState(() {
          _isRankIconExpanded = false;
        });
      },
      child: Container(
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // アイコン自体のタップは無視（親のonTapを発火させない）
            child: AnimatedScale(
              scale: _isRankIconExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              child: AnimatedOpacity(
                opacity: _isRankIconExpanded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: RankIconWidget(
                  rank: userRank,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
