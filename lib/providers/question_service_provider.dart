import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/question_service.dart';
import 'database_provider.dart';
import 'remote_data_provider.dart';

/// QuestionServiceのプロバイダー
final questionServiceProvider = Provider<QuestionService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final remoteDataService = ref.watch(remoteDataServiceProvider);
  return QuestionService(
    databaseService: databaseService,
    remoteDataService: remoteDataService,
  );
});
