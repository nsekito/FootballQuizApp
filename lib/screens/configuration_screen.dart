import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';
import '../utils/unlock_key_utils.dart';
import '../providers/user_data_provider.dart';
import '../providers/database_provider.dart';
import '../constants/app_colors.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/glow_button.dart';
import '../widgets/responsive_container.dart';
import '../widgets/banner_ad_widget.dart';
import '../utils/category_difficulty_utils.dart';
import '../models/promotion_exam.dart';

class ConfigurationScreen extends ConsumerStatefulWidget {
  final String category;

  const ConfigurationScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends ConsumerState<ConfigurationScreen> {
  String? _selectedDifficulty;
  String? _selectedRegion;
  String? _selectedCountry;
  String? _selectedTeam;
  String? _selectedLeagueType; // Weekly Recap用のリーグタイプ
  final ScrollController _teamScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.category == AppConstants.categoryTeams) {
      _selectedCountry = 'japan';
    }
  }

  @override
  void dispose() {
    _teamScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.stitchBackgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white.withValues(alpha: 0.7),
          elevation: 0,
          automaticallyImplyLeading: false, // 戻るボタンを非表示
          leading: IconButton(
            icon: const Icon(Icons.home, color: AppColors.techIndigo),
            onPressed: () => context.go('/'),
            tooltip: 'ホームへ戻る',
          ),
          title: Text(
            CategoryDifficultyUtils.getCategoryName(widget.category),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return GridPatternBackground(
            child: SizedBox(
              height: constraints.maxHeight,
              child: ResponsiveContainer(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'クイズ設定',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Weekly Recap: リーグタイプ選択
                  if (widget.category == AppConstants.categoryMatchRecap) ...[
                    _buildLeagueTypeSelector(),
                    const SizedBox(height: 24),
                  ],

                  // 歴史クイズ: 地域選択
                  if (widget.category == AppConstants.categoryHistory) ...[
                    _buildRegionSelector(),
                    const SizedBox(height: 24),
                  ],

                  // チームクイズ: 国選択とチーム選択
                  if (widget.category == AppConstants.categoryTeams) ...[
                    _buildCountrySelector(),
                    const SizedBox(height: 16),
                    Expanded(child: _buildTeamSelector()),
                    const SizedBox(height: 16),
                  ],

                  // 難易度選択（Weekly Recap以外）- 最後に表示
                  if (widget.category != AppConstants.categoryMatchRecap) ...[
                    if (widget.category != AppConstants.categoryTeams)
                      const SizedBox(height: 16),
                    _buildDifficultySelector(),
                    const SizedBox(height: 24),
                  ],

                  // STARTボタン
                  SizedBox(
                    width: double.infinity,
                    child: GlowButton(
                      glowColor: AppColors.stitchEmerald,
                      onPressed: _canStart() ? _validateAndStart : null,
                      backgroundColor: AppColors.stitchEmerald,
                      foregroundColor: Colors.white,
                      borderRadius: 16,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'START',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        },
      ),
      bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.bolt,
              color: AppColors.stitchEmerald,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '難易度',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDifficultyButton('EASY', AppConstants.difficultyEasy)),
            const SizedBox(width: 8),
            Expanded(child: _buildDifficultyButton('NORMAL', AppConstants.difficultyNormal)),
            const SizedBox(width: 8),
            Expanded(child: _buildDifficultyButton('HARD', AppConstants.difficultyHard)),
          ],
        ),
      ],
    );
  }

  /// 現在の選択からタグを生成
  String _generateTags() {
    if (widget.category == AppConstants.categoryTeams) {
      final tags = <String>['teams'];
      if (_selectedCountry != null && _selectedCountry!.isNotEmpty) {
        tags.add(_selectedCountry!);
      }
      if (_selectedTeam != null && _selectedTeam!.isNotEmpty) {
        // リーグ全体の選択
        if (_selectedTeam == 'j1_all_teams') {
          tags.add('j1');
        } else if (_selectedTeam == 'j2_all_teams') {
          tags.add('j2');
        } else {
          // 個別チーム名の選択 - リーグタグも含める
          final leagueTag = _getLeagueTagForTeam(_selectedTeam!);
          if (leagueTag != null) {
            tags.add(leagueTag);
          }
          tags.add(_selectedTeam!);
        }
      }
      return tags.join(',');
    } else if (widget.category == AppConstants.categoryHistory) {
      final tags = <String>['history'];
      if (_selectedRegion != null && _selectedRegion!.isNotEmpty) {
        tags.add(_selectedRegion!);
      }
      return tags.join(',');
    } else {
      return widget.category;
    }
  }

  /// チーム名からリーグタグを取得
  String? _getLeagueTagForTeam(String teamValue) {
    // J1チーム
    const j1Teams = [
      'kashima_antlers',
      'kashiwa_reysol',
      'kyoto_sanga',
      'sanfrecce_hiroshima',
      'vissel_kobe',
      'machida_zelvia',
      'urawa_reds',
      'kawasaki_frontale',
      'gamba_osaka',
      'cerezo_osaka',
      'fc_tokyo',
      'avispa_fukuoka',
      'fagiano_okayama',
      'shimizu_s_pulse',
      'yokohama_f_marinos',
      'nagoya_grampus',
      'tokyo_verdy',
    ];
    
    // J2チーム
    const j2Teams = [
      'mito_hollyhock',
      'v_varen_nagasaki',
      'jef_united_chiba',
    ];
    
    // セリエAチーム
    const serieATeams = [
      'juventus',
      'ac_milan',
      'inter_milan',
    ];
    
    // ラリーガチーム
    const laLigaTeams = [
      'real_madrid',
      'barcelona',
      'atletico_madrid',
    ];
    
    // プレミアリーグチーム
    const premierLeagueTeams = [
      'liverpool',
      'arsenal',
      'manchester_city',
      'manchester_united',
      'chelsea',
    ];
    
    if (j1Teams.contains(teamValue)) {
      return 'j1';
    } else if (j2Teams.contains(teamValue)) {
      return 'j2';
    } else if (serieATeams.contains(teamValue)) {
      return 'serie_a';
    } else if (laLigaTeams.contains(teamValue)) {
      return 'la_liga';
    } else if (premierLeagueTeams.contains(teamValue)) {
      return 'premier_league';
    }
    
    return null;
  }

  /// 難易度がアンロックされているかチェック
  Future<bool> _isDifficultyUnlocked(String difficulty) async {
    final tags = _generateTags();
    final unlockKey = UnlockKeyUtils.generateUnlockKey(
      category: widget.category,
      difficulty: difficulty,
      tags: tags,
    );
    
    // EASYは常にアンロック
    if (difficulty == AppConstants.difficultyEasy) {
      return true;
    }
    
    final unlockedDifficulties = ref.read(unlockedDifficultiesProvider);
    return unlockedDifficulties.contains(unlockKey);
  }

  /// 次にアンロックできる難易度を取得
  Future<String?> _getNextUnlockableDifficulty() async {
    final tags = _generateTags();
    
    // EASYは常にアンロック済み
    // NORMALがロックされている場合、NORMALが次にアンロックできる
    final normalUnlockKey = UnlockKeyUtils.generateUnlockKey(
      category: widget.category,
      difficulty: AppConstants.difficultyNormal,
      tags: tags,
    );
    final unlockedDifficulties = ref.read(unlockedDifficultiesProvider);
    if (!unlockedDifficulties.contains(normalUnlockKey)) {
      return AppConstants.difficultyNormal;
    }
    
    // NORMALがアンロック済みでHARDがロックされている場合、HARDが次にアンロックできる
    final hardUnlockKey = UnlockKeyUtils.generateUnlockKey(
      category: widget.category,
      difficulty: AppConstants.difficultyHard,
      tags: tags,
    );
    if (!unlockedDifficulties.contains(hardUnlockKey)) {
      return AppConstants.difficultyHard;
    }
    
    return null;
  }

  /// 難易度に対応する昇格試験を取得
  PromotionExam? _getPromotionExamForDifficulty(String difficulty) {
    final tags = _generateTags();
    
    switch (difficulty) {
      case AppConstants.difficultyNormal:
        return PromotionExam.easyToNormal(
          category: widget.category,
          tags: tags,
        );
      case AppConstants.difficultyHard:
        return PromotionExam.normalToHard(
          category: widget.category,
          tags: tags,
        );
      default:
        return null;
    }
  }

  Widget _buildDifficultyButton(String label, String value) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _isDifficultyUnlocked(value),
        _getNextUnlockableDifficulty(),
      ]),
      builder: (context, snapshot) {
        final isUnlocked = (snapshot.data?[0] as bool?) ?? (value == AppConstants.difficultyEasy);
        final isSelected = _selectedDifficulty == value;
        Color buttonColor;
        Color textColor;
        Color glowColor;
        final isEnabled = isUnlocked;

        switch (value) {
          case AppConstants.difficultyEasy:
            buttonColor = isSelected
                ? AppColors.stitchEmerald
                : (isEnabled
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.grey.shade300);
            textColor = isSelected
                ? Colors.white
                : (isEnabled ? Colors.grey.shade600 : Colors.grey.shade400);
            glowColor = AppColors.stitchEmerald;
            break;
          case AppConstants.difficultyNormal:
            buttonColor = isSelected
                ? Colors.blue.shade400
                : (isEnabled
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.grey.shade300);
            textColor = isSelected
                ? Colors.white
                : (isEnabled ? Colors.grey.shade600 : Colors.grey.shade400);
            glowColor = Colors.blue.shade400;
            break;
          case AppConstants.difficultyHard:
            buttonColor = isSelected
                ? Colors.orange.shade400
                : (isEnabled
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.grey.shade300);
            textColor = isSelected
                ? Colors.white
                : (isEnabled ? Colors.grey.shade600 : Colors.grey.shade400);
            glowColor = Colors.orange.shade400;
            break;
          default:
            buttonColor = Colors.white.withValues(alpha: 0.8);
            textColor = Colors.grey.shade600;
            glowColor = Colors.grey;
        }

        final promotionExam = _getPromotionExamForDifficulty(value);
        final currentPoints = ref.read(totalPointsProvider);
        final remainingPoints = promotionExam != null && !isEnabled
            ? (promotionExam.requiredPoints - currentPoints)
            : 0;

        return GestureDetector(
          onTap: isEnabled
              ? () => setState(() => _selectedDifficulty = value)
              : () => _showPromotionExamDialog(value),
          child: GlassMorphismWidget(
            borderRadius: 16,
            backgroundColor: buttonColor,
            borderColor: isSelected
                ? glowColor.withValues(alpha: 0.5)
                : Colors.grey.shade300,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: 0.4),
                      blurRadius: 15,
                    ),
                  ]
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                      if (!isEnabled) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock,
                          color: Colors.grey.shade400,
                          size: 16,
                        ),
                      ],
                    ],
                  ),
                  if (!isEnabled && promotionExam != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '昇格試験まであと${NumberFormat('#,###').format(remainingPoints > 0 ? remainingPoints : 0)}pt',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 昇格試験のタグが一意に決まるまでに必要な選択が揃っているか
  bool _hasScopeForPromotionExam() {
    if (widget.category == AppConstants.categoryHistory) {
      return _selectedRegion != null && _selectedRegion!.isNotEmpty;
    }
    if (widget.category == AppConstants.categoryTeams) {
      return _selectedCountry != null &&
          _selectedCountry!.isNotEmpty &&
          _selectedTeam != null &&
          _selectedTeam!.isNotEmpty;
    }
    return true;
  }

  String _messageWhenPromotionExamScopeMissing() {
    if (widget.category == AppConstants.categoryHistory) {
      return '昇格試験に進むには、先に地域（日本または世界）を選んでください。';
    }
    if (widget.category == AppConstants.categoryTeams) {
      return '昇格試験に進むには、先に国とチームを選んでください。';
    }
    return '必要な設定を選択してください。';
  }

  void _showPromotionExamDialog(String targetDifficulty) {
    if (!_hasScopeForPromotionExam()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_messageWhenPromotionExamScopeMissing()),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    final tags = _generateTags();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('昇格試験が必要です'),
        content: Text(
          '${targetDifficulty.toUpperCase()}難易度をアンロックするには、昇格試験に合格する必要があります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              final uri = Uri(
                path: '/promotion-exam',
                queryParameters: {
                  'category': widget.category,
                  'tags': tags,
                  'targetDifficulty': targetDifficulty,
                },
              );
              context.push(uri.toString());
            },
            child: const Text('昇格試験を受ける'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegionSelector() {
    return _buildSectionSelector(
      icon: Icons.public,
      title: '地域',
      children: [
        _buildChip('日本', 'japan', _selectedRegion,
            (value) => setState(() => _selectedRegion = value)),
        _buildChip('世界', 'world', _selectedRegion,
            (value) => setState(() => _selectedRegion = value)),
      ],
    );
  }

  Widget _buildCountrySelector() {
    final countries = [
      {'label': '日本', 'value': 'japan', 'flag': '🇯🇵'},
      {'label': 'イングランド', 'value': 'england', 'flag': '🇬🇧'},
      {'label': 'スペイン', 'value': 'spain', 'flag': '🇪🇸'},
      {'label': 'イタリア', 'value': 'italy', 'flag': '🇮🇹'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.public,
              color: AppColors.stitchEmerald,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '国',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: countries.map((c) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCountryChip(
                  c['label']!,
                  c['value']!,
                  c['flag']!,
                  _selectedCountry,
                  (value) => setState(() => _selectedCountry = value),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryChip(
    String label,
    String value,
    String flag,
    String? selectedValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = selectedValue == value;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: GlassMorphismWidget(
        borderRadius: 20,
        backgroundColor: isSelected
            ? AppColors.techIndigo
            : Colors.white.withValues(alpha: 0.8),
        borderColor: isSelected
            ? AppColors.stitchEmerald.withValues(alpha: 0.3)
            : Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelector() {
    List<Map<String, String>> teams = [];
    
    if (_selectedCountry == 'japan') {
      teams = [
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
    } else if (_selectedCountry == 'italy') {
      teams = [
        {'label': 'ユベントス', 'value': 'juventus'},
        {'label': 'ACミラン', 'value': 'ac_milan'},
        {'label': 'インテルミラノ', 'value': 'inter_milan'},
      ];
    } else if (_selectedCountry == 'spain') {
      teams = [
        {'label': 'レアルマドリード', 'value': 'real_madrid'},
        {'label': 'バルセロナ', 'value': 'barcelona'},
        {'label': 'アトレティコマドリード', 'value': 'atletico_madrid'},
      ];
    } else if (_selectedCountry == 'england') {
      teams = [
        {'label': 'リバプール', 'value': 'liverpool'},
        {'label': 'アーセナル', 'value': 'arsenal'},
        {'label': 'マンチェスターシティ', 'value': 'manchester_city'},
        {'label': 'マンチェスターユナイテッド', 'value': 'manchester_united'},
        {'label': 'チェルシー', 'value': 'chelsea'},
      ];
    } else {
      // 国が選択されていない場合は空のリストを返す
      teams = [];
    }

    // チーム選択は2列グリッド + スクロールバーで表示
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.category,
              color: AppColors.stitchEmerald,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'チーム',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Scrollbar(
            controller: _teamScrollController,
            thumbVisibility: true,
            child: GridView.builder(
              controller: _teamScrollController,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final isOverseas = _selectedCountry == 'england' ||
                    _selectedCountry == 'spain' ||
                    _selectedCountry == 'italy';
                return _buildTeamCard(
                  team['label']!,
                  team['value']!,
                  _selectedTeam,
                  (value) => setState(() => _selectedTeam = value),
                  isComingSoon: isOverseas,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamColorBar(List<Color> colors) {
    if (colors.isEmpty) return const SizedBox.shrink();
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: colors.length == 1
            ? ColoredBox(color: colors[0])
            : Column(
                children: colors
                    .map((c) => Expanded(
                          child: Container(color: c),
                        ))
                    .toList(),
              ),
      ),
    );
  }

  /// チームのクラブカラーを取得（著作権を避けるためロゴの代わりにカラー表示）
  List<Color> _getTeamColors(String teamValue) {
    final colors = <String, List<int>>{
      // J1/J2（ユーザー提供の公式カラー）
      'kashima_antlers': [0xFF8B0000, 0xFF001F3F, 0xFFFFD700], // ディープレッド・ネイビー・ゴールド
      'mito_hollyhock': [0xFF003399, 0xFF87CEEB], // 青・水色
      'urawa_reds': [0xFFDC143C, 0xFF000000], // 赤・黒
      'jef_united_chiba': [0xFFFFD700, 0xFF228B22, 0xFFDC143C], // 黄色・緑・赤
      'kashiwa_reysol': [0xFFFFD700, 0xFF000000], // 黄色・黒
      'fc_tokyo': [0xFF003399, 0xFFDC143C], // 青・赤
      'tokyo_verdy': [0xFF228B22, 0xFFFFFFFF, 0xFFFFD700], // 緑・白・ゴールド
      'machida_zelvia': [0xFF001F3F, 0xFF0066CC], // ネイビー〜ブルー
      'kawasaki_frontale': [0xFF4799B0, 0xFF000000], // サックスブルー・黒
      'yokohama_f_marinos': [0xFF003399, 0xFFDC143C, 0xFFFFFFFF], // 青・赤・白（トリコロール）
      'shimizu_s_pulse': [0xFFFF8C00, 0xFF003399], // オレンジ・青
      'nagoya_grampus': [0xFFDC143C, 0xFFFF8C00, 0xFFFFD700], // 赤・オレンジ・黄色
      'kyoto_sanga': [0xFF6A0DAD, 0xFFDC143C], // パープル・赤
      'gamba_osaka': [0xFF003399, 0xFF000000], // 青・黒
      'cerezo_osaka': [0xFFE91E8C, 0xFF001F3F], // セレッソピンク・ネイビー
      'vissel_kobe': [0xFF8B0000, 0xFF000000, 0xFFFFFFFF], // クリムゾンレッド・黒・白
      'fagiano_okayama': [0xFF722F37, 0xFF001F3F], // エンジ・ネイビー
      'sanfrecce_hiroshima': [0xFF6A0DAD, 0xFFFFFFFF], // 紫・白
      'avispa_fukuoka': [0xFF001F3F, 0xFF87CEEB], // ネイビー・水色
      'v_varen_nagasaki': [0xFFFF8C00, 0xFF003399], // オレンジ・青
      // セリエA
      'juventus': [0xFFFFFFFF, 0xFF000000], // 白・黒
      'ac_milan': [0xFFDC143C, 0xFF000000], // 赤・黒
      'inter_milan': [0xFF003399, 0xFF000000], // 青・黒
      // ラリーガ
      'real_madrid': [0xFFFFFFFF],
      'barcelona': [0xFF003399, 0xFFDC143C], // 青・赤
      'atletico_madrid': [0xFFDC143C, 0xFFFFFFFF], // 赤・白
      // プレミアリーグ
      'liverpool': [0xFFDC143C],
      'arsenal': [0xFFDC143C, 0xFFFFFFFF],
      'manchester_city': [0xFF6CACE4],
      'manchester_united': [0xFFDC143C],
      'chelsea': [0xFF003399],
    };
    final hexList = colors[teamValue] ?? [0xFF9E9E9E]; // デフォルトはグレー
    return hexList.map((h) => Color(h)).toList();
  }

  Widget _buildTeamCard(
    String label,
    String value,
    String? selectedValue,
    ValueChanged<String> onSelected, {
    bool isComingSoon = false,
  }) {
    final isSelected = !isComingSoon && selectedValue == value;
    final teamColors = _getTeamColors(value);

    return GestureDetector(
      onTap: isComingSoon ? null : () => onSelected(value),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isComingSoon
                  ? Colors.grey.shade100
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.stitchEmerald
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Opacity(
                  opacity: isComingSoon ? 0.4 : 1.0,
                  child: _buildTeamColorBar(teamColors),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isComingSoon
                          ? Colors.grey.shade400
                          : Colors.grey.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isComingSoon)
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.stitchEmerald
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.stitchEmerald
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
              ],
            ),
          ),
          if (isComingSoon)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Transform.rotate(
                      angle: -0.15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFFFF3366)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3366)
                                  .withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'COMING SOON',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionSelector({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppColors.stitchEmerald,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: children,
        ),
      ],
    );
  }

  Widget _buildChip(
    String label,
    String value,
    String? selectedValue,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = selectedValue == value;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: GlassMorphismWidget(
        borderRadius: 20,
        backgroundColor: isSelected
            ? AppColors.techIndigo
            : Colors.white.withValues(alpha: 0.8),
        borderColor: isSelected
            ? AppColors.stitchEmerald.withValues(alpha: 0.3)
            : Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildLeagueTypeSelector() {
    return FutureBuilder<Map<String, int>>(
      future: _getLeagueTypePlayCounts(),
      builder: (context, snapshot) {
        final playCounts = snapshot.data ?? {};
        final j1PlayCount = playCounts[AppConstants.leagueTypeJ1] ?? 0;
        final europePlayCount = playCounts[AppConstants.leagueTypeEurope] ?? 0;
        final j1CanPlay = j1PlayCount < 3;
        final europeCanPlay = europePlayCount < 3;
        
        return _buildSectionSelector(
          icon: Icons.sports_soccer,
          title: 'リーグ',
          children: [
            _buildLeagueTypeChip(
              'J1リーグ',
              AppConstants.leagueTypeJ1,
              _selectedLeagueType,
              j1CanPlay,
              j1PlayCount,
              (value) => setState(() => _selectedLeagueType = value),
            ),
            _buildLeagueTypeChip(
              'ヨーロッパサッカー',
              AppConstants.leagueTypeEurope,
              _selectedLeagueType,
              europeCanPlay,
              europePlayCount,
              (value) => setState(() => _selectedLeagueType = value),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _getLeagueTypePlayCounts() async {
    final databaseService = ref.read(databaseServiceProvider);
    final j1Count = await databaseService.getMatchDayPlayCountByLeagueType(AppConstants.leagueTypeJ1);
    final europeCount = await databaseService.getMatchDayPlayCountByLeagueType(AppConstants.leagueTypeEurope);
    return {
      AppConstants.leagueTypeJ1: j1Count,
      AppConstants.leagueTypeEurope: europeCount,
    };
  }

  Widget _buildLeagueTypeChip(
    String label,
    String value,
    String? selectedValue,
    bool canPlay,
    int playCount,
    ValueChanged<String> onSelected,
  ) {
    final isSelected = selectedValue == value;
    final isDisabled = !canPlay;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () => onSelected(isSelected ? '' : value),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: GlassMorphismWidget(
          borderRadius: 20,
          backgroundColor: isDisabled
              ? Colors.grey.shade300
              : (isSelected
                  ? AppColors.techIndigo
                  : Colors.white.withValues(alpha: 0.8)),
          borderColor: isDisabled
              ? Colors.grey.shade400
              : (isSelected
                  ? AppColors.stitchEmerald.withValues(alpha: 0.3)
                  : Colors.grey.shade300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: isDisabled
                      ? Colors.grey.shade600
                      : (isSelected ? Colors.white : Colors.grey.shade700),
                ),
              ),
              if (isDisabled) ...[
                const SizedBox(width: 8),
                Text(
                  '(3回プレイ済み)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ] else if (playCount > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '($playCount/3回)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.white.withValues(alpha: 0.8) : Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _canStart() {
    if (widget.category == AppConstants.categoryRules) {
      return _selectedDifficulty != null && _selectedDifficulty!.isNotEmpty;
    }

    if (widget.category == AppConstants.categoryMatchRecap) {
      return _selectedLeagueType != null &&
          _selectedLeagueType!.isNotEmpty;
    }

    if (widget.category == AppConstants.categoryHistory) {
      return _selectedDifficulty != null &&
          _selectedDifficulty!.isNotEmpty &&
          _selectedRegion != null &&
          _selectedRegion!.isNotEmpty;
    }

    if (widget.category == AppConstants.categoryTeams) {
      return _selectedDifficulty != null &&
          _selectedDifficulty!.isNotEmpty &&
          _selectedCountry != null &&
          _selectedCountry!.isNotEmpty &&
          _selectedTeam != null &&
          _selectedTeam!.isNotEmpty;
    }

    return false;
  }

  Future<void> _validateAndStart() async {
    if (!_canStart()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('必要な設定を選択してください。'),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    _startQuiz();
  }

  void _startQuiz() {
    final uri = Uri(
      path: '/quiz',
      queryParameters: {
        'category': widget.category,
        if (widget.category != AppConstants.categoryMatchRecap)
          'difficulty': _selectedDifficulty ?? '',
        if (_selectedRegion != null && _selectedRegion!.isNotEmpty)
          'region': _selectedRegion!,
        if (_selectedCountry != null && _selectedCountry!.isNotEmpty)
          'country': _selectedCountry!,
        if (_selectedTeam != null && _selectedTeam!.isNotEmpty)
          'team': _selectedTeam!,
        if (_selectedLeagueType != null && _selectedLeagueType!.isNotEmpty)
          'leagueType': _selectedLeagueType!,
      },
    );
    context.push(uri.toString());
  }
}
