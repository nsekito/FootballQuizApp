import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quiz_history_service.dart';
import '../services/database_service.dart';
import '../models/quiz_history.dart';
import 'database_provider.dart';

/// クイズ履歴サービスのプロバイダー
final quizHistoryServiceProvider = Provider<QuizHistoryService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return QuizHistoryService(databaseService);
});

/// クイズ履歴一覧のプロバイダー（キャッシュ付き）
final quizHistoryListProvider = FutureProvider<List<QuizHistory>>((ref) async {
  final historyService = ref.watch(quizHistoryServiceProvider);
  return await historyService.getAllHistory();
});

/// クイズ統計情報のプロバイダー（キャッシュ付き）
final quizStatisticsProvider = FutureProvider<QuizStatistics>((ref) async {
  final historyService = ref.watch(quizHistoryServiceProvider);
  return await historyService.getStatistics();
});
