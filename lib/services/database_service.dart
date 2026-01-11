import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';

/// SQLiteデータベースサービス
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'soccer_quiz.db';
  static const int _databaseVersion = 1;

  /// データベースインスタンスを取得
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// データベースを初期化
  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// データベース作成時の処理
  static Future<void> _onCreate(Database db, int version) async {
    // クイズ問題テーブル
    await db.execute('''
      CREATE TABLE questions (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        options TEXT NOT NULL,
        answerIndex INTEGER NOT NULL,
        explanation TEXT NOT NULL,
        trivia TEXT,
        category TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        tags TEXT NOT NULL
      )
    ''');

    // ユーザーデータテーブル
    await db.execute('''
      CREATE TABLE user_data (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // 初期ユーザーデータを挿入
    await db.insert('user_data', {
      'key': 'total_points',
      'value': '0',
    });
  }

  /// データベースアップグレード時の処理
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // 将来のアップグレード処理をここに追加
  }

  /// クイズ問題を追加
  Future<void> insertQuestion(Question question) async {
    final db = await database;
    await db.insert(
      'questions',
      {
        'id': question.id,
        'text': question.text,
        'options': question.options.join('|||'), // 区切り文字で結合
        'answerIndex': question.answerIndex,
        'explanation': question.explanation,
        'trivia': question.trivia,
        'category': question.category,
        'difficulty': question.difficulty,
        'tags': question.tags,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 複数のクイズ問題を一括追加
  Future<void> insertQuestions(List<Question> questions) async {
    final db = await database;
    final batch = db.batch();
    for (final question in questions) {
      batch.insert(
        'questions',
        {
          'id': question.id,
          'text': question.text,
          'options': question.options.join('|||'),
          'answerIndex': question.answerIndex,
          'explanation': question.explanation,
          'trivia': question.trivia,
          'category': question.category,
          'difficulty': question.difficulty,
          'tags': question.tags,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 条件に基づいてクイズ問題を取得
  Future<List<Question>> getQuestions({
    String? category,
    String? difficulty,
    String? tags,
    int? limit,
  }) async {
    final db = await database;
    final List<Map<String, dynamic>> maps;

    var query = 'SELECT * FROM questions WHERE 1=1';
    final List<dynamic> args = [];

    if (category != null && category.isNotEmpty) {
      query += ' AND category = ?';
      args.add(category);
    }

    if (difficulty != null && difficulty.isNotEmpty) {
      query += ' AND difficulty = ?';
      args.add(difficulty);
    }

    if (tags != null && tags.isNotEmpty) {
      query += ' AND tags LIKE ?';
      args.add('%$tags%');
    }

    query += ' ORDER BY RANDOM()';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    maps = await db.rawQuery(query, args);

    return maps.map((map) => _mapToQuestion(map)).toList();
  }

  /// MapからQuestionオブジェクトに変換
  Question _mapToQuestion(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as String,
      text: map['text'] as String,
      options: (map['options'] as String).split('|||'),
      answerIndex: map['answerIndex'] as int,
      explanation: map['explanation'] as String,
      trivia: map['trivia'] as String?,
      category: map['category'] as String,
      difficulty: map['difficulty'] as String,
      tags: map['tags'] as String,
    );
  }

  /// ユーザーの累計ポイントを取得
  Future<int> getTotalPoints() async {
    final db = await database;
    final result = await db.query(
      'user_data',
      where: 'key = ?',
      whereArgs: ['total_points'],
    );
    if (result.isEmpty) {
      return 0;
    }
    return int.tryParse(result.first['value'] as String) ?? 0;
  }

  /// ユーザーの累計ポイントを更新
  Future<void> updateTotalPoints(int points) async {
    final db = await database;
    await db.update(
      'user_data',
      {'value': points.toString()},
      where: 'key = ?',
      whereArgs: ['total_points'],
    );
  }

  /// ポイントを追加
  Future<void> addPoints(int points) async {
    final currentPoints = await getTotalPoints();
    await updateTotalPoints(currentPoints + points);
  }

  /// データベースを閉じる
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
