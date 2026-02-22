import 'package:shared_preferences/shared_preferences.dart';
import '../constants/gameConfig.dart';

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

  /// 連続日数に応じたポイントを取得（LOGIN_BONUS.DAILY_PTを参照）
  int getLoginBonusPoints(int streakDay) {
    if (streakDay >= 1 && streakDay <= LOGIN_BONUS.dailyPt.length) {
      return LOGIN_BONUS.dailyPt[streakDay - 1];
    }
    // 7日を超える場合は1日目に戻る
    return LOGIN_BONUS.dailyPt[0];
  }

  /// ログインボーナスを受け取る
  /// 
  /// 日付と連続日数を更新し、受け取ったポイントを返します。
  /// 7日連続の場合はEXPも返します（戻り値はポイントのみ、EXPは別途処理）。
  Future<Map<String, dynamic>> claimLoginBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_keyLastLoginBonusDate);
    final currentDate = getCurrentDateString();
    
    // 連続日数を計算
    final newStreak = await calculateStreakAsync(lastDate, currentDate);
    
    // 日付と連続日数を保存
    await prefs.setString(_keyLastLoginBonusDate, currentDate);
    await prefs.setInt(_keyLoginStreakDays, newStreak);
    
    // ポイントを計算
    final points = getLoginBonusPoints(newStreak);
    
    // 7日連続の場合はEXPも付与
    int exp = 0;
    if (newStreak == 7) {
      exp = LOGIN_BONUS.consecutive7DayBonusExp;
    }
    
    return {
      'points': points,
      'exp': exp,
      'streak': newStreak,
    };
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
    
    // 7日連続の場合はEXPも返す
    int exp = 0;
    if (streak == 7 && canClaim) {
      exp = LOGIN_BONUS.consecutive7DayBonusExp;
    }
    
    return {
      'canClaim': canClaim,
      'streakDays': streak,
      'points': points,
      'exp': exp,
      'lastDate': lastDate,
      'currentDate': currentDate,
    };
  }
}
