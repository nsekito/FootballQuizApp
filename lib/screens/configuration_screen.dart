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
  String? _selectedRange;
  String? _selectedNewsRegion; // ニュースクイズ用の地域
  String? _selectedYear; // ニュースクイズ用の年
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

                // 難易度選択（Weekly Recap以外）
                if (widget.category != AppConstants.categoryMatchRecap) ...[
                  _buildDifficultySelector(),
                  const SizedBox(height: 40),
                ],

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

                // チームクイズ: 国選択と範囲選択
                if (widget.category == AppConstants.categoryTeams) ...[
                  _buildCountrySelector(),
                  const SizedBox(height: 24),
                  _buildRangeSelector(),
                  const SizedBox(height: 40),
                ],

                // ニュースクイズ: 地域選択と年選択
                if (widget.category == AppConstants.categoryNews) ...[
                  _buildNewsRegionSelector(),
                  const SizedBox(height: 24),
                  _buildYearSelector(),
                  const SizedBox(height: 40),
                ],

                // STARTボタン
                GlowButton(
                  glowColor: AppColors.stitchEmerald,
                  onPressed: _canStart() ? _validateAndStart : null,
                  backgroundColor: AppColors.stitchEmerald,
                  foregroundColor: Colors.white,
                  borderRadius: 16,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Text(
                    'START',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          children: [
            _buildDifficultyButton('EASY', AppConstants.difficultyEasy),
            _buildDifficultyButton('NORMAL', AppConstants.difficultyNormal),
            _buildDifficultyButton('HARD', AppConstants.difficultyHard),
            _buildDifficultyButton('EXTREME', AppConstants.difficultyExtreme),
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
      if (_selectedRange != null && _selectedRange!.isNotEmpty) {
        if (_selectedRange == 'j1_all_teams') {
          tags.add('j1');
        } else if (_selectedRange == 'j2_all_teams') {
          tags.add('j2');
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

  Widget _buildDifficultyButton(String label, String value) {
    return FutureBuilder<bool>(
      future: _isDifficultyUnlocked(value),
      builder: (context, snapshot) {
        final isUnlocked = snapshot.data ?? (value == AppConstants.difficultyEasy);
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

        // NORMALがロックされている場合、昇格試験の情報を取得
        PromotionExam? promotionExam;
        if (value == AppConstants.difficultyNormal && !isEnabled) {
          final tags = _generateTags();
          promotionExam = PromotionExam.easyToNormal(
            category: widget.category,
            tags: tags,
          );
        }

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
                borderColor: isSelected
                    ? glowColor.withValues(alpha: 0.5)
                    : Colors.grey.shade300,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // NORMALがロックされている場合は「NORMALの昇格試験を受ける」に変更
                              (value == AppConstants.difficultyNormal && !isEnabled)
                                  ? 'NORMALの昇格試験を受ける'
                                  : label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                fontSize: (value == AppConstants.difficultyNormal && !isEnabled) ? 12 : null,
                              ),
                            ),
                            if (!isEnabled)
                              if (promotionExam != null)
                                // 昇格試験の条件を表示
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'ランクは${promotionExam.requiredRank.japaneseName}以上、ポイントは${NumberFormat('#,###').format(promotionExam.requiredPoints)}が必要です',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                )
                              else
                                Text(
                                  '昇格試験でアンロック',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: textColor,
                          size: 20,
                        )
                      else if (!isEnabled)
                        Icon(
                          Icons.lock,
                          color: Colors.grey.shade400,
                          size: 16,
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
        _buildChip('指定なし', '', _selectedCountry,
            (value) => setState(() => _selectedCountry = value)),
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

  Widget _buildRangeSelector() {
    final ranges = _selectedCountry == 'japan'
        ? [
            {'label': 'J1全チーム', 'value': 'j1_all_teams'},
            {'label': 'J2全チーム', 'value': 'j2_all_teams'},
            {'label': '指定なし', 'value': ''},
          ]
        : _selectedCountry != null && _selectedCountry!.isNotEmpty
            ? [
                {'label': '海外Top3', 'value': 'overseas_top3'},
                {'label': '指定なし', 'value': ''},
              ]
            : [
                {'label': '指定なし', 'value': ''},
              ];

    return _buildSectionSelector(
      icon: Icons.category,
      title: '範囲',
      children: ranges.map((range) {
        return _buildChip(
          range['label']!,
          range['value']!,
          _selectedRange,
          (value) => setState(() => _selectedRange = value),
        );
      }).toList(),
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

  Widget _buildNewsRegionSelector() {
    return _buildSectionSelector(
      icon: Icons.public,
      title: '地域',
      children: [
        _buildChip('指定なし', '', _selectedNewsRegion,
            (value) => setState(() => _selectedNewsRegion = value)),
        _buildChip('国内', AppConstants.regionDomestic, _selectedNewsRegion,
            (value) => setState(() => _selectedNewsRegion = value)),
        _buildChip('世界', AppConstants.regionWorld, _selectedNewsRegion,
            (value) => setState(() => _selectedNewsRegion = value)),
      ],
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    final years = List.generate(6, (index) => (currentYear - index).toString());

    return _buildSectionSelector(
      icon: Icons.calendar_today,
      title: '年',
      children: [
        _buildChip('指定なし', '', _selectedYear,
            (value) => setState(() => _selectedYear = value)),
        ...years.map((year) {
          return _buildChip(
            year,
            year,
            _selectedYear,
            (value) => setState(() => _selectedYear = value),
          );
        }),
      ],
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
      return _selectedDifficulty != null && _selectedDifficulty!.isNotEmpty;
    }

    if (widget.category == AppConstants.categoryNews) {
      return _selectedDifficulty != null && _selectedDifficulty!.isNotEmpty;
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
        if (_selectedRange != null && _selectedRange!.isNotEmpty)
          'range': _selectedRange!,
        if (_selectedNewsRegion != null && _selectedNewsRegion!.isNotEmpty)
          'region': _selectedNewsRegion!,
        if (_selectedYear != null && _selectedYear!.isNotEmpty)
          'year': _selectedYear!,
        if (_selectedLeagueType != null && _selectedLeagueType!.isNotEmpty)
          'leagueType': _selectedLeagueType!,
      },
    );
    context.push(uri.toString());
  }
}
