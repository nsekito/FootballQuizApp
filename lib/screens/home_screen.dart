import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/user_data_provider.dart';
import '../providers/sample_data_provider.dart';
import '../providers/recap_data_provider.dart';
import '../utils/constants.dart';
import '../constants/app_colors.dart';
import '../models/user_rank.dart';
import '../widgets/responsive_container.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasSyncedRecap = false;

  @override
  void initState() {
    super.initState();
    // Weekly Recapデータの自動同期（バックグラウンドで実行）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasSyncedRecap) {
        _hasSyncedRecap = true;
        _syncWeeklyRecapData(ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // サンプルデータの初期化を確認
    ref.watch(sampleDataInitializedProvider);

    final totalPoints = ref.watch(totalPointsProvider);
    final userRank = ref.watch(userRankProvider);

    return Scaffold(
      backgroundColor: AppColors.techWhite,
      body: SafeArea(
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(context),
            
            // メインコンテンツ
            Expanded(
              child: SingleChildScrollView(
                child: ResponsiveContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Featured Card (MATCH DAY)
                      _buildFeaturedCard(context),
                      const SizedBox(height: 24),

                      // ユーザー情報カード
                      _buildUserInfoCard(context, ref, totalPoints, userRank),
                      const SizedBox(height: 24),

                      // カテゴリ選択セクション
                      _buildCategorySection(context),
                      const SizedBox(height: 24),

                      // 履歴と統計
                      _buildHistoryAndStatsSection(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // ボトムナビゲーション
      bottomNavigationBar: _buildBottomNav(context),
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
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.slate100,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(BorderSide(color: AppColors.slate200)),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.slate500,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/configuration?category=${AppConstants.categoryMatchRecap}');
      },
      child: Container(
        height: 192,
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
              // 背景画像の代わりにグラデーション
              Container(
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
              ),
              // コンテンツ
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.techBlue,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'MATCH DAY',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '最新の試合結果をクイズで分析',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'START MISSION',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.techIndigo,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.play_circle_outline,
                            color: AppColors.techIndigo,
                            size: 18,
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
      ),
    );
  }

  Widget _buildUserInfoCard(
    BuildContext context,
    WidgetRef ref,
    int totalPoints,
    dynamic userRank,
  ) {
    final progressValue = userRank.maxPoints != null
        ? (totalPoints - userRank.minPoints) / (userRank.maxPoints! - userRank.minPoints)
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF3B82F6), Color(0xFF4F46E5)],
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${_calculateLevel(totalPoints)}',
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
                      Text(
                        NumberFormat('#,###').format(totalPoints),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.techIndigo,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'GP',
                        style: TextStyle(
                          fontSize: 12,
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
                userRank.maxPoints != null
                    ? 'Next: ${_getNextRankName(userRank)}'
                    : '最高ランク達成',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                ),
              ),
              if (userRank.maxPoints != null)
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

  Widget _buildCategorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            'SELECT CATEGORY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.techIndigo.withValues(alpha: 0.4),
              letterSpacing: 1.2,
            ),
          ),
        ),
        _buildCategoryButton(
          context,
          'ルールクイズ',
          '基本からマニアックな規定まで',
          Icons.gavel,
          Colors.blue,
          AppColors.techBlue,
          AppConstants.categoryRules,
        ),
        const SizedBox(height: 12),
        _buildCategoryButton(
          context,
          '歴史クイズ',
          '伝説のプレーヤーと大会の記録',
          Icons.auto_stories,
          Colors.amber,
          Colors.amber.shade500,
          AppConstants.categoryHistory,
        ),
        const SizedBox(height: 12),
        _buildCategoryButton(
          context,
          'チームクイズ',
          '欧州・国内リーグのクラブ知識',
          Icons.groups,
          Colors.purple,
          Colors.purple.shade500,
          AppConstants.categoryTeams,
        ),
        const SizedBox(height: 12),
        _buildCategoryButton(
          context,
          'ニュースクイズ',
          '今、サッカー界で起きていること',
          Icons.newspaper,
          Colors.cyan,
          Colors.cyan.shade500,
          AppConstants.categoryNews,
        ),
      ],
    );
  }

  Widget _buildCategoryButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color iconBgColor,
    Color iconColor,
    String category,
  ) {
    return _CategoryButton(
      title: title,
      subtitle: subtitle,
      icon: icon,
      iconBgColor: iconBgColor,
      iconColor: iconColor,
      onTap: () {
        context.push('/configuration?category=$category');
      },
    );
  }

  Widget _buildHistoryAndStatsSection(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildHistoryStatsButton(
            context,
            Icons.history,
            'クイズ履歴',
            AppColors.techBlue,
            () => context.push('/history'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildHistoryStatsButton(
            context,
            Icons.insights,
            '統計情報',
            AppColors.techGreen,
            () => context.push('/statistics'),
          ),
        ),
      ],
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


  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        border: const Border(
          top: BorderSide(color: AppColors.slate100, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(Icons.home, 'Home', true),
          _buildNavItem(Icons.leaderboard, 'Rank', false),
          Container(
            margin: const EdgeInsets.only(bottom: 40),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.techBlue,
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.techBlue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
          _buildNavItem(Icons.shopping_bag, 'Shop', false),
          _buildNavItem(Icons.settings, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.techBlue : AppColors.slate500,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.techBlue : AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateLevel(int totalPoints) {
    // 簡単なレベル計算（500ポイントごとにレベルアップ）
    return (totalPoints / 500).floor() + 1;
  }

  String _getNextRankName(dynamic userRank) {
    final allRanks = [
      UserRank.academy,
      UserRank.rookie,
      UserRank.regular,
      UserRank.fantasista,
      UserRank.legend,
    ];
    
    final currentIndex = allRanks.indexOf(userRank);
    if (currentIndex >= 0 && currentIndex < allRanks.length - 1) {
      return allRanks[currentIndex + 1].japaneseName;
    }
    return 'レジェンド';
  }

  /// Weekly Recapデータをバックグラウンドで同期
  Future<void> _syncWeeklyRecapData(WidgetRef ref) async {
    try {
      final recapDataService = ref.read(recapDataServiceProvider);
      await recapDataService.syncWeeklyRecapToDatabase();
    } catch (e) {
      // エラーは無視（ネットワークエラーなどは正常）
      // デバッグ時のみログ出力
      debugPrint('Weekly Recap自動同期エラー: $e');
    }
  }
}

class _CategoryButton extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_CategoryButton> createState() => _CategoryButtonState();
}

class _CategoryButtonState extends State<_CategoryButton> {
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
                color: _isHovered ? widget.iconColor : widget.iconBgColor.withValues(alpha: 0.1),
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
            const Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+150 XP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.techGreen,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.slate200,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
