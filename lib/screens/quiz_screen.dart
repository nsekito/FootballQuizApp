import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/question.dart';
import '../providers/question_service_provider.dart';
import '../services/remote_data_service.dart';
import '../utils/constants.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../constants/app_colors.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/glow_button.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String category;
  final String difficulty;
  final String country;
  final String region;
  final String range;
  final String? year; // ニュースクイズ用
  final String? date; // Weekly Recap用（YYYY-MM-DD形式）
  final String? leagueType; // Weekly Recap用（"j1" または "europe"）

  const QuizScreen({
    super.key,
    required this.category,
    required this.difficulty,
    this.country = '',
    this.region = '',
    this.range = '',
    this.year,
    this.date,
    this.leagueType,
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showResult = false;
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

      String? tags;
      if (widget.region.isNotEmpty) {
        tags = widget.region;
      } else if (widget.country.isNotEmpty) {
        tags = widget.country;
      }

      final questions = await questionService.getQuestions(
        category: widget.category,
        difficulty: widget.category == AppConstants.categoryMatchRecap 
            ? '' // Weekly Recapの場合は難易度を渡さない
            : widget.difficulty,
        tags: tags,
        country: widget.country.isNotEmpty ? widget.country : null,
        region: widget.region.isNotEmpty ? widget.region : null,
        range: widget.range.isNotEmpty ? widget.range : null,
        year: widget.year,
        date: widget.date,
        leagueType: widget.leagueType,
        limit: AppConstants.defaultQuestionsPerQuiz,
      );

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _isLoading = false;
      });

      if (_questions.isEmpty) {
        if (mounted) {
          showErrorDialog(
            context,
            title: 'データが見つかりません',
            message: '選択した条件に一致するクイズデータが見つかりませんでした。\n\n別の条件でお試しください。',
            showRetry: false,
            onClose: () => context.pop(),
          );
        }
      }
    } on RemoteDataException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showErrorDialog(
        context,
        title: 'データの取得に失敗しました',
        message: e.getUserFriendlyMessage(),
        showRetry: true,
        onRetry: () => _loadQuestions(),
        onClose: () => context.pop(),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      showErrorDialog(
        context,
        title: 'エラーが発生しました',
        message:
            'クイズデータの読み込み中にエラーが発生しました。\n\nエラー内容: ${e.toString()}\n\nもう一度お試しください。',
        showRetry: true,
        onRetry: () => _loadQuestions(),
        onClose: () => context.pop(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('クイズ'),
        ),
        body: const AppLoadingWidget(),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('クイズ'),
        ),
        body: const Center(
          child: Text('クイズデータがありません'),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.stitchBackgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'CURRENT QUESTION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '問題 ${_currentQuestionIndex + 1} / ${_questions.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: GridPatternBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 進捗バー
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: _currentQuestionIndex / _questions.length,
                  end: progress,
                ),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width * value,
                          decoration: BoxDecoration(
                            color: AppColors.stitchCyan,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.stitchCyan.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // 問題カード
              GlassMorphismWidget(
                borderRadius: 16,
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 対象年月の表示
                    if (currentQuestion.referenceDate != null &&
                        currentQuestion.referenceDate!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatReferenceDate(currentQuestion.referenceDate!),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      currentQuestion.text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 選択肢
              ...currentQuestion.options.asMap().entries.map((entry) {
                final index = entry.key;
                final option = entry.value;
                final isSelected = _selectedAnswerIndex == index;
                final isCorrect = _showResult
                    ? (index == currentQuestion.answerIndex
                        ? true
                        : isSelected ? false : null)
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuizChoiceButton(
                    text: option,
                    isSelected: isSelected,
                    isCorrect: isCorrect,
                    onTap: () => _selectAnswer(index),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // 次へ/結果へボタン
              if (_showResult)
                GlowButton(
                  glowColor: AppColors.stitchCyan,
                  onPressed: () => _nextQuestion(isLastQuestion),
                  backgroundColor: AppColors.stitchCyan,
                  foregroundColor: Colors.white,
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastQuestion ? '結果を見る' : '次の問題',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLastQuestion ? Icons.emoji_events : Icons.arrow_forward,
                        size: 20,
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

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswerIndex = index;
      _showResult = true;

      if (index == _questions[_currentQuestionIndex].answerIndex) {
        _score++;
      }
    });

    _showExplanationDialog();
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

  void _nextQuestion(bool isLastQuestion) {
    if (isLastQuestion) {
      final earnedPoints = _score * AppConstants.pointsPerCorrectAnswer;
      final totalPoints = _score == _questions.length
          ? earnedPoints + AppConstants.pointsPerfectScoreBonus
          : earnedPoints;

      final uri = Uri(
        path: '/result',
        queryParameters: {
          'score': '$_score',
          'total': '${_questions.length}',
          'points': '$totalPoints',
          'category': widget.category,
          'difficulty': widget.difficulty,
        },
      );
      context.push(uri.toString());
    } else {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = null;
        _showResult = false;
      });
    }
  }

  String _formatReferenceDate(String referenceDate) {
    if (referenceDate.isEmpty) return '';

    if (referenceDate.contains('-')) {
      final parts = referenceDate.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final month = parts[1];
        return '対象: $year年$month月時点';
      }
    }

    if (referenceDate.length == 4 &&
        RegExp(r'^\d{4}$').hasMatch(referenceDate)) {
      return '対象: $referenceDate年時点';
    }

    return '対象: $referenceDate';
  }
}

/// Quiz Screen用の選択肢ボタン
class _QuizChoiceButton extends StatefulWidget {
  final String text;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback onTap;

  const _QuizChoiceButton({
    required this.text,
    required this.isSelected,
    this.isCorrect,
    required this.onTap,
  });

  @override
  State<_QuizChoiceButton> createState() => _QuizChoiceButtonState();
}

class _QuizChoiceButtonState extends State<_QuizChoiceButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color? glowColor;

    if (widget.isCorrect == true) {
      borderColor = AppColors.stitchEmerald;
      glowColor = AppColors.stitchEmerald;
    } else if (widget.isCorrect == false) {
      borderColor = Colors.red.shade400;
      glowColor = Colors.red.shade400;
    } else if (widget.isSelected) {
      borderColor = AppColors.stitchCyan;
      glowColor = AppColors.stitchCyan;
    } else {
      borderColor = Colors.grey.shade300;
      glowColor = null;
    }

    return GestureDetector(
      onTap: widget.isCorrect == null ? widget.onTap : null,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: GlassMorphismWidget(
          borderRadius: 16,
          backgroundColor: Colors.white.withValues(alpha: 0.4),
          borderColor: _isHovered && widget.isCorrect == null
              ? AppColors.stitchCyan
              : borderColor,
          boxShadow: glowColor != null
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ]
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isHovered && widget.isCorrect == null)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.stitchCyan,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
