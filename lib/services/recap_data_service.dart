import 'package:flutter/foundation.dart' show debugPrint;
import '../constants/app_constants.dart';
import '../utils/app_date_utils.dart';
import 'database_service.dart';
import 'remote_data_service.dart';

/// Weekly RecapデータのDB取り込みを管理するサービス
class RecapDataService {
  final DatabaseService _databaseService;
  final RemoteDataService _remoteDataService;

  RecapDataService({
    required DatabaseService databaseService,
    required RemoteDataService remoteDataService,
  })  : _databaseService = databaseService,
        _remoteDataService = remoteDataService;

  /// Weekly Recapデータをリモートから取得してDBに同期
  /// 
  /// [date] 日付（YYYY-MM-DD形式、指定しない場合は最新の週、404時は過去週を試行）
  /// [force] trueの場合、既に同期済みでも再同期する
  /// 戻り値: 同期した問題数の合計
  Future<int> syncWeeklyRecapToDatabase({
    String? date,
    bool force = false,
  }) async {
    const maxWeeksToTry = 4;
    var tryDate = date ?? _getLatestMonday();
    int totalSynced = 0;

    try {
      for (var i = 0; i < maxWeeksToTry; i++) {
        // すべてのリーグタイプのデータを取得
        final allQuestions = await _remoteDataService.fetchAllWeeklyRecapQuestions(
          date: tryDate,
        );

        final hasData = allQuestions.values.any((list) => list.isNotEmpty);
        if (!hasData) {
          tryDate = AppDateUtils.getPreviousMondayString(tryDate);
          continue;
        }

        // 各リーグタイプごとに処理
        for (final entry in allQuestions.entries) {
          final leagueType = entry.key;
          final questions = entry.value;

          // 既に同期済みかチェック
          if (!force) {
            final isSynced = await _databaseService.isRecapSynced(
              date: tryDate,
              leagueType: leagueType,
            );
            if (isSynced) {
              debugPrint('Weekly Recap ($tryDate, $leagueType) は既に同期済みです');
              continue;
            }
          }

          // 問題が空の場合はスキップ
          if (questions.isEmpty) {
            debugPrint('Weekly Recap ($tryDate, $leagueType) に問題がありません');
            continue;
          }

          // DBに保存
          await _databaseService.insertQuestions(questions);
          totalSynced += questions.length;

          // 同期履歴を記録
          await _databaseService.recordRecapSync(
            date: tryDate,
            leagueType: leagueType,
            questionCount: questions.length,
          );

          debugPrint(
            'Weekly Recap ($tryDate, $leagueType): ${questions.length}問をDBに同期しました',
          );
        }

        return totalSynced;
      }

      return totalSynced;
    } catch (e) {
      debugPrint('Weekly Recap同期エラー: $e');
      rethrow;
    }
  }

  /// 指定日付のWeekly Recapが既に同期済みかチェック
  Future<bool> isWeeklyRecapSynced({
    required String date,
    String? leagueType,
  }) async {
    if (leagueType != null) {
      return await _databaseService.isRecapSynced(
        date: date,
        leagueType: leagueType,
      );
    } else {
      // 両方のリーグタイプが同期済みかチェック
      final j1Synced = await _databaseService.isRecapSynced(
        date: date,
        leagueType: AppConstants.leagueTypeJ1,
      );
      final europeSynced = await _databaseService.isRecapSynced(
        date: date,
        leagueType: AppConstants.leagueTypeEurope,
      );
      return j1Synced && europeSynced;
    }
  }

  /// 同期済みの日付リストを取得
  Future<List<String>> getSyncedDates() async {
    final syncedRecords = await _databaseService.getSyncedRecapDates();
    final dates = <String>{};
    for (final record in syncedRecords) {
      dates.add(record['date'] as String);
    }
    return dates.toList()..sort((a, b) => b.compareTo(a)); // 新しい順
  }

  String _getLatestMonday() => AppDateUtils.getLatestMondayString();
}
