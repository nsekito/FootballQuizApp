import 'package:shared_preferences/shared_preferences.dart';
import '../constants/game_config.dart';
import '../utils/app_date_utils.dart';

/// クイズ履歴解放サービス
/// 無料解放の残り回数管理と日次リセット処理
class HistoryUnlockService {
  static const String _keyFreeUnlockCount = 'history_free_unlock_count';
  static const String _keyLastResetDate = 'history_free_unlock_last_reset_date';

  String _getCurrentDateString() => AppDateUtils.getCurrentDateString();

  /// 日次リセットをチェックして実行
  Future<void> _checkAndResetDaily() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResetDate = prefs.getString(_keyLastResetDate);
    final currentDate = _getCurrentDateString();

    // 日付が変わった場合はリセット
    if (lastResetDate != currentDate) {
      await prefs.setInt(_keyFreeUnlockCount, AD_BONUS.historyFreeUnlockDailyLimit);
      await prefs.setString(_keyLastResetDate, currentDate);
    }
  }

  /// 無料解放の残り回数を取得
  Future<int> getRemainingFreeUnlocks() async {
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyFreeUnlockCount) ?? AD_BONUS.historyFreeUnlockDailyLimit;
  }

  /// 無料解放を使用
  Future<bool> useFreeUnlock() async {
    await _checkAndResetDaily();
    final prefs = await SharedPreferences.getInstance();
    final remaining = prefs.getInt(_keyFreeUnlockCount) ?? AD_BONUS.historyFreeUnlockDailyLimit;

    if (remaining <= 0) {
      return false;
    }

    await prefs.setInt(_keyFreeUnlockCount, remaining - 1);
    return true;
  }

  /// 10問セット解放のコストを取得
  int getBundle10Cost() {
    return HISTORY_UNLOCK.bundle10Cost;
  }

  /// 1問解放のコストを取得
  int getSingleQuestionCost() {
    return HISTORY_UNLOCK.singleQuestionCost;
  }
}
