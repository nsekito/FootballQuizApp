import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/admin_mode_provider.dart';
import '../providers/user_data_provider.dart';
import '../providers/question_unlock_provider.dart';
import '../providers/login_bonus_provider.dart';
import '../providers/quiz_history_provider.dart';
import '../providers/database_provider.dart';
import '../models/user_rank.dart';
import '../constants/app_colors.dart';
import '../constants/game_config.dart';
import '../widgets/grid_pattern_background.dart';
import '../widgets/glass_morphism_widget.dart';
import '../widgets/responsive_container.dart';
import '../widgets/banner_ad_widget.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final TextEditingController _expController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  UserRank? _selectedRank;
  bool _isExpSetting = false;
  bool _isPointsSetting = false;
  bool _isResettingQuestions = false;
  bool _isResettingDifficulties = false;
  bool _isUnlockingNormal = false;
  bool _isUnlockingHard = false;
  bool _isResettingLoginBonus = false;
  bool _isSettingStreakDays = false;
  final TextEditingController _streakDaysController = TextEditingController();
  bool _isResettingHistory = false;
  bool _isResettingMatchDay = false;
  bool _isResettingAllData = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  @override
  void dispose() {
    _expController.dispose();
    _pointsController.dispose();
    _streakDaysController.dispose();
    super.dispose();
  }

  void _loadCurrentValues() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentExp = ref.read(totalExpProvider);
      final currentPoints = ref.read(totalPointsProvider);
      final currentRank = ref.read(userRankProvider);
      
      _expController.text = currentExp.toString();
      _pointsController.text = currentPoints.toString();
      _selectedRank = currentRank;
    });
  }

  Future<void> _setExp() async {
    final expText = _expController.text.trim();
    if (expText.isEmpty) {
      _showErrorSnackBar('EXPを入力してください');
      return;
    }

    final exp = int.tryParse(expText);
    if (exp == null || exp < 0) {
      _showErrorSnackBar('有効なEXP値を入力してください（0以上）');
      return;
    }

    if (exp > 999999) {
      _showErrorSnackBar('EXP値が大きすぎます（最大999,999）');
      return;
    }

    setState(() {
      _isExpSetting = true;
    });

    try {
      await ref.read(totalExpProvider.notifier).setExp(exp);
      if (mounted) {
        _showSuccessSnackBar('EXPを${NumberFormat('#,###').format(exp)}に設定しました');
        // ランクが変更された可能性があるため、選択を更新
        final newRank = ref.read(userRankProvider);
        setState(() {
          _selectedRank = newRank;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('EXPの設定に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExpSetting = false;
        });
      }
    }
  }

  Future<void> _setPoints() async {
    final pointsText = _pointsController.text.trim();
    if (pointsText.isEmpty) {
      _showErrorSnackBar('ポイントを入力してください');
      return;
    }

    final points = int.tryParse(pointsText);
    if (points == null || points < 0) {
      _showErrorSnackBar('有効なポイント値を入力してください（0以上）');
      return;
    }

    if (points > 999999) {
      _showErrorSnackBar('ポイント値が大きすぎます（最大999,999）');
      return;
    }

    setState(() {
      _isPointsSetting = true;
    });

    try {
      await ref.read(totalPointsProvider.notifier).setPoints(points);
      if (mounted) {
        _showSuccessSnackBar('ポイントを${NumberFormat('#,###').format(points)}に設定しました');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('ポイントの設定に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPointsSetting = false;
        });
      }
    }
  }

  Future<void> _setRank(UserRank rank) async {
    final exp = rank.minExp;
    
    setState(() {
      _isExpSetting = true;
    });

    try {
      await ref.read(totalExpProvider.notifier).setExp(exp);
      if (mounted) {
        setState(() {
          _selectedRank = rank;
          _expController.text = exp.toString();
        });
        _showSuccessSnackBar('ランクを${rank.japaneseName}に設定しました（EXP: ${NumberFormat('#,###').format(exp)}）');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('ランクの設定に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExpSetting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminMode = ref.watch(adminModeProvider);
    final currentExp = ref.watch(totalExpProvider);
    final currentPoints = ref.watch(totalPointsProvider);
    final currentRank = ref.watch(userRankProvider);

    // 初期値の設定（初回のみ）
    _selectedRank ??= currentRank;
    if (_expController.text.isEmpty) {
      _expController.text = currentExp.toString();
    }
    if (_pointsController.text.isEmpty) {
      _pointsController.text = currentPoints.toString();
    }

    return Scaffold(
      backgroundColor: AppColors.stitchBackgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '管理者設定',
          style: TextStyle(
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
                  '管理者設定',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // 管理者モードトグル
                _buildAdminModeToggle(adminMode),
                const SizedBox(height: 24),

                // ランク設定
                _buildRankSection(currentRank),
                const SizedBox(height: 24),

                // EXP設定
                _buildExpSection(currentExp),
                const SizedBox(height: 24),

                // ポイント設定
                _buildPointsSection(currentPoints),
                const SizedBox(height: 24),

                // 問題解放リセット
                _buildQuestionUnlockResetSection(),
                const SizedBox(height: 24),

                // 難易度解放管理
                _buildDifficultyUnlockSection(),
                const SizedBox(height: 24),

                // ログインボーナスリセット
                _buildLoginBonusResetSection(),
                const SizedBox(height: 24),

                // クイズ履歴リセット
                _buildHistoryResetSection(),
                const SizedBox(height: 24),

                // MATCH DAYプレイ回数リセット
                _buildMatchDayResetSection(),
                const SizedBox(height: 24),

                // 全ユーザーデータリセット
                _buildFullDataResetSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Widget _buildAdminModeToggle(bool adminMode) {
    return GlassMorphismWidget(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: AppColors.stitchEmerald,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '管理者モード',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  adminMode
                      ? 'すべて先頭の回答を選択すると全問正解になります'
                      : '選択肢がランダムにシャッフルされます',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: adminMode,
            onChanged: (value) {
              ref.read(adminModeProvider.notifier).setAdminMode(value);
            },
            activeThumbColor: AppColors.stitchEmerald,
          ),
        ],
      ),
    );
  }

  Widget _buildRankSection(UserRank currentRank) {
    return GlassMorphismWidget(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: AppColors.stitchEmerald,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'ランク設定',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '現在のランク: ${currentRank.japaneseName} (${currentRank.englishName})',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<UserRank>(
            initialValue: _selectedRank,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'ランクを選択',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.8),
            ),
            items: UserRank.values.map((rank) {
              return DropdownMenuItem<UserRank>(
                value: rank,
                child: Text(
                  '${rank.japaneseName} (EXP: ${NumberFormat('#,###').format(rank.minExp)}${rank.maxExp != null ? '〜${NumberFormat('#,###').format(rank.maxExp)}' : '+'})',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            onChanged: _isExpSetting
                ? null
                : (UserRank? rank) {
                    if (rank != null) {
                      _setRank(rank);
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildExpSection(int currentExp) {
    return GlassMorphismWidget(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.star,
                color: AppColors.stitchEmerald,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'EXP設定',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '現在のEXP: ${NumberFormat('#,###').format(currentExp)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _expController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'EXPを入力',
              hintText: '0〜999,999',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isExpSetting ? null : _setExp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.stitchEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isExpSetting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'EXPを設定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsSection(int currentPoints) {
    return GlassMorphismWidget(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.monetization_on,
                color: AppColors.stitchEmerald,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'ポイント設定',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '現在のポイント: ${NumberFormat('#,###').format(currentPoints)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pointsController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: InputDecoration(
              labelText: 'ポイントを入力',
              hintText: '0〜999,999',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPointsSetting ? null : _setPoints,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.stitchEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isPointsSetting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'ポイントを設定',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionUnlockResetSection() {
    final unlockedQuestionsAsync = ref.watch(unlockedQuestionIdsProvider);
    
    return GlassMorphismWidget(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_reset,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '問題解放リセット',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          unlockedQuestionsAsync.when(
            data: (unlockedIds) => Text(
              '現在の開放済み問題数: ${unlockedIds.length}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            loading: () => Text(
              '読み込み中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            error: (_, __) => Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isResettingQuestions ? null : _resetUnlockedQuestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isResettingQuestions
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '問題解放をリセット',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyUnlockSection() {
    final unlockedDifficulties = ref.watch(unlockedDifficultiesProvider);
    
    return GlassMorphismWidget(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lock_open,
                color: AppColors.stitchEmerald,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '難易度解放管理',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '現在の開放済み難易度数: ${unlockedDifficulties.length}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 24),
          // リセットボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isResettingDifficulties ? null : _resetUnlockedDifficulties,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isResettingDifficulties
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '難易度解放をリセット',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // NORMAL一括開放ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUnlockingNormal ? null : _unlockAllNormalDifficulties,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUnlockingNormal
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'NORMAL難易度を全開放',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // HARD一括開放ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUnlockingHard ? null : _unlockAllHardDifficulties,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUnlockingHard
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'HARD難易度を全開放',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetUnlockedQuestions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('問題解放をリセット'),
        content: const Text(
          'すべての開放済み問題をリセットします。この操作は元に戻せません。\n\n本当に実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isResettingQuestions = true;
    });

    try {
      await ref.read(resetUnlockedQuestionsProvider.future);
      if (mounted) {
        _showSuccessSnackBar('問題解放をリセットしました');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('リセットに失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingQuestions = false;
        });
      }
    }
  }

  Future<void> _resetUnlockedDifficulties() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('難易度解放をリセット'),
        content: const Text(
          '難易度解放を初期状態（EASY難易度のみ）にリセットします。この操作は元に戻せません。\n\n本当に実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
            ),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isResettingDifficulties = true;
    });

    try {
      await ref.read(unlockedDifficultiesProvider.notifier).resetUnlockedDifficulties();
      if (mounted) {
        _showSuccessSnackBar('難易度解放をリセットしました');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('リセットに失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingDifficulties = false;
        });
      }
    }
  }

  Future<void> _unlockAllNormalDifficulties() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('NORMAL難易度を全開放'),
        content: const Text(
          '全カテゴリ・全タグのNORMAL難易度を一括開放します。\n\n実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
            ),
            child: const Text('開放する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUnlockingNormal = true;
    });

    try {
      await ref.read(unlockedDifficultiesProvider.notifier).unlockAllNormalDifficulties();
      if (mounted) {
        _showSuccessSnackBar('NORMAL難易度を全開放しました');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('開放に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUnlockingNormal = false;
        });
      }
    }
  }

  Future<void> _unlockAllHardDifficulties() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('HARD難易度を全開放'),
        content: const Text(
          '全カテゴリ・全タグのHARD難易度を一括開放します。\n\n実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
            ),
            child: const Text('開放する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isUnlockingHard = true;
    });

    try {
      await ref.read(unlockedDifficultiesProvider.notifier).unlockAllHardDifficulties();
      if (mounted) {
        _showSuccessSnackBar('HARD難易度を全開放しました');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('開放に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUnlockingHard = false;
        });
      }
    }
  }

  Widget _buildLoginBonusResetSection() {
    final loginBonusStatus = ref.watch(loginBonusStatusProvider);
    
    return GlassMorphismWidget(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.purple.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'ログインボーナス管理',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '現在の連続日数: ${loginBonusStatus.streakDays}日',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          if (loginBonusStatus.lastDate != null) ...[
            const SizedBox(height: 8),
            Text(
              '最後に受け取った日: ${loginBonusStatus.lastDate}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '次回受け取り時のポイント: ${loginBonusStatus.points}ポイント',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.purple.shade700,
            ),
          ),
          const SizedBox(height: 24),
          // 連続日数設定
          const Text(
            '連続日数を設定（1日以上、8日目以降は1日目に戻る）',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _streakDaysController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  decoration: InputDecoration(
                    hintText: '1〜7',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isSettingStreakDays ? null : _setStreakDays,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSettingStreakDays
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('設定'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // クイック設定ボタン（1〜14日目まで表示、8日目以降は1日目に戻る）
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(14, (index) {
              final day = index + 1;
              final normalizedDay = ((day - 1) % 7) + 1;
              final points = _getPointsForDay(normalizedDay);
              final displayDay = day <= 7 ? day : '$day日目($normalizedDay日目相当)';
              return ElevatedButton(
                onPressed: _isSettingStreakDays
                    ? null
                    : () {
                        _streakDaysController.text = day.toString();
                        _setStreakDays();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: normalizedDay == 4 || normalizedDay == 7
                      ? Colors.orange.shade600
                      : Colors.purple.shade300,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('$displayDay (${points}pt)'),
              );
            }),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isResettingLoginBonus ? null : _resetLoginBonus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isResettingLoginBonus
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'ログインボーナスをリセット',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 日数に応じたポイントを取得
  int _getPointsForDay(int day) {
    if (day >= 1 && day <= 7) {
      return LOGIN_BONUS.dailyPt[day - 1];
    }
    return LOGIN_BONUS.dailyPt[0];
  }

  Widget _buildHistoryResetSection() {
    final historyStatsAsync = ref.watch(quizStatisticsProvider);
    
    return GlassMorphismWidget(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.history,
                color: Colors.blue.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'クイズ履歴リセット',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          historyStatsAsync.when(
            data: (stats) => Text(
              '現在のプレイ回数: ${stats.totalPlays}回',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            loading: () => Text(
              '読み込み中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            error: (_, __) => Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isResettingHistory ? null : _resetHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isResettingHistory
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'クイズ履歴をリセット',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchDayResetSection() {
    return GlassMorphismWidget(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sports_soccer,
                color: Colors.green.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'MATCH DAYプレイ回数リセット',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '今週のMATCH DAYプレイ回数と出題済み問題履歴をリセットします。',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isResettingMatchDay ? null : _resetMatchDay,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isResettingMatchDay
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'MATCH DAYプレイ回数をリセット',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetMatchDay() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MATCH DAYプレイ回数をリセット'),
        content: const Text(
          '今週のMATCH DAYプレイ回数と出題済み問題履歴をリセットします。この操作は元に戻せません。\n\n本当に実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
            ),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isResettingMatchDay = true;
    });

    try {
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.resetMatchDayPlayHistory();
      await databaseService.resetWeeklyRecapQuestionHistory();
      if (mounted) {
        _showSuccessSnackBar('MATCH DAYプレイ回数をリセットしました');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('リセットに失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingMatchDay = false;
        });
      }
    }
  }

  Widget _buildFullDataResetSection() {
    final currentExp = ref.watch(totalExpProvider);
    final currentPoints = ref.watch(totalPointsProvider);
    final currentRank = ref.watch(userRankProvider);
    
    return GlassMorphismWidget(
      borderRadius: 16,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '全ユーザーデータリセット',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '現在の状態:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'EXP: ${NumberFormat('#,###').format(currentExp)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            'ポイント: ${NumberFormat('#,###').format(currentPoints)}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            'ランク: ${currentRank.japaneseName}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isResettingAllData ? null : _resetAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isResettingAllData
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '全データをリセット',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setStreakDays() async {
    final streakDaysText = _streakDaysController.text.trim();
    if (streakDaysText.isEmpty) {
      _showErrorSnackBar('連続日数を入力してください');
      return;
    }

    final streakDays = int.tryParse(streakDaysText);
    if (streakDays == null || streakDays < 1) {
      _showErrorSnackBar('連続日数は1日以上で設定してください');
      return;
    }

    // 8日目以降は1日目に戻る（7日周期）
    final normalizedDay = ((streakDays - 1) % 7) + 1;
    final points = _getPointsForDay(normalizedDay);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('連続日数を設定'),
        content: Text(
          streakDays <= 7
              ? '連続日数を${streakDays}日に設定します。\n次回ログインボーナス受け取り時に${points}ポイント獲得できます。\n\n本当に設定しますか？'
              : '連続日数を${streakDays}日（${normalizedDay}日目相当）に設定します。\n次回ログインボーナス受け取り時に${points}ポイント獲得できます。\n\n本当に設定しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
            ),
            child: const Text('設定する'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSettingStreakDays = true;
    });

    try {
      await ref.read(loginBonusStatusProvider.notifier).setStreakDays(streakDays);
      if (mounted) {
        _showSuccessSnackBar('連続日数を${streakDays}日に設定しました（次回受け取り時: ${points}ポイント）');
        _streakDaysController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('設定に失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSettingStreakDays = false;
        });
      }
    }
  }

  Future<void> _resetLoginBonus() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログインボーナスをリセット'),
        content: const Text(
          'ログインボーナスの連続日数と最後に受け取った日付をリセットします。この操作は元に戻せません。\n\n本当に実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade700,
            ),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isResettingLoginBonus = true;
    });

    try {
      await ref.read(loginBonusStatusProvider.notifier).resetLoginBonus();
      if (mounted) {
        _showSuccessSnackBar('ログインボーナスをリセットしました');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('リセットに失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingLoginBonus = false;
        });
      }
    }
  }

  Future<void> _resetHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('クイズ履歴をリセット'),
        content: const Text(
          'すべてのクイズ履歴と統計情報を削除します。この操作は元に戻せません。\n\n本当に実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
            ),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isResettingHistory = true;
    });

    try {
      final historyService = ref.read(quizHistoryServiceProvider);
      await historyService.deleteAllHistory();
      // プロバイダーを無効化して再読み込み
      ref.invalidate(quizHistoryListProvider);
      ref.invalidate(quizStatisticsProvider);
      if (mounted) {
        _showSuccessSnackBar('クイズ履歴をリセットしました');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('リセットに失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingHistory = false;
        });
      }
    }
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('全ユーザーデータをリセット'),
        content: const Text(
          'EXP、ポイント、ランクをすべて0にリセットします。この操作は元に戻せません。\n\n本当に実行しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text('リセットする'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isResettingAllData = true;
    });

    try {
      // EXPとポイントを0に設定
      await ref.read(totalExpProvider.notifier).setExp(0);
      await ref.read(totalPointsProvider.notifier).setPoints(0);
      if (mounted) {
        setState(() {
          _selectedRank = UserRank.fromExp(0);
          _expController.text = '0';
          _pointsController.text = '0';
        });
        _showSuccessSnackBar('全ユーザーデータをリセットしました');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('リセットに失敗しました: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingAllData = false;
        });
      }
    }
  }
}
