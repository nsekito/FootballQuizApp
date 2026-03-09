import '../models/question.dart';
import '../constants/app_constants.dart';
import 'database_service.dart';
import 'remote_data_service.dart';

/// 問題取得を統合するサービス
/// 
/// カテゴリに応じて適切なデータソースから問題を取得します。
/// - match_recap → リモートデータサービス
/// - rules, history, teams → ローカルデータベースサービス
class QuestionService {
  final DatabaseService _databaseService;
  final RemoteDataService _remoteDataService;

  QuestionService({
    required DatabaseService databaseService,
    required RemoteDataService remoteDataService,
  })  : _databaseService = databaseService,
        _remoteDataService = remoteDataService;

  /// 問題を取得（カテゴリに応じて適切なデータソースから）
  /// 
  /// [category] カテゴリ（rules, history, teams, match_recap）
  /// [difficulty] 難易度（easy, normal, hard, extreme）。Weekly Recapの場合は空文字列でも可
  /// [tags] タグ（カンマ区切り、オプション）
  /// [country] 国（オプション）
  /// [region] 地域（オプション）
  /// [team] チーム（オプション）
  /// [limit] 取得する問題数（デフォルト: 10）
  /// [excludeIds] 除外する問題IDのリスト（オプション）
  /// [date] 日付（Weekly Recap用、YYYY-MM-DD形式、オプション）
  /// [leagueType] リーグタイプ（Weekly Recap用、"j1" または "europe"、オプション）
  Future<List<Question>> getQuestions({
    required String category,
    required String difficulty,
    String? tags,
    String? country,
    String? region,
    String? team,
    int? limit,
    List<String>? excludeIds,
    String? date,
    String? leagueType,
    // 後方互換性のため（非推奨: teamパラメータを使用してください）
    String? range,
  }) async {
    // 後方互換性: rangeパラメータが指定されている場合はteamに変換
    final teamParam = team ?? range;
    
    // リモートデータが必要なカテゴリ
    if (category == AppConstants.categoryMatchRecap) {
      return await _getWeeklyRecapQuestions(
        difficulty: difficulty,
        limit: limit,
        date: date,
        leagueType: leagueType,
        excludeIds: excludeIds,
      );
    }

    // ローカルデータベースから取得
    return await _databaseService.getQuestionsOptimized(
      category: category,
      difficulty: difficulty,
      tags: null, // tagsパラメータは使用しない
      country: country,
      region: region,
      team: teamParam,
      limit: limit,
      excludeIds: excludeIds,
    );
  }

  /// Daily Quiz用の問題を取得
  /// チーム4問(easy2, normal1, hard1)、歴史3問(easy1, normal2, hard0)、ルール3問(easy1, normal1, hard1)
  /// 合計: easy4, normal4, hard2
  Future<List<Question>> getDailyQuizQuestions() async {
    final allQuestions = <Question>[];
    final usedIds = <String>{};

    // チーム: easy 2, normal 1, hard 1
    final teamEasy = await _databaseService.getQuestions(
      category: AppConstants.categoryTeams,
      difficulty: AppConstants.difficultyEasy,
      team: 'j1_all_teams',
      limit: 3,
    );
    final teamNormal = await _databaseService.getQuestions(
      category: AppConstants.categoryTeams,
      difficulty: AppConstants.difficultyNormal,
      team: 'j1_all_teams',
      limit: 2,
    );
    final teamHard = await _databaseService.getQuestions(
      category: AppConstants.categoryTeams,
      difficulty: AppConstants.difficultyHard,
      team: 'j1_all_teams',
      limit: 2,
    );

    _addUniqueQuestions(allQuestions, usedIds, teamEasy, 2);
    _addUniqueQuestions(allQuestions, usedIds, teamNormal, 1);
    _addUniqueQuestions(allQuestions, usedIds, teamHard, 1);

    // 歴史: easy 1, normal 2
    final historyEasy = await _databaseService.getQuestions(
      category: AppConstants.categoryHistory,
      difficulty: AppConstants.difficultyEasy,
      limit: 2,
    );
    final historyNormal = await _databaseService.getQuestions(
      category: AppConstants.categoryHistory,
      difficulty: AppConstants.difficultyNormal,
      limit: 3,
    );

    _addUniqueQuestions(allQuestions, usedIds, historyEasy, 1);
    _addUniqueQuestions(allQuestions, usedIds, historyNormal, 2);

    // ルール: easy 1, normal 1, hard 1
    final ruleEasy = await _databaseService.getQuestions(
      category: AppConstants.categoryRules,
      difficulty: AppConstants.difficultyEasy,
      limit: 2,
    );
    final ruleNormal = await _databaseService.getQuestions(
      category: AppConstants.categoryRules,
      difficulty: AppConstants.difficultyNormal,
      limit: 2,
    );
    final ruleHard = await _databaseService.getQuestions(
      category: AppConstants.categoryRules,
      difficulty: AppConstants.difficultyHard,
      limit: 2,
    );

    _addUniqueQuestions(allQuestions, usedIds, ruleEasy, 1);
    _addUniqueQuestions(allQuestions, usedIds, ruleNormal, 1);
    _addUniqueQuestions(allQuestions, usedIds, ruleHard, 1);

    // データ不足時は他難易度・他カテゴリで補完
    if (allQuestions.length < 10) {
      final needed = 10 - allQuestions.length;
      final fallback = await _databaseService.getQuestions(
        category: AppConstants.categoryTeams,
        difficulty: AppConstants.difficultyEasy,
        team: 'j1_all_teams',
        limit: needed + 5,
      );
      for (final q in fallback) {
        if (allQuestions.length >= 10) break;
        if (!usedIds.contains(q.id)) {
          allQuestions.add(q);
          usedIds.add(q.id);
        }
        if (allQuestions.length >= 10) break;
      }
      if (allQuestions.length < 10) {
        final moreHistory = await _databaseService.getQuestions(
          category: AppConstants.categoryHistory,
          difficulty: AppConstants.difficultyNormal,
          limit: needed + 5,
        );
        for (final q in moreHistory) {
          if (allQuestions.length >= 10) break;
          if (!usedIds.contains(q.id)) {
            allQuestions.add(q);
            usedIds.add(q.id);
          }
        }
      }
      if (allQuestions.length < 10) {
        final moreRules = await _databaseService.getQuestions(
          category: AppConstants.categoryRules,
          difficulty: AppConstants.difficultyEasy,
          limit: needed + 5,
        );
        for (final q in moreRules) {
          if (allQuestions.length >= 10) break;
          if (!usedIds.contains(q.id)) {
            allQuestions.add(q);
            usedIds.add(q.id);
          }
        }
      }
    }

    allQuestions.shuffle();
    return allQuestions.take(10).toList();
  }

  void _addUniqueQuestions(
    List<Question> target,
    Set<String> usedIds,
    List<Question> source,
    int count,
  ) {
    var added = 0;
    for (final q in source) {
      if (added >= count) break;
      if (!usedIds.contains(q.id)) {
        target.add(q);
        usedIds.add(q.id);
        added++;
      }
    }
  }

  /// 問題開放画面用: ページネーション対応の軽量取得
  ///
  /// getQuestionsOptimizedは使用せず、ORDER BY idでoffset/limitを指定。
  /// match_recapカテゴリは対象外（問題開放画面では使用しない）。
  Future<List<Question>> getQuestionsForUnlockScreen({
    required String category,
    required String difficulty,
    String? country,
    String? region,
    String? team,
    int limit = AppConstants.questionUnlockPageSize,
    int offset = 0,
    String? range,
  }) async {
    if (category == AppConstants.categoryMatchRecap) {
      return [];
    }

    return await _databaseService.getQuestions(
      category: category,
      difficulty: difficulty,
      country: country,
      region: region,
      team: team ?? range,
      limit: limit,
      offset: offset,
      orderBy: 'id',
    );
  }

  /// Weekly Recap問題を取得
  /// 
  /// まずローカルDBから取得を試み、見つからない場合はリモートから取得
  /// 難易度の割合:
  /// - ヨーロッパサッカー: easy 7問、normal 2問、hard 1問
  /// - J1リーグ: easy 3問、normal 5問、hard 2問
  /// 出題済み問題は除外される
  Future<List<Question>> _getWeeklyRecapQuestions({
    required String difficulty,
    int? limit,
    String? date,
    String? leagueType,
    List<String>? excludeIds,
  }) async {
    // 出題済み問題IDリストを取得（リーグタイプが指定されている場合）
    List<String> playedQuestionIds = [];
    if (leagueType != null && leagueType.isNotEmpty) {
      playedQuestionIds = await _databaseService.getPlayedQuestionIds(leagueType);
    }
    
    // excludeIdsと出題済み問題IDをマージ
    final allExcludeIds = <String>{};
    if (excludeIds != null) {
      allExcludeIds.addAll(excludeIds);
    }
    allExcludeIds.addAll(playedQuestionIds);
    final finalExcludeIds = allExcludeIds.isEmpty ? null : allExcludeIds.toList();
    // リーグタイプに応じたtagsフィルタリング
    String? tagsFilter;
    if (leagueType != null && leagueType.isNotEmpty) {
      if (leagueType == AppConstants.leagueTypeJ1) {
        // J1の場合: tagsに"j1"が含まれる問題のみ
        tagsFilter = 'j1';
      } else if (leagueType == AppConstants.leagueTypeEurope) {
        // ヨーロッパの場合: tagsに"europe"が含まれる問題のみ
        tagsFilter = 'europe';
      }
    }
    
    // まずローカルDBから取得を試みる
    final localQuestions = await _databaseService.getQuestionsOptimized(
      category: AppConstants.categoryMatchRecap,
      difficulty: '', // 難易度でフィルタリングしない（全難易度を取得）
      tags: tagsFilter, // リーグタイプでフィルタリング
      limit: 1000, // 十分な数を取得
      excludeIds: finalExcludeIds, // 出題済み問題を除外
    );
    
    // ローカルDBにデータがある場合はそれを使用
    if (localQuestions.isNotEmpty) {
      // ヨーロッパの場合、j1が含まれないことを確認
      var filtered = localQuestions;
      if (leagueType == AppConstants.leagueTypeEurope) {
        filtered = filtered.where((q) => 
          q.tags.contains('europe') && !q.tags.contains('j1')
        ).toList();
      }
      
      if (date != null) {
        // referenceDateが設定されていない古いデータも含める（後方互換性のため）
        // ただし、referenceDateが設定されている場合は一致するもののみ
        filtered = filtered.where((q) => 
          q.referenceDate == null || q.referenceDate == date
        ).toList();
      }
      
      // 出題済み問題を除外
      if (finalExcludeIds != null && finalExcludeIds.isNotEmpty) {
        filtered = filtered.where((q) => !finalExcludeIds.contains(q.id)).toList();
      }
      
      // フィルタリング後の問題数が十分でない場合は、リモートから取得
      if (filtered.length < (limit ?? 10)) {
        final remoteQuestions = date != null
            ? await _remoteDataService.fetchWeeklyRecapQuestions(
                date: date,
                leagueType: leagueType,
              )
            : await _remoteDataService.fetchWeeklyRecapQuestionsWithDateFallback(
                leagueType: leagueType,
              );
        // 出題済み問題を除外
        var remoteFiltered = remoteQuestions;
        if (finalExcludeIds != null && finalExcludeIds.isNotEmpty) {
          remoteFiltered = remoteQuestions.where((q) => !finalExcludeIds.contains(q.id)).toList();
        }
        // リモートから取得した問題の方が多い場合はそれを使用
        if (remoteFiltered.length > filtered.length) {
          return _selectQuestionsByDifficultyRatio(
            remoteFiltered, 
            limit ?? 10,
            leagueType: leagueType,
          );
        }
      }
      
      // 難易度の割合で選択（リーグタイプに応じて配分が異なる）
      return _selectQuestionsByDifficultyRatio(
        filtered, 
        limit ?? 10,
        leagueType: leagueType,
      );
    }
    
    // ローカルDBにデータがない場合はリモートから取得（404時は過去週を試行）
    final questions = date != null
        ? await _remoteDataService.fetchWeeklyRecapQuestions(
            date: date,
            leagueType: leagueType,
          )
        : await _remoteDataService.fetchWeeklyRecapQuestionsWithDateFallback(
            leagueType: leagueType,
          );
    
    // 出題済み問題を除外
    var finalQuestions = questions;
    if (finalExcludeIds != null && finalExcludeIds.isNotEmpty) {
      finalQuestions = questions.where((q) => !finalExcludeIds.contains(q.id)).toList();
    }

    // 難易度の割合で選択（リーグタイプに応じて配分が異なる）
    return _selectQuestionsByDifficultyRatio(
      finalQuestions, 
      limit ?? 10,
      leagueType: leagueType,
    );
  }

  /// 難易度の割合で問題を選択
  /// ヨーロッパサッカー: easy 7問、normal 2問、hard 1問
  /// J1リーグ: easy 3問、normal 5問、hard 2問
  List<Question> _selectQuestionsByDifficultyRatio(
    List<Question> questions,
    int totalLimit, {
    String? leagueType,
  }) {
    // 難易度ごとに分類
    final easyQuestions = questions
        .where((q) => q.difficulty == AppConstants.difficultyEasy)
        .toList();
    final normalQuestions = questions
        .where((q) => q.difficulty == AppConstants.difficultyNormal)
        .toList();
    final hardQuestions = questions
        .where((q) => q.difficulty == AppConstants.difficultyHard)
        .toList();

    // 各難易度をシャッフル
    easyQuestions.shuffle();
    normalQuestions.shuffle();
    hardQuestions.shuffle();

    // リーグタイプに応じた配分を決定
    int easyCount;
    int normalCount;
    int hardCount;
    
    if (leagueType == AppConstants.leagueTypeEurope) {
      // ヨーロッパサッカー: easy 7問、normal 2問、hard 1問
      easyCount = (totalLimit * 0.7).round();
      normalCount = (totalLimit * 0.2).round();
      hardCount = totalLimit - easyCount - normalCount;
    } else {
      // J1リーグ: easy 3問、normal 5問、hard 2問
      easyCount = (totalLimit * 0.3).round();
      normalCount = (totalLimit * 0.5).round();
      hardCount = totalLimit - easyCount - normalCount;
    }
    
    final selectedQuestions = <Question>[];
    
    // 各難易度から指定数選択
    selectedQuestions.addAll(easyQuestions.take(easyCount));
    selectedQuestions.addAll(normalQuestions.take(normalCount));
    selectedQuestions.addAll(hardQuestions.take(hardCount));
    
    // 不足分は他の難易度から補完
    if (selectedQuestions.length < totalLimit) {
      final remaining = totalLimit - selectedQuestions.length;
      final allRemaining = [
        ...easyQuestions.skip(easyCount),
        ...normalQuestions.skip(normalCount),
        ...hardQuestions.skip(hardCount),
      ];
      allRemaining.shuffle();
      selectedQuestions.addAll(allRemaining.take(remaining));
    }
    
    // 最終的にシャッフル
    selectedQuestions.shuffle();
    
    return selectedQuestions.take(totalLimit).toList();
  }
}
