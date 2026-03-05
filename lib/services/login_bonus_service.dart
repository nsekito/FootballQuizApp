import 'package:shared_preferences/shared_preferences.dart';
import '../constants/game_config.dart';

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
  /// 8日目以降は1日目に戻る（7日周期）
  int getLoginBonusPoints(int streakDay) {
    // 8日目以降は1日目に戻る（7日周期）
    final normalizedDay = ((streakDay - 1) % 7) + 1;
    if (normalizedDay >= 1 && normalizedDay <= LOGIN_BONUS.dailyPt.length) {
      return LOGIN_BONUS.dailyPt[normalizedDay - 1];
    }
    // フォールバック
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
    final currentStreak = await getCurrentStreakDays();
    
    int newStreak;
    
    // 管理者が設定した連続日数がある場合（昨日の日付が設定されている場合）
    // その日数をそのまま使用（+1しない）
    if (lastDate != null && currentStreak > 0) {
      final last = DateTime.parse(lastDate);
      final current = DateTime.parse(currentDate);
      final difference = current.difference(last).inDays;
      
      if (difference == 1) {
        // 昨日から今日になった場合、設定された日数をそのまま使用
        newStreak = currentStreak;
      } else {
        // 通常の連続日数計算
        newStreak = await calculateStreakAsync(lastDate, currentDate);
      }
    } else {
      // 通常の連続日数計算
      newStreak = await calculateStreakAsync(lastDate, currentDate);
    }
    
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
    final currentStreak = await getCurrentStreakDays();
    
    int streak;
    if (canClaim) {
      // 受け取り可能な場合
      if (lastDate != null && currentStreak > 0) {
        // 管理者が設定した連続日数がある場合（昨日の日付が設定されている場合）
        // その日数をそのまま使用（+1しない）
        final last = DateTime.parse(lastDate);
        final current = DateTime.parse(currentDate);
        final difference = current.difference(last).inDays;
        
        if (difference == 1) {
          // 昨日から今日になった場合、設定された日数をそのまま使用
          streak = currentStreak;
        } else {
          // 通常の連続日数計算
          streak = await calculateStreakAsync(lastDate, currentDate);
        }
      } else {
        // 通常の連続日数計算
        streak = await calculateStreakAsync(lastDate, currentDate);
      }
    } else {
      // 受け取り済みの場合は、現在の連続日数を取得
      streak = currentStreak;
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

  /// ログインボーナスをリセットする（管理者用）
  /// 
  /// 最後に受け取った日付と連続日数を削除し、初期状態に戻します。
  Future<void> resetLoginBonus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastLoginBonusDate);
    await prefs.remove(_keyLoginStreakDays);
  }

  /// 連続日数を設定する（管理者用）
  /// 
  /// 指定した連続日数を設定します。日付は現在の日付から1日前に設定されます。
  /// これにより、次回ログイン時に指定した日数として受け取れます。
  /// 8日目以降は1日目に戻ります（8日目→1日目、9日目→2日目...）。
  Future<void> setStreakDays(int streakDays) async {
    if (streakDays < 1) {
      throw Exception('連続日数は1日以上で設定してください');
    }
    
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayString = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
    
    // 8日目以降は1日目に戻る（7日周期）
    final normalizedStreak = ((streakDays - 1) % 7) + 1;
    
    // 昨日の日付を設定（これにより今日受け取れるようになる）
    await prefs.setString(_keyLastLoginBonusDate, yesterdayString);
    // 連続日数を設定（正規化後の日数、次回受け取る際の日数として使用）
    await prefs.setInt(_keyLoginStreakDays, normalizedStreak);
  }
}
