import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/quiz_history_provider.dart';
import '../utils/constants.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(quizHistoryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('クイズ履歴'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: historyAsync.when(
        data: (historyList) {
          if (historyList.isEmpty) {
            return const AppEmptyStateWidget(
              message: 'まだクイズ履歴がありません\nクイズをプレイして履歴を残しましょう！',
              icon: Icons.history,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(quizHistoryListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historyList.length,
              itemBuilder: (context, index) {
                final history = historyList[index];
                return _buildHistoryCard(context, history);
              },
            ),
          );
        },
        loading: () => const AppLoadingWidget(),
        error: (error, stack) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(quizHistoryListProvider),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, QuizHistory history) {
    final dateFormat = DateFormat('yyyy/MM/dd HH:mm');
    final isPerfect = history.score == history.total;
    final categoryName = _getCategoryName(history.category);
    final difficultyName = _getDifficultyName(history.difficulty);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        difficultyName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isPerfect)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '全問正解',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'スコア',
                    '${history.score} / ${history.total}',
                    Colors.blue,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '正答率',
                    '${history.accuracyPercentage.toStringAsFixed(1)}%',
                    Colors.green,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '獲得GP',
                    '+${history.earnedPoints}',
                    Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(history.completedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  String _getCategoryName(String category) {
    switch (category) {
      case AppConstants.categoryRules:
        return 'ルールクイズ';
      case AppConstants.categoryHistory:
        return '歴史クイズ';
      case AppConstants.categoryTeams:
        return 'チームクイズ';
      case AppConstants.categoryNews:
        return 'ニュースクイズ';
      case AppConstants.categoryMatchRecap:
        return 'Monday Match Recap';
      default:
        return category;
    }
  }

  String _getDifficultyName(String difficulty) {
    switch (difficulty) {
      case AppConstants.difficultyEasy:
        return 'EASY';
      case AppConstants.difficultyNormal:
        return 'NORMAL';
      case AppConstants.difficultyHard:
        return 'HARD';
      case AppConstants.difficultyExtreme:
        return 'EXTREME';
      default:
        return difficulty.toUpperCase();
    }
  }
}
