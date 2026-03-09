import '../constants/game_config.dart';
import 'database_service.dart';

/// Daily Quizのプレイ回数管理サービス
/// 1日2回まで、2回目は広告視聴後にプレイ可能
class DailyQuizService {
  final DatabaseService _databaseService;

  DailyQuizService({required DatabaseService databaseService})
      : _databaseService = databaseService;

  /// 今日のプレイ回数を取得
  Future<int> getDailyQuizPlayCount() async {
    return _databaseService.getDailyQuizPlayCount();
  }

  /// プレイ可能かどうか、および広告が必要かどうかを返す
  /// 戻り値: (canPlay, needsAd)
  /// - canPlay: プレイ可能か（1回目または2回目で広告視聴済み）
  /// - needsAd: 2回目のプレイのため広告視聴が必要か
  Future<(bool canPlay, bool needsAd)> canPlayDailyQuiz() async {
    final playCount = await getDailyQuizPlayCount();

    if (playCount == 0) {
      return (true, false); // 1回目: 無料でプレイ可能
    }
    if (playCount == 1) {
      return (true, true); // 2回目: 広告視聴後にプレイ可能
    }
    return (false, false); // 2回済み: プレイ不可
  }

  /// 残りプレイ回数を取得
  Future<int> getRemainingPlays() async {
    final playCount = await getDailyQuizPlayCount();
    return (dailyQuiz.maxPlaysPerDay - playCount).clamp(0, dailyQuiz.maxPlaysPerDay);
  }

  /// Daily Quizのプレイを記録
  Future<void> recordDailyQuizPlay() async {
    await _databaseService.recordDailyQuizPlay();
  }
}
