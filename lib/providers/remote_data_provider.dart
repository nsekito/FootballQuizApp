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
