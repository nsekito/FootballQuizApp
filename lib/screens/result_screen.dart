import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_data_provider.dart';
import '../models/user_rank.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final int score;
  final int total;
  final int earnedPoints;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.earnedPoints,
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

  @override
  Widget build(BuildContext context) {
    final accuracy = widget.total > 0 ? (widget.score / widget.total * 100) : 0.0;
    final isPerfect = widget.score == widget.total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('結果'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // スコア表示
              Card(
                elevation: 4,
                child: Padding(
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
                              color: isPerfect ? Colors.amber.shade700 : Colors.green.shade700,
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
                        Icon(
                          Icons.trending_up,
                          size: 48,
                          color: Colors.amber.shade700,
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
                      const SizedBox(height: 8),
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
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
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
    );
  }
}
