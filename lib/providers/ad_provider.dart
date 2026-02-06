import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ad_service.dart';

/// 広告サービスのプロバイダー
final adServiceProvider = Provider<AdService>((ref) {
  return AdService();
});

/// リワード広告の読み込み状態を管理するプロバイダー
final rewardedAdReadyProvider = StateProvider<bool>((ref) {
  return false;
});

/// リワード広告のエラーメッセージを管理するプロバイダー
final rewardedAdErrorProvider = StateProvider<String?>((ref) {
  return null;
});
