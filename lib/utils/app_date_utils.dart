/// アプリ全体で使用する日付計算のユーティリティ。
///
/// 週初め（月曜日）基準のカレンダーロジックと
/// 日付フォーマットを一元管理する。
class AppDateUtils {
  AppDateUtils._();

  /// 指定日の週初め（月曜日）の DateTime を返す。
  static DateTime getWeekStartDate(DateTime date) {
    final weekday = date.weekday;
    final daysFromMonday = weekday == 7 ? 0 : weekday - 1;
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: daysFromMonday));
  }

  /// 指定日の週末（日曜日）の DateTime を返す。
  static DateTime getWeekEndDate(DateTime date) {
    final weekStart = getWeekStartDate(date);
    return weekStart.add(const Duration(days: 6));
  }

  /// 指定日の翌週月曜日の DateTime を返す。
  static DateTime getNextWeekStartDate(DateTime date) {
    final weekStart = getWeekStartDate(date);
    return weekStart.add(const Duration(days: 7));
  }

  /// 直近の月曜日を YYYY-MM-DD 形式の文字列で返す。
  static String getLatestMondayString({DateTime? now}) {
    final date = now ?? DateTime.now();
    final monday = getWeekStartDate(date);
    return formatDateYmd(monday);
  }

  /// 今日の日付を YYYY-MM-DD 形式の文字列で返す。
  static String getCurrentDateString({DateTime? now}) {
    final date = now ?? DateTime.now();
    return formatDateYmd(date);
  }

  /// DateTime を YYYY-MM-DD 形式にフォーマット。
  static String formatDateYmd(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// DateTime を日本語表記（例: "2月10日（月）"）にフォーマット。
  static String formatDateJapanese(DateTime date) {
    const weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    return '${date.month}月${date.day}日（${weekdays[date.weekday - 1]}）';
  }
}
