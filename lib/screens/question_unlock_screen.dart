import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/question_unlock_provider.dart';
import '../providers/question_service_provider.dart';
import '../providers/user_data_provider.dart';
import '../providers/database_provider.dart';
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

/// 問題開放画面（ゼロベース再実装）
/// - initStateで初回ロード（build中にsetStateしない）
/// - ルールクイズ: 100件一括表示
/// - チームクイズ: 国→チームでフィルタ
class QuestionUnlockScreen extends ConsumerStatefulWidget {
  const QuestionUnlockScreen({super.key});

  @override
  ConsumerState<QuestionUnlockScreen> createState() =>
      _QuestionUnlockScreenState();
}

class _QuestionUnlockScreenState extends ConsumerState<QuestionUnlockScreen> {
  String _selectedCategory = AppConstants.categoryRules;
  String _selectedDifficulty = AppConstants.difficultyEasy;
  String? _selectedRegion = 'japan';
  String _selectedCountry = 'japan';
  String? _selectedTeam;

  final List<Question> _questions = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  final HistoryUnlockService _historyUnlockService = HistoryUnlockService();
  int _remainingFreeUnlocks = 0;
  final ScrollController _scrollController = ScrollController();
  bool _showOnlyWrongAnswers = false;
  Set<String> _wrongAnswerIds = {};

  static const int _pageSize = 100;

  @override
  void initState() {
    super.initState();
    _loadRemainingFreeUnlocks();
    _loadWrongAnswerIds();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _canLoadQuestions()) {
        _loadQuestions();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !_hasMore) return;
    if (!_canLoadQuestions()) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMoreQuestions();
    }
  }

  bool _canLoadQuestions() {
    if (_selectedCategory == AppConstants.categoryTeams) {
      return _selectedTeam != null && _selectedTeam!.isNotEmpty;
    }
    return true;
  }

  Future<void> _loadRemainingFreeUnlocks() async {
    final remaining = await _historyUnlockService.getRemainingFreeUnlocks();
    if (mounted) {
      setState(() => _remainingFreeUnlocks = remaining);
    }
  }

  Future<void> _loadWrongAnswerIds() async {
    final databaseService = ref.read(databaseServiceProvider);
    final ids = await databaseService.getWrongAnswerQuestionIds();
    if (mounted) {
      setState(() => _wrongAnswerIds = Set<String>.from(ids));
    }
  }

  List<Question> _getDisplayQuestions() {
    if (!_showOnlyWrongAnswers) return _questions;
    return _questions.where((q) => _wrongAnswerIds.contains(q.id)).toList();
  }

  Future<void> _loadQuestions() async {
    if (!_canLoadQuestions()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hasMore = true;
    });

    try {
      await _loadWrongAnswerIds();
      final questionService = ref.read(questionServiceProvider);
      final batch = await questionService.getQuestionsForUnlockScreen(
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        country: _selectedCategory == AppConstants.categoryTeams
            ? _selectedCountry
            : null,
        region: _selectedCategory == AppConstants.categoryHistory
            ? _selectedRegion
            : null,
        team: _selectedCategory == AppConstants.categoryTeams
            ? _selectedTeam
            : null,
        limit: _pageSize,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _questions.clear();
          _questions.addAll(batch);
          _hasMore = batch.length >= _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasMore = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadMoreQuestions() async {
    if (!_canLoadQuestions()) return;
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final questionService = ref.read(questionServiceProvider);
      final batch = await questionService.getQuestionsForUnlockScreen(
        category: _selectedCategory,
        difficulty: _selectedDifficulty,
        country: _selectedCategory == AppConstants.categoryTeams
            ? _selectedCountry
            : null,
        region: _selectedCategory == AppConstants.categoryHistory
            ? _selectedRegion
            : null,
        team: _selectedCategory == AppConstants.categoryTeams
            ? _selectedTeam
            : null,
        limit: _pageSize,
        offset: _questions.length,
      );

      if (mounted) {
        setState(() {
          _questions.addAll(batch);
          _hasMore = batch.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasMore = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onFilterChanged() {
    setState(() {
      _questions.clear();
      _error = null;
      _hasMore = true;
    });
    _loadQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final totalPoints = ref.watch(totalPointsProvider);
    final unlockedIdsAsync = ref.watch(unlockedQuestionIdsProvider);

    int? unlockedCount;
    int? totalCount;
    double? percentage;
    final displayQuestions = _getDisplayQuestions();
    final unlockedIds = unlockedIdsAsync.valueOrNull;
    if (unlockedIds != null && displayQuestions.isNotEmpty) {
      final unlockedIdsSet = Set<String>.from(unlockedIds);
      totalCount = displayQuestions.length;
      unlockedCount =
          displayQuestions.where((q) => unlockedIdsSet.contains(q.id)).length;
      percentage = totalCount > 0 ? (unlockedCount / totalCount * 100) : 0.0;
    }

    return Scaffold(
      backgroundColor: AppColors.stitchBackgroundLight,
      appBar: buildAppBarWithBackground(
        titleWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '問題開放',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            if (unlockedCount != null && totalCount != null)
              Text(
                '$unlockedCount/$totalCount問 (${percentage?.toStringAsFixed(1) ?? '0'}%) 解放',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => context.go('/'),
          tooltip: 'ホームへ戻る',
        ),
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
                      color: Colors.white,
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
            _buildFilterSection(),
            Expanded(child: _buildContent(unlockedIdsAsync)),
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
          _buildSectionLabel('カテゴリ'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('ルール', _selectedCategory == AppConstants.categoryRules,
                  () => setState(() {
                    _selectedCategory = AppConstants.categoryRules;
                    _onFilterChanged();
                  })),
              _buildFilterChip('歴史', _selectedCategory == AppConstants.categoryHistory,
                  () => setState(() {
                    _selectedCategory = AppConstants.categoryHistory;
                    _selectedRegion = 'japan';
                    _onFilterChanged();
                  })),
              _buildFilterChip('チーム', _selectedCategory == AppConstants.categoryTeams,
                  () => setState(() {
                    _selectedCategory = AppConstants.categoryTeams;
                    _selectedCountry = 'japan';
                    _selectedTeam = null;
                    _onFilterChanged();
                  })),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionLabel('難易度'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('EASY', _selectedDifficulty == AppConstants.difficultyEasy,
                  () => setState(() {
                    _selectedDifficulty = AppConstants.difficultyEasy;
                    _onFilterChanged();
                  })),
              _buildFilterChip('NORMAL', _selectedDifficulty == AppConstants.difficultyNormal,
                  () => setState(() {
                    _selectedDifficulty = AppConstants.difficultyNormal;
                    _onFilterChanged();
                  })),
              _buildFilterChip('HARD', _selectedDifficulty == AppConstants.difficultyHard,
                  () => setState(() {
                    _selectedDifficulty = AppConstants.difficultyHard;
                    _onFilterChanged();
                  })),
            ],
          ),
          if (_selectedCategory == AppConstants.categoryTeams) ...[
            const SizedBox(height: 16),
            _buildTeamFilter(),
          ],
          if (_selectedCategory == AppConstants.categoryHistory) ...[
            const SizedBox(height: 16),
            _buildRegionFilter(),
          ],
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              '過去に不正解だった問題のみ表示',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.techIndigo,
              ),
            ),
            value: _showOnlyWrongAnswers,
            activeColor: AppColors.techBlue,
            onChanged: (value) async {
              final showOnly = value ?? false;
              if (showOnly) {
                await _loadWrongAnswerIds();
              }
              if (mounted) {
                setState(() => _showOnlyWrongAnswers = showOnly);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.techIndigo,
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.techBlue.withValues(alpha: 0.3),
      checkmarkColor: AppColors.techIndigo,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildComingSoonChip(String label) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FilterChip(
          label: Text(
            label,
            style: TextStyle(color: Colors.grey.shade400),
          ),
          selected: false,
          onSelected: null,
          backgroundColor: Colors.grey.shade100,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Positioned(
          top: -4,
          right: -4,
          child: Transform.rotate(
            angle: -0.15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF3366)],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3366).withValues(alpha: 0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Text(
                'COMING SOON',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalChipRow(List<Widget> chips) {
    return SizedBox(
      height: 44,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: chips
              .map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: c,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildTeamFilter() {
    final teams = _getTeamListForCountry(_selectedCountry);

    final countryChips = [
      _buildFilterChip('日本', _selectedCountry == 'japan',
          () => setState(() {
            _selectedCountry = 'japan';
            _selectedTeam = null;
            _onFilterChanged();
          })),
      _buildFilterChip('イタリア', _selectedCountry == 'italy',
          () => setState(() {
            _selectedCountry = 'italy';
            _selectedTeam = null;
            _onFilterChanged();
          })),
      _buildFilterChip('スペイン', _selectedCountry == 'spain',
          () => setState(() {
            _selectedCountry = 'spain';
            _selectedTeam = null;
            _onFilterChanged();
          })),
      _buildFilterChip('イングランド', _selectedCountry == 'england',
          () => setState(() {
            _selectedCountry = 'england';
            _selectedTeam = null;
            _onFilterChanged();
          })),
    ];

    final isOverseas = _selectedCountry == 'england' ||
        _selectedCountry == 'spain' ||
        _selectedCountry == 'italy';

    final teamChips = teams.map((team) {
      if (isOverseas) {
        return _buildComingSoonChip(team['label']!);
      }
      return _buildFilterChip(
        team['label']!,
        _selectedTeam == team['value'],
        () => setState(() {
          _selectedTeam = team['value'];
          _onFilterChanged();
        }),
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('国'),
        const SizedBox(height: 4),
        _buildHorizontalChipRow(countryChips),
        const SizedBox(height: 12),
        _buildSectionLabel('チーム'),
        const SizedBox(height: 4),
        _buildHorizontalChipRow(teamChips),
      ],
    );
  }

  List<Map<String, String>> _getTeamListForCountry(String country) {
    switch (country) {
      case 'japan':
        return [
          {'label': '鹿島アントラーズ', 'value': 'kashima_antlers'},
          {'label': '柏レイソル', 'value': 'kashiwa_reysol'},
          {'label': '京都サンガF.C.', 'value': 'kyoto_sanga'},
          {'label': 'サンフレッチェ広島', 'value': 'sanfrecce_hiroshima'},
          {'label': 'ヴィッセル神戸', 'value': 'vissel_kobe'},
          {'label': 'FC町田ゼルビア', 'value': 'machida_zelvia'},
          {'label': '浦和レッズ', 'value': 'urawa_reds'},
          {'label': '川崎フロンターレ', 'value': 'kawasaki_frontale'},
          {'label': 'ガンバ大阪', 'value': 'gamba_osaka'},
          {'label': 'セレッソ大阪', 'value': 'cerezo_osaka'},
          {'label': 'FC東京', 'value': 'fc_tokyo'},
          {'label': 'アビスパ福岡', 'value': 'avispa_fukuoka'},
          {'label': 'ファジアーノ岡山', 'value': 'fagiano_okayama'},
          {'label': '清水エスパルス', 'value': 'shimizu_s_pulse'},
          {'label': '横浜F・マリノス', 'value': 'yokohama_f_marinos'},
          {'label': '名古屋グランパス', 'value': 'nagoya_grampus'},
          {'label': '東京ヴェルディ', 'value': 'tokyo_verdy'},
          {'label': '水戸ホーリーホック', 'value': 'mito_hollyhock'},
          {'label': 'V・ファーレン長崎', 'value': 'v_varen_nagasaki'},
          {'label': 'ジェフユナイテッド市原・千葉', 'value': 'jef_united_chiba'},
        ];
      case 'italy':
        return [
          {'label': 'ユベントス', 'value': 'juventus'},
          {'label': 'ACミラン', 'value': 'ac_milan'},
          {'label': 'インテルミラノ', 'value': 'inter_milan'},
        ];
      case 'spain':
        return [
          {'label': 'レアルマドリード', 'value': 'real_madrid'},
          {'label': 'バルセロナ', 'value': 'barcelona'},
          {'label': 'アトレティコマドリード', 'value': 'atletico_madrid'},
        ];
      case 'england':
        return [
          {'label': 'リバプール', 'value': 'liverpool'},
          {'label': 'アーセナル', 'value': 'arsenal'},
          {'label': 'マンチェスターシティ', 'value': 'manchester_city'},
          {'label': 'マンチェスターユナイテッド', 'value': 'manchester_united'},
          {'label': 'チェルシー', 'value': 'chelsea'},
        ];
      default:
        return [];
    }
  }

  Widget _buildRegionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('地域'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFilterChip('日本', _selectedRegion == 'japan',
                () => setState(() {
                  _selectedRegion = 'japan';
                  _onFilterChanged();
                })),
            _buildFilterChip('世界', _selectedRegion == 'world',
                () => setState(() {
                  _selectedRegion = 'world';
                  _onFilterChanged();
                })),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(AsyncValue<List<String>> unlockedIdsAsync) {
    if (_selectedCategory == AppConstants.categoryTeams &&
        (_selectedTeam == null || _selectedTeam!.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'チームを選択してください',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '読み込みに失敗しました',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'もう一度お試しください',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _error = null);
                  _loadQuestions();
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading && _questions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('読み込み中...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return unlockedIdsAsync.when(
      data: (unlockedIds) {
        final unlockedIdsSet = Set<String>.from(unlockedIds);
        final displayQuestions = _getDisplayQuestions();

        if (_questions.isEmpty) {
          return Center(
            child: Text(
              'この条件では問題がありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        if (displayQuestions.isEmpty) {
          return Center(
            child: Text(
              _showOnlyWrongAnswers
                  ? 'この条件の不正解問題はありません'
                  : 'この条件では問題がありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '問題一覧（${displayQuestions.length}件）',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.techIndigo,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: displayQuestions.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= displayQuestions.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final question = displayQuestions[index];
                  final isUnlocked = unlockedIdsSet.contains(question.id);
                  final wasWrong = _wrongAnswerIds.contains(question.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildQuestionCard(
                      question,
                      isUnlocked,
                      wasWrong: wasWrong,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('読み込み中...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'エラー: $error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    Question question,
    bool isUnlocked, {
    bool wasWrong = false,
  }) {
    return GlassMorphismWidget(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                CategoryDifficultyUtils.getDifficultyName(question.difficulty),
                Colors.orange,
              ),
              if (wasWrong) ...[
                const SizedBox(width: 8),
                _buildInfoChip('過去に不正解', Colors.red.shade400),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (!isUnlocked) ...[
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
                      Text('${historyUnlock.singleQuestionCost} PTで開放'),
                    ],
                  ),
                ),
              ),
            ] else
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

    if (totalPoints < historyUnlock.singleQuestionCost) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ポイントが不足しています。${historyUnlock.singleQuestionCost}ポイント必要です。',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('問題を開放しますか？'),
        content: Text(
          '${historyUnlock.singleQuestionCost}ポイントを消費してこの問題を開放します。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.techBlue),
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
        onError: (error) => debugPrint('広告読み込みエラー: $error'),
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

        try {
          final unlockService = ref.read(questionUnlockServiceProvider);
          await unlockService.unlockQuestion(question.id, 0);
          ref.invalidate(unlockedQuestionIdsProvider);
          ref.invalidate(unlockedQuestionsProvider);
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
      onError: (error) => debugPrint('広告表示エラー: $error'),
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
