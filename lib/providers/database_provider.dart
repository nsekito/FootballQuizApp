import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

/// データベースサービスのプロバイダー
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});
