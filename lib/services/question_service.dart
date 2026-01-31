import '../models/question.dart';
import '../utils/constants.dart';
import 'database_service.dart';
import 'remote_data_service.dart';

/// 問題取得を統合するサービス
/// 
/// カテゴリに応じて適切なデータソースから問題を取得します。
/// - match_recap, news → リモートデータサービス
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
  /// [category] カテゴリ（rules, history, teams, match_recap, news）
  /// [difficulty] 難易度（easy, normal, hard, extreme）。Weekly Recapの場合は空文字列でも可
  /// [tags] タグ（カンマ区切り、オプション）
  /// [country] 国（オプション）
  /// [region] 地域（オプション）
  /// [range] 範囲（オプション）
  /// [limit] 取得する問題数（デフォルト: 10）
  /// [excludeIds] 除外する問題IDのリスト（オプション）
  /// [year] 年（ニュースクイズ用、オプション）
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
    String? year,
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

    if (category == AppConstants.categoryNews) {
      return await _getNewsQuestions(
        difficulty: difficulty,
        year: year,
        region: region,
        limit: limit,
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
  /// 難易度の割合: easy 3問、normal 5問、hard 2問
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
        filtered = filtered.where((q) => q.referenceDate == date).toList();
      }
      
      // 難易度の割合で選択（easy 3問、normal 5問、hard 2問）
      return _selectQuestionsByDifficultyRatio(filtered, limit ?? 10);
    }
    
    // ローカルDBにデータがない場合はリモートから取得
    final questions = await _remoteDataService.fetchWeeklyRecapQuestions(
      date: date,
      leagueType: leagueType,
    );

    // 難易度の割合で選択（easy 3問、normal 5問、hard 2問）
    return _selectQuestionsByDifficultyRatio(questions, limit ?? 10);
  }

  /// 難易度の割合で問題を選択（easy 3問、normal 5問、hard 2問）
  List<Question> _selectQuestionsByDifficultyRatio(
    List<Question> questions,
    int totalLimit,
  ) {
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

    // 割合に基づいて選択（easy 3問、normal 5問、hard 2問）
    final selectedQuestions = <Question>[];
    
    // easy 3問
    final easyCount = (totalLimit * 0.3).round();
    selectedQuestions.addAll(easyQuestions.take(easyCount));
    
    // normal 5問
    final normalCount = (totalLimit * 0.5).round();
    selectedQuestions.addAll(normalQuestions.take(normalCount));
    
    // hard 2問
    final hardCount = totalLimit - selectedQuestions.length;
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

  /// ニュースクイズ問題を取得
  Future<List<Question>> _getNewsQuestions({
    required String difficulty,
    String? year,
    String? region,
    int? limit,
  }) async {
    // 年が指定されていない場合は現在の年を使用
    final targetYear = year ?? DateTime.now().year.toString();

    final questions = await _remoteDataService.fetchNewsQuestions(
      year: targetYear,
      region: region,
      difficulty: difficulty,
    );

    // ランダムにシャッフル
    questions.shuffle();

    // 指定された数だけ返す
    final resultLimit = limit ?? AppConstants.defaultQuestionsPerQuiz;
    return questions.take(resultLimit).toList();
  }
}
