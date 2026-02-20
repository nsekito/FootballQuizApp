import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';
import '../utils/unlock_key_utils.dart';
import '../providers/user_data_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.stitchBackgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          CategoryDifficultyUtils.getCategoryTitle(widget.category),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: GridPatternBackground(
        child: SingleChildScrollView(
          child: ResponsiveContainer(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'クイズ設定',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Weekly Recap: リーグタイプ選択
                if (widget.category == AppConstants.categoryMatchRecap) ...[
                  _buildLeagueTypeSelector(),
                  const SizedBox(height: 40),
                ],

                // 歴史クイズ: 地域選択
                if (widget.category == AppConstants.categoryHistory) ...[
                  _buildRegionSelector(),
                  const SizedBox(height: 40),
                ],

                // チームクイズ: 国選択とチーム選択
                if (widget.category == AppConstants.categoryTeams) ...[
                  _buildCountrySelector(),
                  const SizedBox(height: 24),
                  _buildTeamSelector(),
                  const SizedBox(height: 40),
                ],

                // 難易度選択（Weekly Recap以外）- 最後に表示
                if (widget.category != AppConstants.categoryMatchRecap) ...[
                  _buildDifficultySelector(),
                  const SizedBox(height: 40),
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
      ),
      bottomNavigationBar: const BannerAdWidget(),
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
              '難易度 (Difficulty)',
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
        // 縦に並べる（1列）
        Column(
          children: [
            _buildDifficultyButton('EASY', AppConstants.difficultyEasy),
            const SizedBox(height: 12),
            _buildDifficultyButton('NORMAL', AppConstants.difficultyNormal),
            const SizedBox(height: 12),
            _buildDifficultyButton('HARD', AppConstants.difficultyHard),
            // チームクイズではEXTREMEを表示しない
            if (widget.category != AppConstants.categoryTeams) ...[
              const SizedBox(height: 12),
              _buildDifficultyButton('EXTREME', AppConstants.difficultyExtreme),
            ],
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
        } else if (_selectedTeam == 'serie_a_all_teams') {
          tags.add('serie_a');
        } else if (_selectedTeam == 'la_liga_all_teams') {
          tags.add('la_liga');
        } else if (_selectedTeam == 'premier_league_all_teams') {
          tags.add('premier_league');
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
    
    // HARDがアンロック済みでEXTREMEがロックされている場合、EXTREMEが次にアンロックできる
    if (widget.category != AppConstants.categoryTeams) {
      final extremeUnlockKey = UnlockKeyUtils.generateUnlockKey(
        category: widget.category,
        difficulty: AppConstants.difficultyExtreme,
        tags: tags,
      );
      if (!unlockedDifficulties.contains(extremeUnlockKey)) {
        return AppConstants.difficultyExtreme;
      }
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
      case AppConstants.difficultyExtreme:
        return PromotionExam.hardToExtreme(
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
        final nextUnlockable = snapshot.data?[1] as String?;
        final isNextUnlockable = !isUnlocked && nextUnlockable == value;
        final isSelected = _selectedDifficulty == value;
        Color buttonColor;
        Color textColor;
        Color glowColor;
        final isEnabled = isUnlocked;

        // 次にアンロックできる難易度の場合、特別なスタイルを適用
        if (isNextUnlockable) {
          switch (value) {
            case AppConstants.difficultyNormal:
              buttonColor = Colors.blue.shade50;
              textColor = Colors.blue.shade700;
              glowColor = Colors.blue.shade400;
              break;
            case AppConstants.difficultyHard:
              buttonColor = Colors.orange.shade50;
              textColor = Colors.orange.shade700;
              glowColor = Colors.orange.shade400;
              break;
            case AppConstants.difficultyExtreme:
              buttonColor = Colors.red.shade50;
              textColor = Colors.red.shade700;
              glowColor = Colors.red.shade400;
              break;
            default:
              buttonColor = Colors.grey.shade300;
              textColor = Colors.grey.shade400;
              glowColor = Colors.grey;
          }
        } else {
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
            case AppConstants.difficultyExtreme:
              buttonColor = isSelected
                  ? Colors.red.shade400
                  : (isEnabled 
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.grey.shade300);
              textColor = isSelected
                  ? Colors.white
                  : (isEnabled ? Colors.grey.shade600 : Colors.grey.shade400);
              glowColor = Colors.red.shade400;
              break;
            default:
              buttonColor = Colors.white.withValues(alpha: 0.8);
              textColor = Colors.grey.shade600;
              glowColor = Colors.grey;
          }
        }

        // 昇格試験の情報を取得
        final promotionExam = _getPromotionExamForDifficulty(value);
        final currentPoints = ref.read(totalPointsProvider);
        final remainingPoints = promotionExam != null && !isEnabled
            ? (promotionExam.requiredPoints - currentPoints)
            : 0;

        return GestureDetector(
          onTap: isEnabled
              ? () => setState(() {
                  _selectedDifficulty = isSelected ? null : value;
                })
              : () => _showPromotionExamDialog(value),
          child: Stack(
            children: [
              GlassMorphismWidget(
                borderRadius: 16,
                backgroundColor: buttonColor,
                borderColor: isNextUnlockable
                    ? glowColor.withValues(alpha: 0.6)
                    : (isSelected
                        ? glowColor.withValues(alpha: 0.5)
                        : Colors.grey.shade300),
                boxShadow: isNextUnlockable || isSelected
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: isNextUnlockable ? 0.5 : 0.4),
                          blurRadius: isNextUnlockable ? 20 : 15,
                          spreadRadius: isNextUnlockable ? 2 : 0,
                        ),
                      ]
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (isNextUnlockable)
                                      Icon(
                                        Icons.star,
                                        color: glowColor,
                                        size: 18,
                                      ),
                                    if (isNextUnlockable)
                                      const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        isNextUnlockable
                                            ? '🎯 $label をアンロック！'
                                            : label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                          fontSize: isNextUnlockable ? 15 : 16,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isNextUnlockable && promotionExam != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (remainingPoints > 0)
                                          Text(
                                            'あと${NumberFormat('#,###').format(remainingPoints)}ポイントで',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: textColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        else
                                          Text(
                                            '✨ 今すぐ昇格試験を受験できます！',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: glowColor,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            remainingPoints > 0
                                                ? '昇格試験を受験できます'
                                                : 'タップして昇格試験へ',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textColor.withValues(alpha: 0.8),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else if (!isEnabled && promotionExam != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'ランク${promotionExam.requiredRank.japaneseName}以上、${NumberFormat('#,###').format(promotionExam.requiredPoints)}ポイント必要',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                else if (!isEnabled)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '昇格試験でアンロック',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: textColor,
                              size: 24,
                            )
                          else if (!isEnabled)
                            Icon(
                              isNextUnlockable ? Icons.lock_open : Icons.lock,
                              color: isNextUnlockable ? glowColor : Colors.grey.shade400,
                              size: 22,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPromotionExamDialog(String targetDifficulty) {
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
    return _buildSectionSelector(
      icon: Icons.public,
      title: '国 (Country)',
      children: [
        _buildChip('日本', 'japan', _selectedCountry,
            (value) => setState(() => _selectedCountry = value)),
        _buildChip('イタリア', 'italy', _selectedCountry,
            (value) => setState(() => _selectedCountry = value)),
        _buildChip('スペイン', 'spain', _selectedCountry,
            (value) => setState(() => _selectedCountry = value)),
        _buildChip('イングランド', 'england', _selectedCountry,
            (value) => setState(() => _selectedCountry = value)),
      ],
    );
  }

  Widget _buildTeamSelector() {
    List<Map<String, String>> teams = [];
    
    if (_selectedCountry == 'japan') {
      teams = [
        {'label': 'J1全チーム', 'value': 'j1_all_teams'},
        {'label': 'J2全チーム', 'value': 'j2_all_teams'},
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
        {'label': 'セリエA全チーム', 'value': 'serie_a_all_teams'},
        {'label': 'ユベントス', 'value': 'juventus'},
        {'label': 'ACミラン', 'value': 'ac_milan'},
        {'label': 'インテルミラノ', 'value': 'inter_milan'},
      ];
    } else if (_selectedCountry == 'spain') {
      teams = [
        {'label': 'ラリーガ全チーム', 'value': 'la_liga_all_teams'},
        {'label': 'レアルマドリード', 'value': 'real_madrid'},
        {'label': 'バルセロナ', 'value': 'barcelona'},
        {'label': 'アトレティコマドリード', 'value': 'atletico_madrid'},
      ];
    } else if (_selectedCountry == 'england') {
      teams = [
        {'label': 'プレミアリーグ全チーム', 'value': 'premier_league_all_teams'},
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

    // チーム選択は多数の選択肢があるため、スクロール可能なレイアウトを使用
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
              'チーム'.toUpperCase(),
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
        SizedBox(
          height: teams.length > 10 ? 200 : null, // 選択肢が多い場合は高さを制限
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: teams.map((team) {
                return _buildChip(
                  team['label']!,
                  team['value']!,
                  _selectedTeam,
                  (value) => setState(() => _selectedTeam = value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
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
      onTap: () => onSelected(isSelected ? '' : value),
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
    return _buildSectionSelector(
      icon: Icons.sports_soccer,
      title: 'リーグ',
      children: [
        _buildChip('J1リーグ', AppConstants.leagueTypeJ1, _selectedLeagueType,
            (value) => setState(() => _selectedLeagueType = value)),
        _buildChip('ヨーロッパサッカー', AppConstants.leagueTypeEurope, _selectedLeagueType,
            (value) => setState(() => _selectedLeagueType = value)),
      ],
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
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
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
