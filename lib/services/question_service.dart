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
  /// [difficulty] 難易度（easy, normal, hard, extreme）
  /// [tags] タグ（カンマ区切り、オプション）
  /// [country] 国（オプション）
  /// [region] 地域（オプション）
  /// [range] 範囲（オプション）
  /// [limit] 取得する問題数（デフォルト: 10）
  /// [excludeIds] 除外する問題IDのリスト（オプション）
  /// [year] 年（ニュースクイズ用、オプション）
  /// [date] 日付（Weekly Recap用、YYYY-MM-DD形式、オプション）
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
  }) async {
    // リモートデータが必要なカテゴリ
    if (category == AppConstants.categoryMatchRecap) {
      return await _getWeeklyRecapQuestions(
        difficulty: difficulty,
        limit: limit,
        date: date,
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
  Future<List<Question>> _getWeeklyRecapQuestions({
    required String difficulty,
    int? limit,
    String? date,
  }) async {
    final questions = await _remoteDataService.fetchWeeklyRecapQuestions(
      date: date,
    );

    // 難易度でフィルタリング
    final filtered = questions
        .where((q) => q.difficulty == difficulty)
        .toList();

    // ランダムにシャッフル
    filtered.shuffle();

    // 指定された数だけ返す
    final resultLimit = limit ?? AppConstants.defaultQuestionsPerQuiz;
    return filtered.take(resultLimit).toList();
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
