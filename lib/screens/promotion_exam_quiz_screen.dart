import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../constants/game_config.dart';
import '../models/question.dart';
import '../providers/question_service_provider.dart';
import '../providers/user_data_provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/glow_button.dart';
import '../widgets/responsive_container.dart';
import '../widgets/banner_ad_widget.dart';
import '../providers/admin_mode_provider.dart';
import '../services/promotion_exam_service.dart';
import '../providers/ad_provider.dart';
import '../providers/sound_service_provider.dart';
import '../utils/question_utils.dart';

class PromotionExamQuizScreen extends ConsumerStatefulWidget {
  final String category;
  final String sourceDifficulty;
  final String targetDifficulty;
  final String tags;
  final int? reservedPoints; // 仮徴収したPT

  const PromotionExamQuizScreen({
    super.key,
    required this.category,
    required this.sourceDifficulty,
    required this.targetDifficulty,
    required this.tags,
    this.reservedPoints,
  });

  @override
  ConsumerState<PromotionExamQuizScreen> createState() => _PromotionExamQuizScreenState();
}

class _PromotionExamQuizScreenState extends ConsumerState<PromotionExamQuizScreen> {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showAnswerResult = false;
  int _score = 0;
  bool _isLoading = true;
  int? _reservedPoints; // 仮徴収したPT

  @override
  void initState() {
    super.initState();
    // 仮徴収したPTを設定
    _reservedPoints = widget.reservedPoints;
    // PTを仮徴収（確定するまで保留）
    if (_reservedPoints != null && _reservedPoints! > 0) {
      _reservePoints();
    }
    _loadQuestions();
  }

  Future<void> _reservePoints() async {
    // 仮徴収は実際にはポイントを減らさず、結果画面で確定する
    // ここではチェックのみ
    final currentPoints = ref.read(totalPointsProvider);
    if (currentPoints < _reservedPoints!) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ポイントが不足しています'),
          backgroundColor: Colors.red,
        ),
      );
      context.pop();
    }
  }

  Future<void> _loadQuestions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final questionService = ref.read(questionServiceProvider);

      final questions = await questionService.getQuestions(
        category: widget.category,
        difficulty: widget.sourceDifficulty,
        tags: widget.tags,
        limit: AppConstants.promotionExamQuestionCount,
      );

      if (!mounted) return;

      // 管理者モードに応じて問題を処理（共通ロジックを使用）
      final adminMode = ref.read(adminModeProvider);
      final processedQuestions = QuestionUtils.processQuestionsForAdminMode(
        questions,
        adminMode,
      );

      setState(() {
        _questions = processedQuestions;
        _isLoading = false;
      });

      if (_questions.isNotEmpty) {
        unawaited(ref.read(soundServiceProvider).playQuizStart());
      }

      if (_questions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('問題が見つかりませんでした'),
              backgroundColor: Colors.red,
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('問題の読み込みに失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _selectAnswer(int index) {
    if (_showAnswerResult) return;

    setState(() {
      _selectedAnswerIndex = index;
      _showAnswerResult = true;
    });

    final isCorrect = index == _questions[_currentQuestionIndex].answerIndex;
    if (isCorrect) {
      _score++;
    }

    unawaited(ref.read(soundServiceProvider).playQuizResult(isCorrect));

    // 通常クイズ（quiz_screen）と同様、解説は即表示。遅延するとメイン画面に
    // 「次の問題へ」が一瞬映るため delay は使わない。
    if (mounted) {
      _showExplanationDialog();
    }
  }

  void _showExplanationDialog() {
    final question = _questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswerIndex == question.answerIndex;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: GlassMorphismWidget(
            borderRadius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: (isCorrect
                                  ? AppColors.stitchEmerald
                                  : Colors.red.shade400)
                              .withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (isCorrect
                                      ? AppColors.stitchEmerald
                                      : Colors.red.shade400)
                                  .withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect
                              ? AppColors.stitchEmerald
                              : Colors.red.shade400,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isCorrect ? '正解！' : '不正解',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isCorrect
                              ? AppColors.stitchEmerald
                              : Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isCorrect ? 'Excellent job' : 'Try again',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCorrect) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: AppColors.stitchEmerald.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.stitchEmerald.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.stitchEmerald,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '正解は ${String.fromCharCode(65 + question.answerIndex)}: ${question.options[question.answerIndex]}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.stitchEmerald,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description,
                              color: Colors.grey.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '解説',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.explanation,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        if (question.trivia != null && question.trivia!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: const BorderRadius.all(Radius.circular(16)),
                              border: Border.all(
                                color: Colors.amber.shade200,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.lightbulb,
                                      color: Colors.amber.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '豆知識',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  question.trivia!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
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
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: GlowButton(
                      glowColor: AppColors.stitchEmerald,
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (mounted) _nextQuestion();
                      },
                      backgroundColor: AppColors.stitchEmerald,
                      foregroundColor: Colors.white,
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _currentQuestionIndex == _questions.length - 1
                            ? '結果を見る'
                            : '次の問題へ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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

  void _nextQuestion() {
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    
    if (isLastQuestion) {
      _showResult();
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _showAnswerResult = false;
      });
    }
  }

  Future<void> _showResult() async {
    final examService = ref.read(promotionExamServiceProvider);
    final config = examService.getExamConfig(
      category: widget.category,
      targetDifficulty: widget.targetDifficulty,
    );

    if (config == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('昇格試験の設定が見つかりませんでした'),
          backgroundColor: Colors.red,
        ),
      );
      context.go('/');
      return;
    }

    final passed = _score >= AppConstants.promotionExamPassLine;

    if (!mounted) return;

    if (passed) {
      if (_reservedPoints != null && _reservedPoints! > 0) {
        await examService.handlePass(
          category: widget.category,
          targetDifficulty: widget.targetDifficulty,
          tags: widget.tags,
          reservedPoints: _reservedPoints!,
        );
      }
    } else {
      if (_reservedPoints != null && _reservedPoints! > 0) {
        await examService.handleFail(
          category: widget.category,
          targetDifficulty: widget.targetDifficulty,
        );
      }
    }

    if (!mounted) return;

    final cashbackPreview = examService.calculateFailForfeitCashback(
      category: widget.category,
      targetDifficulty: widget.targetDifficulty,
    );

    if (!mounted) return;

    _showPromotionResultGlassDialog(
      config: config,
      passed: passed,
      cashbackPreview: cashbackPreview,
    );
  }

  void _showPromotionResultGlassDialog({
    required UnlockDifficultyConfig config,
    required bool passed,
    required int cashbackPreview,
  }) {
    final nf = NumberFormat('#,###');
    var cashbackClaimed = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            const accentPass = AppColors.stitchEmerald;
            final accentFail = Colors.red.shade400;
            final targetName = widget.targetDifficulty.toUpperCase();

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                child: GlassMorphismWidget(
                  borderRadius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.88),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: (passed ? accentPass : accentFail)
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (passed ? accentPass : accentFail)
                                    .withValues(alpha: 0.35),
                                blurRadius: 18,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            passed ? Icons.emoji_events : Icons.school_outlined,
                            color: passed ? accentPass : accentFail,
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          passed ? '合格！' : '不合格',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: passed ? accentPass : accentFail,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_score / ${_questions.length} 問正解',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.techIndigo,
                          ),
                        ),
                        if (passed) ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: accentPass.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accentPass.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$targetName 難易度をアンロックしました',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.techIndigo,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ボーナス +${config.bonusExp} EXP  +${config.bonusPt} PT',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: accentPass.withValues(alpha: 0.95),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.deepOrange.shade200.withValues(alpha: 0.85),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${AppConstants.promotionExamPassLine}問以上正解で合格です',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.techIndigo,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'ウォレットから ${nf.format(config.forfeit)} PT が没収されました',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!cashbackClaimed && cashbackPreview > 0) ...[
                            const SizedBox(height: 16),
                            GlowButton(
                              glowColor: AppColors.stitchEmerald,
                              onPressed: () async {
                                final ok = await _watchFailCashbackAd();
                                if (ok && mounted) {
                                  cashbackClaimed = true;
                                  setDialogState(() {});
                                }
                              },
                              backgroundColor: AppColors.stitchEmerald,
                              foregroundColor: Colors.white,
                              borderRadius: 16,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 12,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.play_circle_outline,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '広告を見る',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '没収の ${nf.format(cashbackPreview)} PT を',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  const Text(
                                    'キャッシュバック',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '没収されたポイントの一部を広告視聴で還元します（1回のみ）',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                          if (cashbackClaimed && cashbackPreview > 0) ...[
                            const SizedBox(height: 12),
                            Text(
                              '+${nf.format(cashbackPreview)} PT をキャッシュバックしました',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.stitchEmerald,
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: GlowButton(
                            glowColor: AppColors.stitchEmerald,
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              context.go('/');
                            },
                            backgroundColor: AppColors.stitchEmerald,
                            foregroundColor: Colors.white,
                            borderRadius: 16,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: const Text(
                              'ホームに戻る',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
          },
        );
      },
    );
  }

  Future<bool> _watchFailCashbackAd() async {
    final adService = ref.read(adServiceProvider);

    if (!adService.isRewardedAdReady) {
      await adService.loadRewardedAd(
        onRewarded: (_, __) {},
        onError: (error) {
          debugPrint('広告読み込みエラー: $error');
        },
      );
    }

    if (!adService.isRewardedAdReady) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('広告の読み込みに失敗しました'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    final success = await adService.showRewardedAd(
      onRewarded: (_, __) {
        unawaited(
          ref.read(promotionExamServiceProvider).grantFailCashbackFromAd(
                category: widget.category,
                targetDifficulty: widget.targetDifficulty,
              ),
        );
      },
      onError: (error) {
        debugPrint('広告表示エラー: $error');
      },
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('広告を表示できませんでした'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    return success;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.stitchBackgroundLight,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.stitchBackgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.stitchEmerald.withValues(alpha: 0.9),
          elevation: 0,
          title: const Text(
            '昇格試験',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: Text('問題が見つかりませんでした'),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: AppColors.stitchBackgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.stitchEmerald.withValues(alpha: 0.9),
        elevation: 0,
        title: Text(
          '昇格試験 (${_currentQuestionIndex + 1} / ${_questions.length})',
          style: const TextStyle(
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
                // 進捗バー
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (_currentQuestionIndex + 1) / _questions.length,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.stitchEmerald,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 問題文
                GlassMorphismWidget(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    currentQuestion.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 選択肢
                ...currentQuestion.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = _selectedAnswerIndex == index;
                  final isAnswer = index == currentQuestion.answerIndex;

                  Color backgroundColor;
                  Color textColor;
                  Color borderColor;

                  if (_showAnswerResult) {
                    if (isAnswer) {
                      backgroundColor = Colors.green.shade50;
                      textColor = Colors.green.shade900;
                      borderColor = Colors.green;
                    } else if (isSelected && !isAnswer) {
                      backgroundColor = Colors.red.shade50;
                      textColor = Colors.red.shade900;
                      borderColor = Colors.red;
                    } else {
                      backgroundColor = Colors.grey.shade50;
                      textColor = Colors.grey.shade700;
                      borderColor = Colors.grey.shade300;
                    }
                  } else {
                    backgroundColor = isSelected
                        ? AppColors.stitchEmerald.withValues(alpha: 0.1)
                        : Colors.white;
                    textColor = isSelected
                        ? AppColors.stitchEmerald
                        : Colors.black87;
                    borderColor = isSelected
                        ? AppColors.stitchEmerald
                        : Colors.grey.shade300;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () => _selectAnswer(index),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: borderColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index), // A, B, C, D
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (_showAnswerResult && isAnswer)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            if (_showAnswerResult && isSelected && !isAnswer)
                              const Icon(
                                Icons.cancel,
                                color: Colors.red,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // 「次の問題へ」は解説ダイアログ内のみ（4択の下には出さない）
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
