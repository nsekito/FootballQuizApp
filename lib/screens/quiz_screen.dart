import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/question.dart';
import '../providers/question_service_provider.dart';
import '../services/remote_data_service.dart';
import '../utils/constants.dart';
import '../widgets/error_widget.dart';
import '../widgets/loading_widget.dart';
import '../widgets/quiz_choice_card.dart';
import '../constants/app_colors.dart';
import '../widgets/background_widget.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String category;
  final String difficulty;
  final String country;
  final String region;
  final String range;
  final String? year; // ニュースクイズ用
  final String? date; // Weekly Recap用（YYYY-MM-DD形式）

  const QuizScreen({
    super.key,
    required this.category,
    required this.difficulty,
    this.country = '',
    this.region = '',
    this.range = '',
    this.year,
    this.date,
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

      // タグの構築（国と地域から）
      String? tags;
      if (widget.region.isNotEmpty) {
        tags = widget.region;
      } else if (widget.country.isNotEmpty) {
        tags = widget.country;
      }

      final questions = await questionService.getQuestions(
        category: widget.category,
        difficulty: widget.difficulty,
        tags: tags,
        country: widget.country.isNotEmpty ? widget.country : null,
        region: widget.region.isNotEmpty ? widget.region : null,
        range: widget.range.isNotEmpty ? widget.range : null,
        year: widget.year,
        date: widget.date,
        limit: AppConstants.defaultQuestionsPerQuiz,
      );

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _isLoading = false;
      });

      // データがない場合の処理
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

    return Scaffold(
      appBar: AppBar(
        title: Text('問題 ${_currentQuestionIndex + 1} / ${_questions.length}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Stack(
          children: [
            // 背景画像
            Image.asset(
              'assets/images/03_Backgrounds/header_background_pattern.png',
              width: double.infinity,
              height: double.infinity,
              repeat: ImageRepeat.repeat,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: AppColors.primary);
              },
            ),
            // オーバーレイ
            Container(
              color: AppColors.primary.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
      body: AppBackgroundWidget(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 進捗バー
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
              ),
              const SizedBox(height: 24),

              // 対象年月の表示（存在する場合）
              if (currentQuestion.referenceDate != null &&
                  currentQuestion.referenceDate!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatReferenceDate(currentQuestion.referenceDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),

              // 問題文
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    currentQuestion.text,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                        : (isSelected ? false : null))
                    : null;

                return QuizChoiceCard(
                  text: option,
                  isSelected: isSelected,
                  isCorrect: isCorrect,
                  onTap: () => _selectAnswer(index),
                );
              }),

              const SizedBox(height: 24),

              // 次へ/結果へボタン
              if (_showResult)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton(
                    onPressed: () => _nextQuestion(isLastQuestion),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      isLastQuestion ? '結果を見る' : '次の問題',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswerIndex = index;
      _showResult = true;

      // 正解かどうかを判定
      if (index == _questions[_currentQuestionIndex].answerIndex) {
        _score++;
      }
    });

    // 解説ダイアログを表示
    _showExplanationDialog();
  }

  void _showExplanationDialog() {
    final question = _questions[_currentQuestionIndex];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text(
                      '解説',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.explanation,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (question.trivia != null && question.trivia!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.lightbulb,
                                color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              '豆知識',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('閉じる'),
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
      // 結果画面へ遷移
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

  /// 対象年月をフォーマット（YYYYまたはYYYY-MM形式を「YYYY年時点」または「YYYY年MM月時点」に変換）
  String _formatReferenceDate(String referenceDate) {
    if (referenceDate.isEmpty) return '';

    // YYYY-MM形式の場合
    if (referenceDate.contains('-')) {
      final parts = referenceDate.split('-');
      if (parts.length == 2) {
        final year = parts[0];
        final month = parts[1];
        return '対象: $year年$month月時点';
      }
    }

    // YYYY形式の場合
    if (referenceDate.length == 4 &&
        RegExp(r'^\d{4}$').hasMatch(referenceDate)) {
      return '対象: $referenceDate年時点';
    }

    // その他の形式はそのまま返す
    return '対象: $referenceDate';
  }
}

