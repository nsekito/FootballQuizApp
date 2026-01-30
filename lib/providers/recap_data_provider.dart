import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recap_data_service.dart';
import 'database_provider.dart';
import 'remote_data_provider.dart';

/// RecapDataServiceのプロバイダー
final recapDataServiceProvider = Provider<RecapDataService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final remoteDataService = ref.watch(remoteDataServiceProvider);
  return RecapDataService(
    databaseService: databaseService,
    remoteDataService: remoteDataService,
  );
});
