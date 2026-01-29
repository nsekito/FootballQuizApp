import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants.dart';
import '../constants/app_colors.dart';
import '../widgets/background_widget.dart';

class ConfigurationScreen extends StatefulWidget {
  final String category;

  const ConfigurationScreen({
    super.key,
    required this.category,
  });

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  String? _selectedDifficulty;
  String? _selectedRegion;
  String? _selectedCountry;
  String? _selectedRange;
  String? _selectedNewsRegion; // ニュースクイズ用の地域
  String? _selectedYear; // ニュースクイズ用の年

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryTitle()),
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
              Text(
                'クイズ設定',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),

              // 難易度選択（全カテゴリ共通）
              _buildDifficultySelector(),
              const SizedBox(height: 24),

              // 歴史クイズ: 地域選択
              if (widget.category == AppConstants.categoryHistory) ...[
                _buildRegionSelector(),
                const SizedBox(height: 24),
              ],

              // チームクイズ: 国選択と範囲選択
              if (widget.category == AppConstants.categoryTeams) ...[
                _buildCountrySelector(),
                const SizedBox(height: 16),
                _buildRangeSelector(),
                const SizedBox(height: 24),
              ],

              // ニュースクイズ: 地域選択と年選択
              if (widget.category == AppConstants.categoryNews) ...[
                _buildNewsRegionSelector(),
                const SizedBox(height: 16),
                _buildYearSelector(),
                const SizedBox(height: 24),
              ],

              // STARTボタン
              ElevatedButton(
                onPressed: _canStart() ? _validateAndStart : null,
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
                  'START',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  String _getCategoryTitle() {
    switch (widget.category) {
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
        return 'クイズ設定';
    }
  }

  Widget _buildDifficultySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '難易度',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(
              'EASY',
              AppConstants.difficultyEasy,
              _selectedDifficulty,
              (value) => setState(() => _selectedDifficulty = value),
            ),
            _buildChip(
              'NORMAL',
              AppConstants.difficultyNormal,
              _selectedDifficulty,
              (value) => setState(() => _selectedDifficulty = value),
            ),
            _buildChip(
              'HARD',
              AppConstants.difficultyHard,
              _selectedDifficulty,
              (value) => setState(() => _selectedDifficulty = value),
            ),
            _buildChip(
              'EXTREME',
              AppConstants.difficultyExtreme,
              _selectedDifficulty,
              (value) => setState(() => _selectedDifficulty = value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRegionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '地域',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(
              '日本',
              'japan',
              _selectedRegion,
              (value) => setState(() => _selectedRegion = value),
            ),
            _buildChip(
              '世界',
              'world',
              _selectedRegion,
              (value) => setState(() => _selectedRegion = value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCountrySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '国',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(
              '指定なし',
              '',
              _selectedCountry,
              (value) => setState(() => _selectedCountry = value),
            ),
            _buildChip(
              '日本',
              'japan',
              _selectedCountry,
              (value) => setState(() => _selectedCountry = value),
            ),
            _buildChip(
              'イタリア',
              'italy',
              _selectedCountry,
              (value) => setState(() => _selectedCountry = value),
            ),
            _buildChip(
              'スペイン',
              'spain',
              _selectedCountry,
              (value) => setState(() => _selectedCountry = value),
            ),
            _buildChip(
              'イングランド',
              'england',
              _selectedCountry,
              (value) => setState(() => _selectedCountry = value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRangeSelector() {
    // 国が「日本」の場合、範囲は「J1」などが自動で候補になる
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '範囲',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ranges.map((range) {
            return _buildChip(
              range['label']!,
              range['value']!,
              _selectedRange,
              (value) => setState(() => _selectedRange = value),
            );
          }).toList(),
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
    Color chipColor;
    
    // 難易度に応じた色を設定
    switch (value) {
      case AppConstants.difficultyEasy:
        chipColor = AppColors.difficultyEasy;
        break;
      case AppConstants.difficultyNormal:
        chipColor = AppColors.difficultyNormal;
        break;
      case AppConstants.difficultyHard:
        chipColor = AppColors.difficultyHard;
        break;
      case AppConstants.difficultyExtreme:
        chipColor = AppColors.difficultyExtreme;
        break;
      default:
        chipColor = Colors.grey;
    }
    
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : chipColor,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(selected ? value : '');
      },
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      backgroundColor: chipColor.withValues(alpha: 0.1),
      side: BorderSide(
        color: isSelected ? chipColor : chipColor.withValues(alpha: 0.5),
        width: isSelected ? 2 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  bool _canStart() {
    // ルールクイズとマッチリキャップ: 難易度のみ必要
    if (widget.category == AppConstants.categoryRules ||
        widget.category == AppConstants.categoryMatchRecap) {
      return _selectedDifficulty != null && _selectedDifficulty!.isNotEmpty;
    }

    // 歴史クイズ: 難易度と地域が必要
    if (widget.category == AppConstants.categoryHistory) {
      return _selectedDifficulty != null &&
          _selectedDifficulty!.isNotEmpty &&
          _selectedRegion != null &&
          _selectedRegion!.isNotEmpty;
    }

    // チームクイズ: 難易度が必要（国と範囲はオプション）
    if (widget.category == AppConstants.categoryTeams) {
      return _selectedDifficulty != null && _selectedDifficulty!.isNotEmpty;
    }

    // ニュースクイズ: 難易度が必要（地域と年はオプション）
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
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    _startQuiz();
  }

  Widget _buildNewsRegionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '地域',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(
              '指定なし',
              '',
              _selectedNewsRegion,
              (value) => setState(() => _selectedNewsRegion = value),
            ),
            _buildChip(
              '国内',
              AppConstants.regionDomestic,
              _selectedNewsRegion,
              (value) => setState(() => _selectedNewsRegion = value),
            ),
            _buildChip(
              '世界',
              AppConstants.regionWorld,
              _selectedNewsRegion,
              (value) => setState(() => _selectedNewsRegion = value),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYearSelector() {
    // 現在の年から過去5年分を選択肢として提供
    final currentYear = DateTime.now().year;
    final years = List.generate(6, (index) => (currentYear - index).toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '年',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(
              '指定なし',
              '',
              _selectedYear,
              (value) => setState(() => _selectedYear = value),
            ),
            ...years.map((year) {
              return _buildChip(
                year,
                year,
                _selectedYear,
                (value) => setState(() => _selectedYear = value),
              );
            }),
          ],
        ),
      ],
    );
  }

  void _startQuiz() {
    final uri = Uri(
      path: '/quiz',
      queryParameters: {
        'category': widget.category,
        'difficulty': _selectedDifficulty ?? '',
        if (_selectedRegion != null && _selectedRegion!.isNotEmpty) 'region': _selectedRegion!,
        if (_selectedCountry != null && _selectedCountry!.isNotEmpty) 'country': _selectedCountry!,
        if (_selectedRange != null && _selectedRange!.isNotEmpty) 'range': _selectedRange!,
        if (_selectedNewsRegion != null && _selectedNewsRegion!.isNotEmpty) 'region': _selectedNewsRegion!,
        if (_selectedYear != null && _selectedYear!.isNotEmpty) 'year': _selectedYear!,
      },
    );
    context.push(uri.toString());
  }
}

