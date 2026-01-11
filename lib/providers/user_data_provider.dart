import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../models/user_rank.dart';
import 'database_provider.dart';

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

  Future<void> refresh() async {
    await _loadPoints();
  }
}

/// ユーザーのランクを取得するプロバイダー
final userRankProvider = Provider<UserRank>((ref) {
  final totalPoints = ref.watch(totalPointsProvider);
  return UserRank.fromPoints(totalPoints);
});
