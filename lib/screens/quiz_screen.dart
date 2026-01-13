import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/question.dart';
import '../providers/database_provider.dart';
import '../utils/constants.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String category;
  final String difficulty;
  final String country;
  final String region;
  final String range;

  const QuizScreen({
    super.key,
    required this.category,
    required this.difficulty,
    this.country = '',
    this.region = '',
    this.range = '',
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
  List<String> _usedQuestionIds = [];

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

      final databaseService = ref.read(databaseServiceProvider);
      
      // タグの構築（国と地域から）
      String? tags;
      if (widget.region.isNotEmpty) {
        tags = widget.region;
      } else if (widget.country.isNotEmpty) {
        tags = widget.country;
      }
      
      final questions = await databaseService.getQuestionsOptimized(
        category: widget.category,
        difficulty: widget.difficulty,
        tags: tags,
        country: widget.country.isNotEmpty ? widget.country : null,
        range: widget.range.isNotEmpty ? widget.range : null,
        limit: AppConstants.defaultQuestionsPerQuiz,
      );

      // 使用した問題IDを記録
      _usedQuestionIds = questions.map((q) => q.id).toList();

      if (!mounted) return;

      setState(() {
        _questions = questions;
        _isLoading = false;
      });

      // データがない場合の処理
      if (_questions.isEmpty) {
        if (mounted) {
          _showErrorDialog(
            context,
            title: 'データが見つかりません',
            message: '選択した条件に一致するクイズデータが見つかりませんでした。\n\n別の条件でお試しください。',
            showRetry: false,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog(
        context,
        title: 'エラーが発生しました',
        message: 'クイズデータの読み込み中にエラーが発生しました。\n\nエラー内容: ${e.toString()}\n\nもう一度お試しください。',
        showRetry: true,
        onRetry: () => _loadQuestions(),
      );
    }
  }

  void _showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool showRetry = false,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          if (showRetry && onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('再試行'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('戻る'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('クイズ'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
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
                final isCorrect = index == currentQuestion.answerIndex;
                final showResult = _showResult;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    onPressed: _showResult ? null : () => _selectAnswer(index),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: showResult
                          ? (isCorrect
                              ? Colors.green.shade100
                              : (isSelected ? Colors.red.shade100 : null))
                          : (isSelected ? Colors.blue.shade100 : null),
                      foregroundColor: showResult
                          ? (isCorrect
                              ? Colors.green.shade900
                              : (isSelected ? Colors.red.shade900 : null))
                          : null,
                    ),
                    child: Row(
                      children: [
                        if (showResult && isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (showResult && isSelected && !isCorrect)
                          const Icon(Icons.cancel, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),

              // 次へ/結果へボタン
              if (_showResult)
                ElevatedButton(
                  onPressed: () => _nextQuestion(isLastQuestion),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isLastQuestion ? '結果を見る' : '次の問題'),
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
      builder: (context) => AlertDialog(
        title: const Text('解説'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                    Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 20),
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('閉じる'),
          ),
        ],
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
}
