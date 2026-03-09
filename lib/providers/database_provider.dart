import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/daily_quiz_service.dart';

/// データベースサービスのプロバイダー
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

/// Daily Quizサービスのプロバイダー
final dailyQuizServiceProvider = Provider<DailyQuizService>((ref) {
  return DailyQuizService(databaseService: ref.watch(databaseServiceProvider));
});
