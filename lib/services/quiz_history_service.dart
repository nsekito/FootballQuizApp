import 'package:sqflite/sqflite.dart';
import '../models/quiz_history.dart';
import 'database_service.dart';

/// クイズ履歴管理サービス
class QuizHistoryService {
  final DatabaseService _databaseService;

  QuizHistoryService(this._databaseService);

  /// クイズ履歴を保存
  Future<int> saveHistory(QuizHistory history) async {
    final db = await DatabaseService.database;
    return await db.insert(
      'quiz_history',
      history.toMap(),
    );
  }

  /// すべてのクイズ履歴を取得（新しい順）
  Future<List<QuizHistory>> getAllHistory({int? limit}) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quiz_history',
      orderBy: 'completed_at DESC',
      limit: limit,
    );
    return maps.map((map) => QuizHistory.fromMap(map)).toList();
  }

  /// カテゴリ別の履歴を取得
  Future<List<QuizHistory>> getHistoryByCategory(String category) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quiz_history',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'completed_at DESC',
    );
    return maps.map((map) => QuizHistory.fromMap(map)).toList();
  }

  /// 難易度別の履歴を取得
  Future<List<QuizHistory>> getHistoryByDifficulty(String difficulty) async {
    final db = await DatabaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'quiz_history',
      where: 'difficulty = ?',
      whereArgs: [difficulty],
      orderBy: 'completed_at DESC',
    );
    return maps.map((map) => QuizHistory.fromMap(map)).toList();
  }

  /// 統計情報を取得
  Future<QuizStatistics> getStatistics() async {
    final db = await DatabaseService.database;
    
    // 総プレイ回数
    final totalPlaysResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM quiz_history',
    );
    final totalPlays = totalPlaysResult.first['count'] as int;

    // 総正答数と総問題数
    final scoreResult = await db.rawQuery(
      'SELECT SUM(score) as total_score, SUM(total) as total_questions FROM quiz_history',
    );
    final totalScore = (scoreResult.first['total_score'] as int?) ?? 0;
    final totalQuestions = (scoreResult.first['total_questions'] as int?) ?? 0;
    final overallAccuracy = totalQuestions > 0 ? totalScore / totalQuestions : 0.0;

    // カテゴリ別の統計
    final categoryStats = await db.rawQuery('''
      SELECT 
        category,
        COUNT(*) as play_count,
        SUM(score) as total_score,
        SUM(total) as total_questions
      FROM quiz_history
      GROUP BY category
    ''');

    // 難易度別の統計
    final difficultyStats = await db.rawQuery('''
      SELECT 
        difficulty,
        COUNT(*) as play_count,
        SUM(score) as total_score,
        SUM(total) as total_questions
      FROM quiz_history
      GROUP BY difficulty
    ''');

    return QuizStatistics(
      totalPlays: totalPlays,
      overallAccuracy: overallAccuracy,
      totalScore: totalScore,
      totalQuestions: totalQuestions,
      categoryStats: categoryStats.map((map) => CategoryStatistic.fromMap(map)).toList(),
      difficultyStats: difficultyStats.map((map) => DifficultyStatistic.fromMap(map)).toList(),
    );
  }

  /// 履歴を削除
  Future<int> deleteHistory(int id) async {
    final db = await DatabaseService.database;
    return await db.delete(
      'quiz_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// すべての履歴を削除
  Future<int> deleteAllHistory() async {
    final db = await DatabaseService.database;
    return await db.delete('quiz_history');
  }
}

/// クイズ統計情報
class QuizStatistics {
  final int totalPlays;
  final double overallAccuracy;
  final int totalScore;
  final int totalQuestions;
  final List<CategoryStatistic> categoryStats;
  final List<DifficultyStatistic> difficultyStats;

  QuizStatistics({
    required this.totalPlays,
    required this.overallAccuracy,
    required this.totalScore,
    required this.totalQuestions,
    required this.categoryStats,
    required this.difficultyStats,
  });
}

/// カテゴリ別統計
class CategoryStatistic {
  final String category;
  final int playCount;
  final int totalScore;
  final int totalQuestions;

  CategoryStatistic({
    required this.category,
    required this.playCount,
    required this.totalScore,
    required this.totalQuestions,
  });

  double get accuracy => totalQuestions > 0 ? totalScore / totalQuestions : 0.0;

  factory CategoryStatistic.fromMap(Map<String, dynamic> map) => CategoryStatistic(
        category: map['category'] as String,
        playCount: map['play_count'] as int,
        totalScore: (map['total_score'] as int?) ?? 0,
        totalQuestions: (map['total_questions'] as int?) ?? 0,
      );
}

/// 難易度別統計
class DifficultyStatistic {
  final String difficulty;
  final int playCount;
  final int totalScore;
  final int totalQuestions;

  DifficultyStatistic({
    required this.difficulty,
    required this.playCount,
    required this.totalScore,
    required this.totalQuestions,
  });

  double get accuracy => totalQuestions > 0 ? totalScore / totalQuestions : 0.0;

  factory DifficultyStatistic.fromMap(Map<String, dynamic> map) => DifficultyStatistic(
        difficulty: map['difficulty'] as String,
        playCount: map['play_count'] as int,
        totalScore: (map['total_score'] as int?) ?? 0,
        totalQuestions: (map['total_questions'] as int?) ?? 0,
      );
}
