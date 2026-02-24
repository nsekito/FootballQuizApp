import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/question_unlock_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/responsive_container.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/app_bar_background.dart';
import '../models/question.dart';
import '../utils/category_difficulty_utils.dart';

class QuestionViewScreen extends ConsumerWidget {
  final String questionId;

  const QuestionViewScreen({
    super.key,
    required this.questionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionAsync = ref.watch(questionByIdProvider(questionId));
    final unlockedQuestionsAsync = ref.watch(unlockedQuestionsProvider);

    return Scaffold(
      backgroundColor: AppColors.stitchBackgroundLight,
      appBar: buildAppBarWithBackground(
        title: '問題詳細',
      ),
      body: GridPatternBackground(
        child: questionAsync.when(
          data: (question) {
            if (question == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text('問題が見つかりません'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('戻る'),
                    ),
                  ],
                ),
              );
            }

            return unlockedQuestionsAsync.when(
              data: (unlockedQuestions) {
                final currentIndex =
                    unlockedQuestions.indexWhere((q) => q.id == questionId);
                final hasPrevious = currentIndex > 0;
                final hasNext = currentIndex < unlockedQuestions.length - 1;

                return SingleChildScrollView(
                  child: ResponsiveContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 問題カード
                        _buildQuestionCard(question),

                        const SizedBox(height: 16),

                        // ナビゲーションボタン
                        if (unlockedQuestions.length > 1)
                          _buildNavigationButtons(
                            context,
                            unlockedQuestions,
                            currentIndex,
                            hasPrevious,
                            hasNext,
                          ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => const Center(child: Text('エラーが発生しました')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('エラー: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('戻る'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return GlassMorphismWidget(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カテゴリと難易度
          Row(
            children: [
              _buildInfoChip(
                CategoryDifficultyUtils.getCategoryName(question.category),
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                CategoryDifficultyUtils.getDifficultyName(question.difficulty),
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 問題文
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.techIndigo,
            ),
          ),
          const SizedBox(height: 24),

          // 選択肢
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isCorrect = index == question.answerIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.green
                        : Colors.grey.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green
                            : Colors.grey.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isCorrect ? Colors.white : Colors.grey.shade700,
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
                          fontWeight:
                              isCorrect ? FontWeight.w600 : FontWeight.normal,
                          color: isCorrect
                              ? Colors.green.shade900
                              : Colors.black87,
                        ),
                      ),
                    ),
                    if (isCorrect)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // 解説
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.techBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: AppColors.techBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '解説',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.techBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.explanation,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // 豆知識
          if (question.trivia != null && question.trivia!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '豆知識',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    question.trivia!,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    List<Question> questions,
    int currentIndex,
    bool hasPrevious,
    bool hasNext,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton.icon(
          onPressed: hasPrevious
              ? () {
                  final previousQuestion = questions[currentIndex - 1];
                  context.pushReplacement(
                    '/question-view?questionId=${previousQuestion.id}',
                  );
                }
              : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('前の問題'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.techBlue,
            foregroundColor: Colors.white,
          ),
        ),
        Text(
          '${currentIndex + 1} / ${questions.length}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        ElevatedButton.icon(
          onPressed: hasNext
              ? () {
                  final nextQuestion = questions[currentIndex + 1];
                  context.pushReplacement(
                    '/question-view?questionId=${nextQuestion.id}',
                  );
                }
              : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('次の問題'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.techBlue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
