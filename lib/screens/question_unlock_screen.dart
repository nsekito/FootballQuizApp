import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/question_unlock_provider.dart';
import '../providers/question_service_provider.dart';
import '../providers/user_data_provider.dart';
import '../constants/app_constants.dart';
import '../constants/app_colors.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/app_bar_background.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/category_difficulty_utils.dart';
import '../models/question.dart';
import '../constants/game_config.dart';
import '../services/history_unlock_service.dart';
import '../providers/ad_provider.dart';

class QuestionUnlockScreen extends ConsumerStatefulWidget {
  const QuestionUnlockScreen({super.key});

  @override
  ConsumerState<QuestionUnlockScreen> createState() =>
      _QuestionUnlockScreenState();
}

class _QuestionUnlockScreenState extends ConsumerState<QuestionUnlockScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;
  String? _selectedDifficulty;
  String? _selectedRegion;
  String? _selectedCountry;
  String? _selectedTeam;
  final HistoryUnlockService _historyUnlockService = HistoryUnlockService();
  int _remainingFreeUnlocks = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedCategory = AppConstants.categoryRules;
    _selectedDifficulty = AppConstants.difficultyEasy;
    _loadRemainingFreeUnlocks();
  }

  Future<void> _loadRemainingFreeUnlocks() async {
    final remaining = await _historyUnlockService.getRemainingFreeUnlocks();
    if (mounted) {
      setState(() {
        _remainingFreeUnlocks = remaining;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = ref.watch(totalPointsProvider);
    final unlockedQuestionIdsAsync = ref.watch(unlockedQuestionIdsProvider);
    // 残り無料解放回数を定期的に更新
    Future.microtask(() => _loadRemainingFreeUnlocks());

    return Scaffold(
      backgroundColor: AppColors.stitchBackgroundLight,
      appBar: buildAppBarWithBackground(
        title: '問題開放',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${NumberFormat('#,###').format(totalPoints)} PT',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: GridPatternBackground(
        child: Column(
          children: [
            // フィルタセクション
            _buildFilterSection(),

            // タブ
            TabBar(
              controller: _tabController,
              labelColor: AppColors.techIndigo,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.techIndigo,
              tabs: const [
                Tab(text: '未開放'),
                Tab(text: '開放済み'),
              ],
            ),

            // 問題一覧
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUnlockedQuestionsList(unlockedQuestionIdsAsync),
                  _buildUnlockedQuestionsList(unlockedQuestionIdsAsync,
                      showUnlocked: true),
                ],
              ),
            ),

            // バナー広告
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return GlassMorphismWidget(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カテゴリ選択
          _buildCategoryFilter(),
          const SizedBox(height: 16),

          // 難易度選択
          if (_selectedCategory != AppConstants.categoryMatchRecap)
            _buildDifficultyFilter(),

          // チームクイズの場合の追加フィルタ
          if (_selectedCategory == AppConstants.categoryTeams) ...[
            const SizedBox(height: 16),
            _buildTeamFilter(),
          ],

          // 歴史クイズの場合の地域フィルタ
          if (_selectedCategory == AppConstants.categoryHistory) ...[
            const SizedBox(height: 16),
            _buildRegionFilter(),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'カテゴリ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.techIndigo,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(
              'ルール',
              _selectedCategory == AppConstants.categoryRules,
              () => setState(
                  () => _selectedCategory = AppConstants.categoryRules),
            ),
            _buildFilterChip(
              '歴史',
              _selectedCategory == AppConstants.categoryHistory,
              () => setState(
                  () => _selectedCategory = AppConstants.categoryHistory),
            ),
            _buildFilterChip(
              'チーム',
              _selectedCategory == AppConstants.categoryTeams,
              () => setState(
                  () => _selectedCategory = AppConstants.categoryTeams),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDifficultyFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '難易度',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.techIndigo,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(
              'EASY',
              _selectedDifficulty == AppConstants.difficultyEasy,
              () => setState(
                  () => _selectedDifficulty = AppConstants.difficultyEasy),
            ),
            _buildFilterChip(
              'NORMAL',
              _selectedDifficulty == AppConstants.difficultyNormal,
              () => setState(
                  () => _selectedDifficulty = AppConstants.difficultyNormal),
            ),
            _buildFilterChip(
              'HARD',
              _selectedDifficulty == AppConstants.difficultyHard,
              () => setState(
                  () => _selectedDifficulty = AppConstants.difficultyHard),
            ),
            _buildFilterChip(
              'EXTREME',
              _selectedDifficulty == AppConstants.difficultyExtreme,
              () => setState(
                  () => _selectedDifficulty = AppConstants.difficultyExtreme),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'チーム',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.techIndigo,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'チーム名で検索',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (value) =>
              setState(() => _selectedTeam = value.isEmpty ? null : value),
        ),
      ],
    );
  }

  Widget _buildRegionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '地域',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.techIndigo,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(
              '日本',
              _selectedRegion == 'japan',
              () => setState(() => _selectedRegion = 'japan'),
            ),
            _buildFilterChip(
              '世界',
              _selectedRegion == 'world',
              () => setState(() => _selectedRegion = 'world'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.techBlue.withValues(alpha: 0.3),
      checkmarkColor: AppColors.techIndigo,
    );
  }

  Widget _buildUnlockedQuestionsList(
      AsyncValue<List<String>> unlockedQuestionIdsAsync,
      {bool showUnlocked = false}) {
    return unlockedQuestionIdsAsync.when(
      data: (unlockedIds) {
        return FutureBuilder<List<Question>>(
          key: ValueKey(_getQuestionsKey()), // フィルタ変更時に再取得
          future: _getQuestions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('エラー: ${snapshot.error}'),
              );
            }

            final questions = snapshot.data ?? [];
            final filteredQuestions = showUnlocked
                ? questions.where((q) => unlockedIds.contains(q.id)).toList()
                : questions.where((q) => !unlockedIds.contains(q.id)).toList();

            if (filteredQuestions.isEmpty) {
              return Center(
                child: Text(
                  showUnlocked ? '開放済みの問題がありません' : 'すべての問題が開放済みです',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredQuestions.length,
              itemBuilder: (context, index) {
                final question = filteredQuestions[index];
                final isUnlocked = unlockedIds.contains(question.id);
                return _buildQuestionCard(question, isUnlocked);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('エラー: $error'),
      ),
    );
  }

  Future<List<Question>> _getQuestions() async {
    final questionService = ref.read(questionServiceProvider);
    return await questionService.getQuestions(
      category: _selectedCategory!,
      difficulty: _selectedDifficulty!,
      country: _selectedCountry,
      region: _selectedRegion,
      team: _selectedTeam,
      limit: 1000, // すべての問題を取得
    );
  }

  String _getQuestionsKey() {
    // フィルタの組み合わせをキーとして使用
    return '${_selectedCategory}_${_selectedDifficulty}_${_selectedRegion ?? ''}_${_selectedCountry ?? ''}_${_selectedTeam ?? ''}';
  }

  Widget _buildQuestionCard(Question question, bool isUnlocked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassMorphismWidget(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 問題文のプレビュー
            Text(
              question.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.techIndigo,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // カテゴリと難易度
            Row(
              children: [
                _buildInfoChip(
                  CategoryDifficultyUtils.getCategoryName(question.category),
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  CategoryDifficultyUtils.getDifficultyName(
                      question.difficulty),
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // アクションボタン
            if (!isUnlocked) ...[
              // 無料解放ボタン（残り回数がある場合）
              if (_remainingFreeUnlocks > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _unlockQuestionFree(question),
                      icon: const Icon(Icons.play_circle_outline, size: 18),
                      label: Text('広告を見て無料開放（残り$_remainingFreeUnlocks回）'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.stitchEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              // PT消費で開放ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _unlockQuestion(question),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.techBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_open, size: 18),
                      const SizedBox(width: 8),
                      Text('${HISTORY_UNLOCK.singleQuestionCost} PTで開放'),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _viewQuestion(question),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.techGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('見る'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
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

  Future<void> _unlockQuestion(Question question) async {
    final totalPoints = ref.read(totalPointsProvider);

    if (totalPoints < HISTORY_UNLOCK.singleQuestionCost) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'ポイントが不足しています。${HISTORY_UNLOCK.singleQuestionCost}ポイント必要です。'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('問題を開放しますか？'),
        content: Text(
          '${HISTORY_UNLOCK.singleQuestionCost}ポイントを消費してこの問題を開放します。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.techBlue,
            ),
            child: const Text('開放する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(unlockQuestionProvider(question.id).future);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('問題を開放しました！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _unlockQuestionFree(Question question) async {
    final adService = ref.read(adServiceProvider);
    
    if (!adService.isRewardedAdReady) {
      await adService.loadRewardedAd(
        onRewarded: (_, __) {},
        onError: (error) {
          debugPrint('広告読み込みエラー: $error');
        },
      );
    }

    if (!adService.isRewardedAdReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('広告の読み込みに失敗しました'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final success = await adService.showRewardedAd(
      onRewarded: (_, __) async {
        // 無料解放を使用
        final used = await _historyUnlockService.useFreeUnlock();
        if (!used) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('無料解放の残り回数がありません'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // 問題を開放（PT消費なし）
        try {
          final unlockService = ref.read(questionUnlockServiceProvider);
          await unlockService.unlockQuestion(question.id, 0); // コスト0で開放
          
          // 開放済み問題リストを更新
          ref.invalidate(unlockedQuestionIdsProvider);
          ref.invalidate(unlockedQuestionsProvider);
          
          // 残り回数を更新
          await _loadRemainingFreeUnlocks();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('問題を無料開放しました！'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('エラー: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onError: (error) {
        debugPrint('広告表示エラー: $error');
      },
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('広告を表示できませんでした'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _viewQuestion(Question question) {
    context.push('/question-view?questionId=${question.id}');
  }
}
