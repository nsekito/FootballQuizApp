import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_data_provider.dart';
import '../providers/quiz_history_provider.dart';
import '../models/user_rank.dart';
import '../constants/app_colors.dart';
import '../widgets/background_widget.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final int score;
  final int total;
  final int earnedPoints;
  final String category;
  final String difficulty;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.earnedPoints,
    required this.category,
    required this.difficulty,
  });

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  UserRank? _previousRank;
  UserRank? _currentRank;
  bool _rankUp = false;

  @override
  void initState() {
    super.initState();
    _checkRankUp();
    _addPoints();
    _saveHistory();
  }

  void _checkRankUp() {
    final totalPoints = ref.read(totalPointsProvider);
    _previousRank = UserRank.fromPoints(totalPoints);
    _currentRank = UserRank.fromPoints(totalPoints + widget.earnedPoints);
    _rankUp = _previousRank != _currentRank;
  }

  Future<void> _addPoints() async {
    await ref.read(totalPointsProvider.notifier).addPoints(widget.earnedPoints);
    setState(() {
      _currentRank = ref.read(userRankProvider);
    });
  }

  Future<void> _saveHistory() async {
    try {
      final historyService = ref.read(quizHistoryServiceProvider);
      final history = QuizHistory(
        category: widget.category,
        difficulty: widget.difficulty,
        score: widget.score,
        total: widget.total,
        earnedPoints: widget.earnedPoints,
        completedAt: DateTime.now(),
      );
      await historyService.saveHistory(history);
      
      // 履歴リストを更新
      ref.invalidate(quizHistoryListProvider);
      ref.invalidate(quizStatisticsProvider);
    } catch (e) {
      // エラーは無視（履歴保存の失敗は致命的ではない）
      debugPrint('履歴の保存に失敗しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('履歴の保存に失敗しましたが、クイズ結果は正常に記録されました。'),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.total > 0 ? (widget.score / widget.total * 100) : 0.0;
    final isPerfect = widget.score == widget.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('結果'),
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
              // スコア表示
              Card(
                elevation: 4,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isPerfect
                          ? [
                              Colors.amber.shade50,
                              Colors.amber.shade100,
                              Colors.amber.shade50,
                            ]
                          : [
                              Colors.green.shade50,
                              Colors.green.shade100,
                              Colors.green.shade50,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (isPerfect ? Colors.amber : Colors.green)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      if (isPerfect)
                        Icon(
                          Icons.emoji_events,
                          size: 64,
                          color: Colors.amber.shade700,
                        ),
                      if (isPerfect) const SizedBox(height: 16),
                      Text(
                        '${widget.score} / ${widget.total}',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPerfect
                                  ? Colors.amber.shade700
                                  : Colors.green.shade700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '正答率: ${accuracy.toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (isPerfect) ...[
                        const SizedBox(height: 8),
                        Text(
                          '全問正解！',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 獲得ポイント表示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '獲得ポイント',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '+${widget.earnedPoints} GP',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.stars,
                        size: 48,
                        color: Colors.amber.shade700,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ランクアップ演出
              if (_rankUp && _currentRank != null) ...[
                Card(
                  color: Colors.amber.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 新しいランクのバッジを表示
                        _RankBadgeWidget(
                          rank: _currentRank!,
                          size: 100,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ランクアップ！',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_previousRank?.japaneseName} → ${_currentRank?.japaneseName}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 現在のランク表示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        '現在のランク',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      // ランクバッジを表示
                      if (_currentRank != null)
                        _RankBadgeWidget(
                          rank: _currentRank!,
                          size: 120,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _currentRank?.japaneseName ?? '',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _currentRank?.englishName ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '累計: ${ref.watch(totalPointsProvider)} GP',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.green.shade700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ホームに戻るボタン
              ElevatedButton(
                onPressed: () {
                  context.go('/');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'ホームに戻る',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),

              // もう一度挑戦ボタン
              OutlinedButton(
                onPressed: () {
                  context.pop();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.primary),
                ),
                child: const Text(
                  'もう一度挑戦',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

}


/// ランクバッジを表示するウィジェット
class _RankBadgeWidget extends StatelessWidget {
  final UserRank rank;
  final double size;

  const _RankBadgeWidget({
    required this.rank,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData iconData;
    
    switch (rank) {
      case UserRank.academy:
        badgeColor = Colors.grey.shade400;
        iconData = Icons.school;
        break;
      case UserRank.rookie:
        badgeColor = Colors.blue.shade400;
        iconData = Icons.star;
        break;
      case UserRank.regular:
        badgeColor = Colors.green.shade400;
        iconData = Icons.emoji_events;
        break;
      case UserRank.fantasista:
        badgeColor = Colors.amber.shade400;
        iconData = Icons.auto_awesome;
        break;
      case UserRank.legend:
        badgeColor = Colors.purple.shade400;
        iconData = Icons.workspace_premium;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            badgeColor,
            badgeColor.withValues(alpha: 0.7),
            badgeColor.withValues(alpha: 0.5),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}
