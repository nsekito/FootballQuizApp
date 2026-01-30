import 'package:flutter/foundation.dart' show debugPrint;
import '../utils/constants.dart';
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
  /// [date] 日付（YYYY-MM-DD形式、指定しない場合は最新の週）
  /// [force] trueの場合、既に同期済みでも再同期する
  /// 戻り値: 同期した問題数の合計
  Future<int> syncWeeklyRecapToDatabase({
    String? date,
    bool force = false,
  }) async {
    final targetDate = date ?? _getLatestMonday();
    int totalSynced = 0;

    try {
      // すべてのリーグタイプのデータを取得
      final allQuestions = await _remoteDataService.fetchAllWeeklyRecapQuestions(
        date: targetDate,
      );

      // 各リーグタイプごとに処理
      for (final entry in allQuestions.entries) {
        final leagueType = entry.key;
        final questions = entry.value;

        // 既に同期済みかチェック
        if (!force) {
          final isSynced = await _databaseService.isRecapSynced(
            date: targetDate,
            leagueType: leagueType,
          );
          if (isSynced) {
            debugPrint('Weekly Recap ($targetDate, $leagueType) は既に同期済みです');
            continue;
          }
        }

        // 問題が空の場合はスキップ
        if (questions.isEmpty) {
          debugPrint('Weekly Recap ($targetDate, $leagueType) に問題がありません');
          continue;
        }

        // DBに保存
        await _databaseService.insertQuestions(questions);
        totalSynced += questions.length;

        // 同期履歴を記録
        await _databaseService.recordRecapSync(
          date: targetDate,
          leagueType: leagueType,
          questionCount: questions.length,
        );

        debugPrint(
          'Weekly Recap ($targetDate, $leagueType): ${questions.length}問をDBに同期しました',
        );
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

  /// 最新の月曜日の日付を取得（YYYY-MM-DD形式）
  String _getLatestMonday() {
    final now = DateTime.now();
    // 月曜日を取得（月曜日 = 1）
    int daysFromMonday = (now.weekday - 1) % 7;
    final monday = now.subtract(Duration(days: daysFromMonday));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }
}
