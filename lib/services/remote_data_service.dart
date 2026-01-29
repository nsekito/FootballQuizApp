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
  /// 指定しない場合は最新の週を取得
  Future<List<Question>> fetchWeeklyRecapQuestions({
    String? date,
  }) async {
    // 日付が指定されていない場合は、最新の週の月曜日の日付を使用
    // 簡易実装: 実際の運用では、最新のファイルを検出するロジックが必要
    final targetDate = date ?? _getLatestMonday();
    final filePath = '${AppConstants.weeklyRecapDataPath}/$targetDate.json';
    final url = _buildGitHubRawUrl(filePath);

    final data = await _fetchFromGitHubRaw(url);
    return _parseQuestionsFromJson(data);
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
  List<Question> _parseQuestionsFromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>?;
    if (questionsJson == null) {
      throw RemoteDataException('JSONに"questions"フィールドがありません');
    }

    return questionsJson
        .map((q) => Question.fromJson(q as Map<String, dynamic>))
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
