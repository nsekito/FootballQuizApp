import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/promotion_exam.dart';
import '../models/user_rank.dart';
import '../providers/user_data_provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/glow_button.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/responsive_container.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/promotion_exam_service.dart';

class PromotionExamScreen extends ConsumerStatefulWidget {
  final String category;
  final String tags;
  final String targetDifficulty;

  const PromotionExamScreen({
    super.key,
    required this.category,
    required this.tags,
    required this.targetDifficulty,
  });

  @override
  ConsumerState<PromotionExamScreen> createState() => _PromotionExamScreenState();
}

class _PromotionExamScreenState extends ConsumerState<PromotionExamScreen> {
  PromotionExam? _exam;
  bool _isLoading = true;
  bool _canTakeExam = false;

  @override
  void initState() {
    super.initState();
    _initializeExam();
  }

  void _initializeExam() {
    PromotionExam? exam;
    
    switch (widget.targetDifficulty) {
      case AppConstants.difficultyNormal:
        exam = PromotionExam.easyToNormal(
          category: widget.category,
          tags: widget.tags,
        );
        break;
      case AppConstants.difficultyHard:
        exam = PromotionExam.normalToHard(
          category: widget.category,
          tags: widget.tags,
        );
        break;
      case AppConstants.difficultyExtreme:
        exam = PromotionExam.hardToExtreme(
          category: widget.category,
          tags: widget.tags,
        );
        break;
    }
    
    setState(() {
      _exam = exam;
      _isLoading = false;
    });
    
    _checkExamRequirements();
  }

  Future<void> _checkExamRequirements() async {
    if (_exam == null) return;
    
    final totalExp = ref.read(totalExpProvider);
    final totalPoints = ref.read(totalPointsProvider);
    final userRank = UserRank.fromExp(totalExp);
    
    final hasRequiredRank = userRank.rankIndex >= _exam!.requiredRank.rankIndex;
    final hasRequiredPoints = totalPoints >= _exam!.requiredPoints;
    
    setState(() {
      _canTakeExam = hasRequiredRank && hasRequiredPoints;
    });
  }

  Future<void> _startExam() async {
    if (_exam == null || !_canTakeExam) return;

    final currentPoints = ref.read(totalPointsProvider);
    if (currentPoints < _exam!.requiredPoints) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ポイントが不足しています: ${_exam!.requiredPoints} PT必要'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final examService = ref.read(promotionExamServiceProvider);
    final unlockCfg = examService.getExamConfig(
      category: widget.category,
      targetDifficulty: widget.targetDifficulty,
    );

    final requiredPt = _exam!.requiredPoints;
    final nf = NumberFormat('#,###');

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: GlassMorphismWidget(
          borderRadius: 24,
          backgroundColor: Colors.white.withValues(alpha: 0.92),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.paid_outlined, color: AppColors.stitchEmerald, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'ポイントの確認',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.techIndigo,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '参加に必要なポイント',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${nf.format(requiredPt)} PT',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.stitchEmerald,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'クイズ終了後に確定します。合格時は上記のポイントが消費され、ボーナスが付与されます。',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (unlockCfg != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.stitchEmerald.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.stitchEmerald.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '不合格の場合',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '・不合格時: ウォレットから ${nf.format(unlockCfg.forfeit)} PT が没収されます',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.4),
                        ),
                        Text(
                          '（参加に必要な ${nf.format(requiredPt)} PT は開始前に引かれません）',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        child: Text('キャンセル', style: TextStyle(color: Colors.grey.shade800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlowButton(
                        glowColor: AppColors.stitchEmerald,
                        onPressed: () => Navigator.of(ctx).pop(true),
                        backgroundColor: AppColors.stitchEmerald,
                        foregroundColor: Colors.white,
                        borderRadius: 14,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: const Text(
                          '試験を開始',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final uri = Uri(
      path: '/promotion-exam-quiz',
      queryParameters: {
        'category': widget.category,
        'sourceDifficulty': _exam!.sourceDifficulty,
        'targetDifficulty': widget.targetDifficulty,
        'tags': widget.tags,
        'reservedPoints': _exam!.requiredPoints.toString(),
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _exam == null) {
      return const Scaffold(
        backgroundColor: AppColors.stitchBackgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.stitchEmerald),
        ),
      );
    }

    final totalPoints = ref.watch(totalPointsProvider);
    final totalExp = ref.watch(totalExpProvider);
    final userRank = ref.watch(userRankProvider);

    final hasRequiredRank = userRank.rankIndex >= _exam!.requiredRank.rankIndex;
    final hasRequiredPoints = totalPoints >= _exam!.requiredPoints;
    final expShortage = hasRequiredRank
        ? 0
        : (_exam!.requiredRank.minExp - totalExp).clamp(0, 999999);
    final ptShortage =
        hasRequiredPoints ? 0 : (_exam!.requiredPoints - totalPoints).clamp(0, 999999);

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.stitchBackgroundLight,
      body: Column(
        children: [
          // 緑バナー: トロフィー + タイトル
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, topPadding + 24, 16, 24),
            decoration: const BoxDecoration(
              color: AppColors.stitchEmerald,
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.accent,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  _exam!.getTitle().replaceAll(' 昇格試験', ''),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  '昇格試験',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // 白ナビバー: 戻る | ホーム
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
                  onPressed: () => context.pop(),
                  tooltip: '戻る',
                ),
                IconButton(
                  icon: Icon(Icons.home, color: Colors.grey.shade800),
                  onPressed: () => context.go('/'),
                  tooltip: 'ホームへ戻る',
                ),
              ],
            ),
          ),
          // メインコンテンツ
          Expanded(
            child: GridPatternBackground(
              child: SingleChildScrollView(
                child: ResponsiveContainer(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 試験説明（プレーンテキスト）
                      Text(
                        _exam!.getDescription(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 24),

                      // 試験詳細カード（白カード＋ピルバッジ）
                      _buildExamDetailCard(),
                      const SizedBox(height: 24),

                      // 受講に必要な条件
                      const Text(
                        '受講に必要な条件',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.techIndigo,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 前提条件カード（未達成時のみ）
                      if (!_canTakeExam)
                        _buildPrerequisiteCard(
                          hasRequiredRank: hasRequiredRank,
                          hasRequiredPoints: hasRequiredPoints,
                          expShortage: expShortage,
                          ptShortage: ptShortage,
                          userRank: userRank,
                          totalPoints: totalPoints,
                        ),
                      if (!_canTakeExam) const SizedBox(height: 24),

                      // 試験開始ボタン
                      GlowButton(
                        glowColor: AppColors.stitchEmerald,
                        onPressed: _canTakeExam ? _startExam : null,
                        backgroundColor: AppColors.stitchEmerald,
                        foregroundColor: Colors.white,
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '試験を開始する',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                          ],
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
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildExamDetailCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(
            '問題数',
            '${_exam!.questionCount}問',
            Icons.assignment,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            '合格条件',
            '${_exam!.passScore}問以上正解',
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            '出題難易度',
            _exam!.sourceDifficulty.toUpperCase(),
            Icons.show_chart,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.stitchEmerald, size: 24),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.stitchEmerald.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.stitchEmerald,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrerequisiteCard({
    required bool hasRequiredRank,
    required bool hasRequiredPoints,
    required int expShortage,
    required int ptShortage,
    required UserRank userRank,
    required int totalPoints,
  }) {
    final lines = <Widget>[];

    if (!hasRequiredRank) {
      lines.addAll([
        const Text('必要なランク', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 4),
        Text('必要:${_exam!.requiredRank.japaneseName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 2),
        Text('現在:${userRank.japaneseName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 4),
        Text('あと${NumberFormat('#,###').format(expShortage)} EXPで「${_exam!.requiredRank.japaneseName}」になれます', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange.shade900)),
      ]);
      if (!hasRequiredPoints) lines.add(const SizedBox(height: 16));
    }
    if (!hasRequiredPoints) {
      lines.addAll([
        const Text('必要なポイント', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 4),
        Text('必要:${NumberFormat('#,###').format(_exam!.requiredPoints)} PT', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 2),
        Text('現在:${NumberFormat('#,###').format(totalPoints)} PT', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 4),
        Text('あと${NumberFormat('#,###').format(ptShortage)} PT必要', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange.shade900)),
      ]);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines,
            ),
          ),
        ],
      ),
    );
  }
}
