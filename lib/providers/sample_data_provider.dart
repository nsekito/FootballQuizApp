import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sample_data_service.dart';
import 'database_provider.dart';

/// サンプルデータの初期化状態を管理
final sampleDataInitializedProvider = FutureProvider<bool>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  
  // データベースにデータがあるか確認
  final questions = await databaseService.getQuestions(limit: 1);
  
  if (questions.isEmpty) {
    // サンプルデータを追加
    await SampleDataService.addSampleData(databaseService);
    return true;
  }
  
  return true;
});
