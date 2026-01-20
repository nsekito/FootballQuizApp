import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../services/remote_data_service.dart';

/// リモートデータサービスのプロバイダー
final remoteDataServiceProvider = Provider<RemoteDataService>((ref) {
  return RemoteDataService();
});

/// Weekly Recap問題のプロバイダー
/// 
/// 使用例:
/// ```dart
/// final weeklyRecapQuestions = ref.watch(weeklyRecapProvider);
/// weeklyRecapQuestions.when(
///   data: (questions) => ...,
///   loading: () => ...,
///   error: (error, stack) => ...,
/// );
/// ```
final weeklyRecapProvider = FutureProvider<List<Question>>((ref) async {
  final service = ref.watch(remoteDataServiceProvider);
  return await service.fetchWeeklyRecapQuestions();
});

/// ニュースクイズ問題のプロバイダー
/// 
/// パラメータ:
/// - year: 年（例: "2025"）
/// - region: 地域（"domestic" または "world"、オプション）
/// - difficulty: 難易度（オプション）
final newsQuestionsProvider = FutureProvider.family<List<Question>, NewsQueryParams>((ref, params) async {
  final service = ref.watch(remoteDataServiceProvider);
  return await service.fetchNewsQuestions(
    year: params.year,
    region: params.region,
    difficulty: params.difficulty,
  );
});

/// ニュースクイズのクエリパラメータ
class NewsQueryParams {
  final String year;
  final String? region;
  final String? difficulty;

  NewsQueryParams({
    required this.year,
    this.region,
    this.difficulty,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewsQueryParams &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          region == other.region &&
          difficulty == other.difficulty;

  @override
  int get hashCode => year.hashCode ^ region.hashCode ^ difficulty.hashCode;
}
