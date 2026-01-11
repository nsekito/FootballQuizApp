import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/constants.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryTitle()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
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

              // STARTボタン
              ElevatedButton(
                onPressed: _canStart() ? _startQuiz : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
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
        ? ['J1全チーム', 'J2全チーム']
        : ['海外Top3', '指定なし'];

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
            final value = range.toLowerCase().replaceAll(' ', '_');
            return _buildChip(
              range,
              value,
              null, // 範囲選択はまだ実装していない
              (value) {
                // 将来の実装用
              },
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
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(selected ? value : '');
      },
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green.shade700,
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

    // ニュースクイズ: 難易度のみ必要
    if (widget.category == AppConstants.categoryNews) {
      return _selectedDifficulty != null && _selectedDifficulty!.isNotEmpty;
    }

    return false;
  }

  void _startQuiz() {
    final uri = Uri(
      path: '/quiz',
      queryParameters: {
        'category': widget.category,
        'difficulty': _selectedDifficulty ?? '',
        if (_selectedRegion != null) 'region': _selectedRegion!,
        if (_selectedCountry != null) 'country': _selectedCountry!,
      },
    );
    context.push(uri.toString());
  }
}
