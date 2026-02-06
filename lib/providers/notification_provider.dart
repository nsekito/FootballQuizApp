import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

/// 通知サービスのプロバイダー
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// 通知権限の状態プロバイダー
final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(notificationServiceProvider);
  return await service.isPermissionGranted();
});
