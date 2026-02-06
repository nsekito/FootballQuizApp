import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/user_rank.dart';
import 'database_provider.dart';

/// ユーザーの累計経験値（exp）を管理するプロバイダー
final totalExpProvider = StateNotifierProvider<TotalExpNotifier, int>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return TotalExpNotifier(databaseService);
});

class TotalExpNotifier extends StateNotifier<int> {
  final DatabaseService _databaseService;

  TotalExpNotifier(this._databaseService) : super(0) {
    _loadExp();
  }

  Future<void> _loadExp() async {
    final exp = await _databaseService.getTotalExp();
    state = exp;
  }

  Future<void> addExp(int exp) async {
    await _databaseService.addExp(exp);
    await _loadExp();
  }

  Future<void> refresh() async {
    await _loadExp();
  }
}

/// ユーザーの累計ポイントを管理するプロバイダー
final totalPointsProvider = StateNotifierProvider<TotalPointsNotifier, int>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return TotalPointsNotifier(databaseService);
});

class TotalPointsNotifier extends StateNotifier<int> {
  final DatabaseService _databaseService;

  TotalPointsNotifier(this._databaseService) : super(0) {
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final points = await _databaseService.getTotalPoints();
    state = points;
  }

  Future<void> addPoints(int points) async {
    await _databaseService.addPoints(points);
    await _loadPoints();
  }

  Future<void> consumePoints(int points) async {
    final currentPoints = state;
    if (currentPoints >= points) {
      await _databaseService.updateTotalPoints(currentPoints - points);
      await _loadPoints();
    } else {
      throw Exception('ポイントが不足しています');
    }
  }

  Future<void> refresh() async {
    await _loadPoints();
  }
}

/// ユーザーのランクを取得するプロバイダー（expベース）
final userRankProvider = Provider<UserRank>((ref) {
  final totalExp = ref.watch(totalExpProvider);
  return UserRank.fromExp(totalExp);
});

/// アンロック済み難易度を管理するプロバイダー
final unlockedDifficultiesProvider = StateNotifierProvider<UnlockedDifficultiesNotifier, List<String>>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return UnlockedDifficultiesNotifier(databaseService);
});

class UnlockedDifficultiesNotifier extends StateNotifier<List<String>> {
  final DatabaseService _databaseService;

  UnlockedDifficultiesNotifier(this._databaseService) : super([]) {
    _loadUnlockedDifficulties();
  }

  Future<void> _loadUnlockedDifficulties() async {
    final unlocked = await _databaseService.getUnlockedDifficulties();
    state = unlocked;
  }

  Future<void> unlockDifficulty(String unlockKey) async {
    await _databaseService.unlockDifficulty(unlockKey);
    await _loadUnlockedDifficulties();
  }

  Future<bool> isUnlocked(String unlockKey) async {
    return await _databaseService.isDifficultyUnlocked(unlockKey);
  }

  Future<void> refresh() async {
    await _loadUnlockedDifficulties();
  }
}
