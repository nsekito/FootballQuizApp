import '../models/question.dart';
import '../utils/constants.dart';
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
  /// [range] 範囲（オプション）
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
    String? range,
    int? limit,
    List<String>? excludeIds,
    String? date,
    String? leagueType,
  }) async {
    // リモートデータが必要なカテゴリ
    if (category == AppConstants.categoryMatchRecap) {
      return await _getWeeklyRecapQuestions(
        difficulty: difficulty,
        limit: limit,
        date: date,
        leagueType: leagueType,
      );
    }

    // ローカルデータベースから取得
    return await _databaseService.getQuestionsOptimized(
      category: category,
      difficulty: difficulty,
      tags: tags,
      country: country,
      range: range,
      limit: limit,
      excludeIds: excludeIds,
    );
  }

  /// Weekly Recap問題を取得
  /// 
  /// まずローカルDBから取得を試み、見つからない場合はリモートから取得
  /// 難易度の割合:
  /// - ヨーロッパサッカー: easy 7問、normal 2問、hard 1問
  /// - J1リーグ: easy 3問、normal 5問、hard 2問
  Future<List<Question>> _getWeeklyRecapQuestions({
    required String difficulty,
    int? limit,
    String? date,
    String? leagueType,
  }) async {
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
      
      // フィルタリング後の問題数が十分でない場合は、リモートから取得
      if (filtered.length < (limit ?? 10)) {
        final remoteQuestions = await _remoteDataService.fetchWeeklyRecapQuestions(
          date: date,
          leagueType: leagueType,
        );
        // リモートから取得した問題の方が多い場合はそれを使用
        if (remoteQuestions.length > filtered.length) {
          return _selectQuestionsByDifficultyRatio(
            remoteQuestions, 
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
    
    // ローカルDBにデータがない場合はリモートから取得
    final questions = await _remoteDataService.fetchWeeklyRecapQuestions(
      date: date,
      leagueType: leagueType,
    );

    // 難易度の割合で選択（リーグタイプに応じて配分が異なる）
    return _selectQuestionsByDifficultyRatio(
      questions, 
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
