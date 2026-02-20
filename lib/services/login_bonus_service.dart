import 'package:shared_preferences/shared_preferences.dart';

/// ログインボーナスサービス
/// 
/// 日付管理とポイント計算ロジックを実装します。
class LoginBonusService {
  static const String _keyLastLoginBonusDate = 'last_login_bonus_date';
  static const String _keyLoginStreakDays = 'login_streak_days';

  /// 現在の日付をYYYY-MM-DD形式で取得
  String getCurrentDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 今日ログインボーナスを受け取れるかチェック
  Future<bool> canClaimLoginBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastLoginBonusDate);
    final currentDate = getCurrentDateString();
    
    // まだ受け取ったことがない場合は受け取れる
    if (lastDate == null) {
      return true;
    }
    
    // 同じ日なら受け取れない
    if (lastDate == currentDate) {
      return false;
    }
    
    // 日付が変わったら受け取れる
    return true;
  }

  /// 現在の連続日数を取得
  Future<int> getCurrentStreakDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLoginStreakDays) ?? 0;
  }

  /// 最後に受け取った日付を取得
  Future<String?> getLastLoginBonusDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastLoginBonusDate);
  }

  /// 連続日数を計算（非同期版）
  Future<int> calculateStreakAsync(String? lastDate, String currentDate) async {
    if (lastDate == null) {
      // 初回は1日目
      return 1;
    }
    
    final last = DateTime.parse(lastDate);
    final current = DateTime.parse(currentDate);
    final difference = current.difference(last).inDays;
    
    if (difference == 1) {
      // 連続している
      final currentStreak = await getCurrentStreakDays();
      // 8日目で1に戻る（7日周期）
      // currentStreakが7の場合、次は8日目になるが、それを1に戻す
      if (currentStreak >= 7) {
        return 1; // 8日目で1に戻る
      }
      return currentStreak + 1;
    } else if (difference == 0) {
      // 同じ日
      final currentStreak = await getCurrentStreakDays();
      return currentStreak;
    } else {
      // 連続が途切れた
      return 1; // 1日目にリセット
    }
  }

  /// 連続日数に応じたポイントを取得
  int getLoginBonusPoints(int streakDay) {
    switch (streakDay) {
      case 1:
      case 2:
      case 3:
        return 1;
      case 4:
        return 4;
      case 5:
      case 6:
        return 1;
      case 7:
        return 10;
      default:
        return 1; // フォールバック
    }
  }

  /// ログインボーナスを受け取る
  /// 
  /// 日付と連続日数を更新し、受け取ったポイントを返します。
  Future<int> claimLoginBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastLoginBonusDate);
    final currentDate = getCurrentDateString();
    
    // 連続日数を計算
    final newStreak = await calculateStreakAsync(lastDate, currentDate);
    
    // 日付と連続日数を保存
    await prefs.setString(_keyLastLoginBonusDate, currentDate);
    await prefs.setInt(_keyLoginStreakDays, newStreak);
    
    // ポイントを計算して返す
    return getLoginBonusPoints(newStreak);
  }

  /// ログインボーナスの状態を取得
  Future<Map<String, dynamic>> getLoginBonusStatus() async {
    final canClaim = await canClaimLoginBonus();
    final lastDate = await getLastLoginBonusDate();
    final currentDate = getCurrentDateString();
    
    int streak;
    if (canClaim) {
      // 受け取り可能な場合は、新しい連続日数を計算
      streak = await calculateStreakAsync(lastDate, currentDate);
    } else {
      // 受け取り済みの場合は、現在の連続日数を取得
      streak = await getCurrentStreakDays();
      if (streak == 0) {
        // まだ受け取ったことがない場合は1日目
        streak = 1;
      }
    }
    
    final points = getLoginBonusPoints(streak);
    
    return {
      'canClaim': canClaim,
      'streakDays': streak,
      'points': points,
      'lastDate': lastDate,
      'currentDate': currentDate,
    };
  }
}
