import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_data_provider.dart';
import '../providers/sample_data_provider.dart';
import '../utils/constants.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // サンプルデータの初期化を確認
    ref.watch(sampleDataInitializedProvider);

    final totalPoints = ref.watch(totalPointsProvider);
    final userRank = ref.watch(userRankProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Soccer Quiz Master'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Weekly Challenge Card
              Card(
                elevation: 4,
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Monday Match Recap',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '今週の試合結果をクイズで確認しよう！',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/configuration?category=${AppConstants.categoryMatchRecap}');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('チャレンジする'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ランクとポイント表示
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                userRank.japaneseName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userRank.englishName,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.grey.shade300,
                          ),
                          Column(
                            children: [
                              Text(
                                '$totalPoints',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const Text('GP'),
                            ],
                          ),
                        ],
                      ),
                      if (userRank.pointsToNextRank(totalPoints) != null) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: (totalPoints - userRank.minPoints) /
                              (userRank.maxPoints! - userRank.minPoints),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '次のランクまで ${userRank.pointsToNextRank(totalPoints)} GP',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // カテゴリ選択
              Text(
                'クイズを選ぶ',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildCategoryCard(
                context,
                'ルールクイズ',
                Icons.rule,
                Colors.blue,
                AppConstants.categoryRules,
              ),
              const SizedBox(height: 12),
              _buildCategoryCard(
                context,
                '歴史クイズ',
                Icons.history,
                Colors.orange,
                AppConstants.categoryHistory,
              ),
              const SizedBox(height: 12),
              _buildCategoryCard(
                context,
                'チームクイズ',
                Icons.groups,
                Colors.purple,
                AppConstants.categoryTeams,
              ),
              const SizedBox(height: 12),
              _buildCategoryCard(
                context,
                'ニュースクイズ',
                Icons.newspaper,
                Colors.red,
                AppConstants.categoryNews,
              ),
              const SizedBox(height: 24),

              // バナー広告のプレースホルダー
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '広告エリア',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String category,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push('/configuration?category=$category');
        },
      ),
    );
  }
}
