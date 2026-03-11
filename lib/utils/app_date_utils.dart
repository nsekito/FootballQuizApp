/// アプリ全体で使用する日付計算のユーティリティ。
///
/// 週初め（月曜日）基準のカレンダーロジックと
/// 日付フォーマットを一元管理する。
///
/// 日付・週のリセット境界は日本時間（JST）7:00 とする。
/// - MATCH DAY: 月曜 7:00 JST で週がリセット
/// - Daily Quiz: 毎日 7:00 JST で日がリセット
class AppDateUtils {
  AppDateUtils._();

  /// 指定日時を日本時間（UTC+9）に変換する。
  static DateTime _toJst(DateTime dateTime) {
    final utc = dateTime.toUtc();
    return utc.add(const Duration(hours: 9));
  }

  /// 指定日の週初め（月曜日）の DateTime を返す。
  static DateTime getWeekStartDate(DateTime date) {
    final weekday = date.weekday;
    final daysFromMonday = weekday == 7 ? 6 : weekday - 1;
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
  /// 週の境界は月曜 7:00 JST。7:00 前は前週として扱う。
  static String getLatestMondayString({DateTime? now}) {
    var jst = _toJst(now ?? DateTime.now());
    if (jst.hour < 7) {
      jst = jst.subtract(const Duration(days: 1));
    }
    final monday = getWeekStartDate(jst);
    return formatDateYmd(monday);
  }

  /// 指定日付の1週間前の月曜日を YYYY-MM-DD 形式で返す。
  /// [dateStr] YYYY-MM-DD 形式の文字列
  static String getPreviousMondayString(String dateStr) {
    final parts = dateStr.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final previousMonday = date.subtract(const Duration(days: 7));
    return formatDateYmd(previousMonday);
  }

  /// 今日の日付を YYYY-MM-DD 形式の文字列で返す。
  /// 日の境界は 7:00 JST。7:00 前は前日として扱う。
  static String getCurrentDateString({DateTime? now}) {
    var jst = _toJst(now ?? DateTime.now());
    if (jst.hour < 7) {
      jst = jst.subtract(const Duration(days: 1));
    }
    return formatDateYmd(jst);
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
