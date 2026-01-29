import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_data_provider.dart';
import '../providers/sample_data_provider.dart';
import '../utils/constants.dart';
import '../constants/app_colors.dart';
import '../widgets/background_widget.dart';

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
              // Weekly Challenge Card
              Card(
                elevation: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      context.push('/configuration?category=${AppConstants.categoryMatchRecap}');
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // 画面幅を取得
                        final screenWidth = MediaQuery.of(context).size.width;
                        
                        // 画像のアスペクト比を維持しながら、画面サイズに応じて調整
                        // 横長のバナー画像を想定（一般的には16:9や21:9）
                        // モバイルでは16:9、タブレット/デスクトップでは21:9を使用
                        final aspectRatio = screenWidth > 600 ? 21 / 9 : 16 / 9;
                        
                        return AspectRatio(
                          aspectRatio: aspectRatio,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.8),
                                  AppColors.accent.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                // 装飾的なパターン
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _CardPatternPainter(
                                      color: Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ),
                                // コンテンツ
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.white,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Monday Match Recap',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                shadows: [
                                                  Shadow(
                                                    offset: const Offset(1, 1),
                                                    blurRadius: 3,
                                                    color: Colors.black.withValues(alpha: 0.3),
                                                  ),
                                                ],
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '今週の試合結果をクイズで確認しよう！',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withValues(alpha: 0.9),
                                            shadows: [
                                              Shadow(
                                                offset: const Offset(1, 1),
                                                blurRadius: 2,
                                                color: Colors.black.withValues(alpha: 0.2),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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

              // 履歴と統計へのリンク
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: Icon(Icons.history, color: Colors.blue.shade700),
                        title: const Text('クイズ履歴'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push('/history');
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      child: ListTile(
                        leading: Icon(Icons.bar_chart, color: Colors.green.shade700),
                        title: const Text('統計情報'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          context.push('/statistics');
                        },
                      ),
                    ),
                  ),
                ],
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
    // カテゴリ別のグラデーション色を取得
    List<Color> gradientColors;
    switch (category) {
      case AppConstants.categoryRules:
        // ルール: 青系グラデーション
        gradientColors = [
          const Color(0xFFBBDEFB), // 明るい青
          const Color(0xFF90CAF9), // 中程度の青
          const Color(0xFF64B5F6), // 濃い青
        ];
        break;
      case AppConstants.categoryHistory:
        // 歴史: 黄色系グラデーション
        gradientColors = [
          const Color(0xFFFFF9C4), // 明るい黄色
          const Color(0xFFFFF59D), // 中程度の黄色
          const Color(0xFFFFF176), // 濃い黄色
        ];
        break;
      case AppConstants.categoryTeams:
        // チーム: 紫系グラデーション
        gradientColors = [
          const Color(0xFFE1BEE7), // 明るい紫
          const Color(0xFFCE93D8), // 中程度の紫
          const Color(0xFFBA68C8), // 濃い紫
        ];
        break;
      case AppConstants.categoryNews:
        // ニュース: オレンジ系グラデーション
        gradientColors = [
          const Color(0xFFFFE0B2), // 明るいオレンジ
          const Color(0xFFFFCC80), // 中程度のオレンジ
          const Color(0xFFFFB74D), // 濃いオレンジ
        ];
        break;
      default:
        gradientColors = [
          AppColors.background,
          AppColors.background.withValues(alpha: 0.8),
        ];
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/configuration?category=$category');
        },
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // レスポンシブ対応：画面幅に応じて高さを調整
            final screenWidth = MediaQuery.of(context).size.width;
            final cardHeight = screenWidth > 600 ? 120.0 : 100.0;
            
            return Container(
              height: cardHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  // アイコン
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontSize: screenWidth > 600 ? 20 : 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: color,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}


/// カード用の装飾パターンを描画するCustomPainter
class _CardPatternPainter extends CustomPainter {
  final Color color;

  _CardPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 斜めの線パターン
    const spacing = 20.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
