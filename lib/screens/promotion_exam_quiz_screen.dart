import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/question.dart';
import '../providers/question_service_provider.dart';
import '../providers/user_data_provider.dart';
import '../utils/constants.dart';
import '../utils/unlock_key_utils.dart';
import '../constants/app_colors.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/glow_button.dart';
import '../widgets/responsive_container.dart';
import '../widgets/banner_ad_widget.dart';

class PromotionExamQuizScreen extends ConsumerStatefulWidget {
  final String category;
  final String sourceDifficulty;
  final String targetDifficulty;
  final String tags;

  const PromotionExamQuizScreen({
    super.key,
    required this.category,
    required this.sourceDifficulty,
    required this.targetDifficulty,
    required this.tags,
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

  @override
  void initState() {
    super.initState();
    _loadQuestions();
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

      setState(() {
        _questions = questions;
        _isLoading = false;
      });

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

    // 解説ダイアログを表示
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showExplanationDialog();
      }
    });
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
              Padding(
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
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  child: GlowButton(
                    glowColor: AppColors.stitchEmerald,
                    onPressed: () => Navigator.of(context).pop(),
                    backgroundColor: AppColors.stitchEmerald,
                    foregroundColor: Colors.white,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Text(
                      '閉じる',
                      style: TextStyle(
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
    final passed = _score >= AppConstants.promotionExamPassScore;
    
    if (!mounted) return;

    // 合格した場合、難易度をアンロック
    if (passed) {
      final unlockKey = UnlockKeyUtils.generateUnlockKey(
        category: widget.category,
        difficulty: widget.targetDifficulty,
        tags: widget.tags,
      );
      await ref.read(unlockedDifficultiesProvider.notifier).unlockDifficulty(unlockKey);
    }

    // 非同期処理後に再度mountedチェック
    if (!mounted) return;

    // 結果ダイアログを表示
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          passed ? '合格！' : '不合格',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: passed ? Colors.green : Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_score問 / ${_questions.length}問正解',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (passed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.targetDifficulty.toUpperCase()}難易度をアンロックしました！',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.cancel,
                      color: Colors.orange,
                      size: 48,
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${AppConstants.promotionExamPassScore}問以上正解で合格です',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('ホームに戻る'),
          ),
        ],
      ),
    );
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

                const SizedBox(height: 24),

                // 次へボタン
                if (_showAnswerResult)
                  GlowButton(
                    glowColor: AppColors.stitchEmerald,
                    onPressed: _nextQuestion,
                    backgroundColor: AppColors.stitchEmerald,
                    foregroundColor: Colors.white,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentQuestionIndex == _questions.length - 1
                              ? '結果を見る'
                              : '次の問題へ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
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
}
