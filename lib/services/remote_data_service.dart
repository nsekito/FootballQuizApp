import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../utils/constants.dart';

/// リモートデータサービス（GitHub RawからJSONを取得）
class RemoteDataService {
  /// GitHub Raw URLを構築
  String _buildGitHubRawUrl(String filePath) {
    return '${AppConstants.githubRawBaseUrl}/'
        '${AppConstants.githubRepoOwner}/'
        '${AppConstants.githubRepoName}/'
        '${AppConstants.githubBranch}/'
        '$filePath';
  }

  /// GitHub RawからJSONデータを取得
  Future<Map<String, dynamic>> _fetchFromGitHubRaw(String url) async {
    try {
      final response = await http
          .get(
            Uri.parse(url),
          )
          .timeout(
            const Duration(seconds: AppConstants.remoteDataTimeoutSeconds),
          );

      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      } else {
        throw RemoteDataException(
          'HTTPエラー: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on http.ClientException catch (e) {
      throw RemoteDataException(
        'ネットワークエラー: ${e.message}',
        isNetworkError: true,
      );
    } on FormatException catch (e) {
      throw RemoteDataException(
        'JSON解析エラー: ${e.message}',
        isParseError: true,
      );
    } catch (e) {
      throw RemoteDataException(
        '予期しないエラー: ${e.toString()}',
      );
    }
  }

  /// Weekly Recap用の問題を取得
  /// 
  /// [date] 日付（YYYY-MM-DD形式、例: "2025-01-13"）
  /// [leagueType] リーグタイプ（"j1" または "europe"）
  /// 指定しない場合は最新の週を取得
  Future<List<Question>> fetchWeeklyRecapQuestions({
    String? date,
    String? leagueType,
  }) async {
    // 日付が指定されていない場合は、最新の週の月曜日の日付を使用
    final targetDate = date ?? _getLatestMonday();
    // リーグタイプが指定されていない場合はj1をデフォルトとする
    final targetLeagueType = leagueType ?? AppConstants.leagueTypeJ1;
    
    // ファイルパス: YYYY-MM-DD_leagueType.json (例: 2025-01-13_j1.json)
    final filePath = '${AppConstants.weeklyRecapDataPath}/${targetDate}_$targetLeagueType.json';
    final url = _buildGitHubRawUrl(filePath);

    final data = await _fetchFromGitHubRaw(url);
    return _parseQuestionsFromJson(data, date: targetDate);
  }

  /// 指定日付のすべてのリーグタイプのWeekly Recap問題を取得（DB取り込み用）
  /// 
  /// [date] 日付（YYYY-MM-DD形式、例: "2025-01-13"）
  /// 指定しない場合は最新の週を取得
  /// 戻り値: Map<leagueType, List<Question>>
  Future<Map<String, List<Question>>> fetchAllWeeklyRecapQuestions({
    String? date,
  }) async {
    final targetDate = date ?? _getLatestMonday();
    final Map<String, List<Question>> result = {};
    
    // J1とヨーロッパの両方を取得
    try {
      final j1Questions = await fetchWeeklyRecapQuestions(
        date: targetDate,
        leagueType: AppConstants.leagueTypeJ1,
      );
      result[AppConstants.leagueTypeJ1] = j1Questions;
    } catch (e) {
      // 404エラーの場合（ファイルが存在しない）は空リストを返す
      if (e is RemoteDataException && e.statusCode == 404) {
        result[AppConstants.leagueTypeJ1] = [];
      } else {
        rethrow;
      }
    }
    
    try {
      final europeQuestions = await fetchWeeklyRecapQuestions(
        date: targetDate,
        leagueType: AppConstants.leagueTypeEurope,
      );
      result[AppConstants.leagueTypeEurope] = europeQuestions;
    } catch (e) {
      // 404エラーの場合（ファイルが存在しない）は空リストを返す
      if (e is RemoteDataException && e.statusCode == 404) {
        result[AppConstants.leagueTypeEurope] = [];
      } else {
        rethrow;
      }
    }
    
    return result;
  }

  /// ニュースクイズ用の問題を取得
  /// 
  /// [year] 年（例: "2025"）
  /// [region] 地域（"domestic" または "world"）
  /// [difficulty] 難易度（オプション）
  Future<List<Question>> fetchNewsQuestions({
    required String year,
    String? region,
    String? difficulty,
  }) async {
    // ファイルパスを構築
    String filePath;
    if (region != null) {
      filePath = '${AppConstants.newsDataPath}/$year/$region.json';
    } else {
      filePath = '${AppConstants.newsDataPath}/$year/all.json';
    }

    final url = _buildGitHubRawUrl(filePath);
    final data = await _fetchFromGitHubRaw(url);

    List<Question> questions = _parseQuestionsFromJson(data);

    // 難易度でフィルタリング
    if (difficulty != null && difficulty.isNotEmpty) {
      questions = questions
          .where((q) => q.difficulty == difficulty)
          .toList();
    }

    return questions;
  }

  /// JSONデータからQuestionリストをパース
  List<Question> _parseQuestionsFromJson(Map<String, dynamic> json, {String? date}) {
    final questionsJson = json['questions'] as List<dynamic>?;
    if (questionsJson == null) {
      throw RemoteDataException('JSONに"questions"フィールドがありません');
    }

    // トップレベルのdateフィールドを取得（なければ引数のdateを使用）
    final topLevelDate = json['date'] as String? ?? date;

    return questionsJson
        .map((q) {
          final questionMap = q as Map<String, dynamic>;
          // referenceDateが設定されていない場合、トップレベルのdateを使用
          if (questionMap['referenceDate'] == null && topLevelDate != null) {
            questionMap['referenceDate'] = topLevelDate;
          }
          return Question.fromJson(questionMap);
        })
        .toList();
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

/// リモートデータ取得時の例外
class RemoteDataException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;
  final bool isParseError;

  RemoteDataException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
    this.isParseError = false,
  });

  @override
  String toString() => message;

  /// ユーザーフレンドリーなエラーメッセージを取得
  String getUserFriendlyMessage() {
    if (isNetworkError) {
      return 'ネットワークに接続できません。\nインターネット接続を確認してください。';
    }
    if (isParseError) {
      return 'データの形式が正しくありません。\nしばらくしてから再度お試しください。';
    }
    if (statusCode == 404) {
      return 'データが見つかりません。\nまだ配信されていない可能性があります。';
    }
    return 'データの取得に失敗しました。\n$message';
  }
}
