import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 管理者権限があるかどうかを判定するプロバイダー
/// 現在はデバッグビルドの場合のみ管理者権限があると判定
final isAdminProvider = Provider<bool>((ref) {
  // デバッグビルドの場合のみ管理者権限がある
  // 将来的には、特定のユーザーIDや設定で判定するように変更可能
  return kDebugMode;
});

/// 管理者モードの状態を管理するプロバイダー
final adminModeProvider = StateNotifierProvider<AdminModeNotifier, bool>((ref) {
  return AdminModeNotifier();
});

class AdminModeNotifier extends StateNotifier<bool> {
  AdminModeNotifier() : super(false) {
    _loadAdminMode();
  }

  /// SharedPreferencesから管理者モードの状態を読み込む
  Future<void> _loadAdminMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool('admin_mode') ?? false;
    } catch (e) {
      // エラーが発生した場合はデフォルト値（false）を使用
      state = false;
    }
  }

  /// 管理者モードを設定する
  Future<void> setAdminMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('admin_mode', enabled);
      state = enabled;
    } catch (e) {
      // エラーが発生した場合は状態を更新しない
    }
  }
}
