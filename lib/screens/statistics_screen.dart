import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quiz_history_provider.dart';
import '../utils/constants.dart';
import '../widgets/error_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_widget.dart';
import '../constants/app_colors.dart';
import '../widgets/background_widget.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(quizStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('統計情報'),
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
        child: statisticsAsync.when(
          data: (statistics) {
            if (statistics.totalPlays == 0) {
              return const AppEmptyStateWidget(
                message: 'まだ統計データがありません\nクイズをプレイして統計を確認しましょう！',
                icon: Icons.bar_chart,
              );
            }

            return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(quizStatisticsProvider);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 総合統計
                  _buildOverallStatsCard(context, statistics),
                  const SizedBox(height: 16),

                  // カテゴリ別統計
                  _buildCategoryStatsCard(context, statistics.categoryStats),
                  const SizedBox(height: 16),

                  // 難易度別統計
                  _buildDifficultyStatsCard(context, statistics.difficultyStats),
                ],
              ),
            ),
          );
        },
        loading: () => const AppLoadingWidget(),
        error: (error, stack) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(quizStatisticsProvider),
        ),
      ),
      ),
    );
  }

  Widget _buildOverallStatsCard(
    BuildContext context,
    QuizStatistics statistics,
  ) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
              Colors.blue.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Colors.blue.shade700,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '総合統計',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox(
                  context,
                  '総プレイ回数',
                  '${statistics.totalPlays}',
                  Icons.play_circle_outline,
                  Colors.blue,
                ),
                _buildStatBox(
                  context,
                  '総正答率',
                  '${statistics.overallAccuracy * 100}%',
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox(
                  context,
                  '総正答数',
                  '${statistics.totalScore}',
                  Icons.star_outline,
                  Colors.amber,
                ),
                _buildStatBox(
                  context,
                  '総問題数',
                  '${statistics.totalQuestions}',
                  Icons.help_outline,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStatsCard(
    BuildContext context,
    List<CategoryStatistic> categoryStats,
  ) {
    if (categoryStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade50,
              Colors.white,
              Colors.orange.shade50,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'カテゴリ別成績',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...categoryStats.map((stat) => _buildCategoryStatItem(context, stat)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStatItem(
    BuildContext context,
    CategoryStatistic stat,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getCategoryName(stat.category),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${stat.accuracy * 100}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: stat.accuracy,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'プレイ回数: ${stat.playCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              Text(
                '${stat.totalScore} / ${stat.totalQuestions}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyStatsCard(
    BuildContext context,
    List<DifficultyStatistic> difficultyStats,
  ) {
    if (difficultyStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.background,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Colors.purple.shade700,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '難易度別成績',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...difficultyStats.map((stat) => _buildDifficultyStatItem(context, stat)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyStatItem(
    BuildContext context,
    DifficultyStatistic stat,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getDifficultyName(stat.difficulty),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${stat.accuracy * 100}%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: stat.accuracy,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'プレイ回数: ${stat.playCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              Text(
                '${stat.totalScore} / ${stat.totalQuestions}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ],
      ),
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

