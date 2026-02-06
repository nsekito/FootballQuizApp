import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/promotion_exam.dart';
import '../models/user_rank.dart';
import '../providers/user_data_provider.dart';
import '../utils/constants.dart';
import '../constants/app_colors.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/glow_button.dart';
import '../widgets/responsive_container.dart';
import '../widgets/banner_ad_widget.dart';

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
  String? _errorMessage;

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
    
    final hasRequiredRank = userRank.index >= _exam!.requiredRank.index;
    final hasRequiredPoints = totalPoints >= _exam!.requiredPoints;
    
    setState(() {
      _canTakeExam = hasRequiredRank && hasRequiredPoints;
      if (!hasRequiredRank) {
        _errorMessage = '必要なランク: ${_exam!.requiredRank.japaneseName}';
      } else if (!hasRequiredPoints) {
        _errorMessage = '必要なポイント: ${NumberFormat('#,###').format(_exam!.requiredPoints)} PT';
      }
    });
  }

  Future<void> _startExam() async {
    if (_exam == null || !_canTakeExam) return;
    
    // ポイントを消費
    try {
      await ref.read(totalPointsProvider.notifier).consumePoints(_exam!.requiredPoints);
      
      if (!mounted) return;
      
      // 昇格試験クイズ画面に遷移
      final uri = Uri(
        path: '/promotion-exam-quiz',
        queryParameters: {
          'category': widget.category,
          'sourceDifficulty': _exam!.sourceDifficulty,
          'targetDifficulty': widget.targetDifficulty,
          'tags': widget.tags,
        },
      );
      context.push(uri.toString());
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ポイントが不足しています: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _exam == null) {
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
            '昇格試験',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final totalPoints = ref.watch(totalPointsProvider);
    final userRank = ref.watch(userRankProvider);

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
          '昇格試験',
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
                // 試験タイトル
                GlassMorphismWidget(
                  borderRadius: 24,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        _exam!.getTitle(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.stitchEmerald,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _exam!.getDescription(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 試験詳細
                GlassMorphismWidget(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRequirementRow(
                        '問題数',
                        '${_exam!.questionCount}問',
                        Icons.quiz,
                      ),
                      const SizedBox(height: 12),
                      _buildRequirementRow(
                        '合格条件',
                        '${_exam!.passScore}問以上正解',
                        Icons.check_circle,
                      ),
                      const SizedBox(height: 12),
                      _buildRequirementRow(
                        '出題難易度',
                        _exam!.sourceDifficulty.toUpperCase(),
                        Icons.bar_chart,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 必要条件
                GlassMorphismWidget(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '必要条件',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRequirementCheck(
                        '必要なランク',
                        _exam!.requiredRank.japaneseName,
                        userRank.index >= _exam!.requiredRank.index,
                        userRank.japaneseName,
                      ),
                      const SizedBox(height: 12),
                      _buildRequirementCheck(
                        '必要なポイント',
                        '${NumberFormat('#,###').format(_exam!.requiredPoints)} PT',
                        totalPoints >= _exam!.requiredPoints,
                        '${NumberFormat('#,###').format(totalPoints)} PT',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // エラーメッセージまたは開始ボタン
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GlowButton(
                    glowColor: AppColors.stitchEmerald,
                    onPressed: _canTakeExam ? _startExam : null,
                    backgroundColor: AppColors.stitchEmerald,
                    foregroundColor: Colors.white,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_outline, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '試験を開始する (${NumberFormat('#,###').format(_exam!.requiredPoints)} PT消費)',
                          style: const TextStyle(
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
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildRequirementRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.stitchEmerald, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.stitchEmerald,
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementCheck(
    String label,
    String required,
    bool isMet,
    String current,
  ) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.cancel,
          color: isMet ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '必要: $required',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                '現在: $current',
                style: TextStyle(
                  fontSize: 12,
                  color: isMet ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
