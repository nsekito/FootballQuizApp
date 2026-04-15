import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 効果音のオン/オフ（true = 再生する）。
final soundEffectsEnabledProvider =
    StateNotifierProvider<SoundEffectsEnabledNotifier, bool>((ref) {
  return SoundEffectsEnabledNotifier();
});

class SoundEffectsEnabledNotifier extends StateNotifier<bool> {
  SoundEffectsEnabledNotifier() : super(true) {
    _load();
  }

  static const _prefsKey = 'sound_effects_enabled';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_prefsKey) ?? true;
    } catch (_) {
      state = true;
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, enabled);
    } catch (_) {
      // 永続化のみ失敗した場合でも UI は更新する
    }
    state = enabled;
  }

  Future<void> toggle() => setEnabled(!state);
}
