import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import '../utils/constants.dart';

/// SQLiteデータベースサービス
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'soccer_quiz.db';
  static const int _databaseVersion = 2;
  
  // キャッシュ用のマップ（問題ID -> Question）
  final Map<String, Question> _questionCache = {};
  
  // キャッシュの最大サイズ
  static const int _maxCacheSize = 100;

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

    // クイズ履歴テーブル
    await db.execute('''
      CREATE TABLE quiz_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        score INTEGER NOT NULL,
        total INTEGER NOT NULL,
        earned_points INTEGER NOT NULL,
        completed_at TEXT NOT NULL
      )
    ''');

    // インデックスの追加（パフォーマンス向上のため）
    await db.execute('''
      CREATE INDEX idx_quiz_history_category ON quiz_history(category)
    ''');
    await db.execute('''
      CREATE INDEX idx_quiz_history_difficulty ON quiz_history(difficulty)
    ''');
    await db.execute('''
      CREATE INDEX idx_quiz_history_completed_at ON quiz_history(completed_at)
    ''');
    await db.execute('''
      CREATE INDEX idx_questions_category_difficulty ON questions(category, difficulty)
    ''');
    await db.execute('''
      CREATE INDEX idx_questions_tags ON questions(tags)
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
    // バージョン1から2へのマイグレーション
    if (oldVersion < 2) {
      // クイズ履歴テーブルの追加
      await db.execute('''
        CREATE TABLE IF NOT EXISTS quiz_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          difficulty TEXT NOT NULL,
          score INTEGER NOT NULL,
          total INTEGER NOT NULL,
          earned_points INTEGER NOT NULL,
          completed_at TEXT NOT NULL
        )
      ''');

      // インデックスの追加
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_history_category ON quiz_history(category)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_history_difficulty ON quiz_history(difficulty)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_quiz_history_completed_at ON quiz_history(completed_at)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_questions_category_difficulty ON questions(category, difficulty)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_questions_tags ON questions(tags)
      ''');
    }
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
    String? country,
    String? range,
    int? limit,
    List<String>? excludeIds,
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

    // タグ検索の強化（複数タグ対応、AND検索）
    if (tags != null && tags.isNotEmpty) {
      final tagList = tags.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
      if (tagList.isNotEmpty) {
        // すべてのタグを含む問題を検索（AND検索）
        for (final tag in tagList) {
          query += ' AND tags LIKE ?';
          args.add('%$tag%');
        }
      }
    }

    // 国によるフィルタリング
    if (country != null && country.isNotEmpty) {
      query += ' AND tags LIKE ?';
      args.add('%$country%');
    }

    // 範囲によるフィルタリング
    if (range != null && range.isNotEmpty) {
      if (range == 'j1全チーム' || range == 'j1_all_teams') {
        // J1全チーム: japanタグとj1タグを含む
        query += ' AND tags LIKE ? AND tags LIKE ?';
        args.add('%japan%');
        args.add('%j1%');
      } else if (range == 'j2全チーム' || range == 'j2_all_teams') {
        // J2全チーム: japanタグとj2タグを含む
        query += ' AND tags LIKE ? AND tags LIKE ?';
        args.add('%japan%');
        args.add('%j2%');
      } else if (range == '海外top3' || range == 'overseas_top3') {
        // 海外Top3: イタリア、スペイン、イングランドのいずれか
        query += ' AND (tags LIKE ? OR tags LIKE ? OR tags LIKE ?)';
        args.add('%italy%');
        args.add('%spain%');
        args.add('%england%');
      }
    }

    // 重複回避: 指定されたIDを除外
    if (excludeIds != null && excludeIds.isNotEmpty) {
      final placeholders = excludeIds.map((_) => '?').join(',');
      query += ' AND id NOT IN ($placeholders)';
      args.addAll(excludeIds);
    }

    query += ' ORDER BY RANDOM()';

    if (limit != null) {
      query += ' LIMIT ?';
      args.add(limit);
    }

    maps = await db.rawQuery(query, args);

    return maps.map((map) => _mapToQuestion(map)).toList();
  }

  /// 改善されたクイズ問題取得（重複回避、難易度バランス調整）
  Future<List<Question>> getQuestionsOptimized({
    String? category,
    String? difficulty,
    String? tags,
    String? country,
    String? range,
    int? limit,
    List<String>? excludeIds,
    bool balanceDifficulty = false,
  }) async {
    final requestedLimit = limit ?? AppConstants.defaultQuestionsPerQuiz;
    
    // 難易度バランス調整が有効な場合
    if (balanceDifficulty && difficulty == null) {
      return await _getQuestionsWithDifficultyBalance(
        category: category,
        tags: tags,
        country: country,
        range: range,
        limit: requestedLimit,
        excludeIds: excludeIds,
      );
    }

    // 通常の取得（重複回避付き）
    final questions = await getQuestions(
      category: category,
      difficulty: difficulty,
      tags: tags,
      country: country,
      range: range,
      limit: requestedLimit * 2, // 余分に取得してシャッフル
      excludeIds: excludeIds,
    );

    // ランダム性を向上させるため、取得した問題をシャッフル
    questions.shuffle();

    // 指定された数だけ返す
    return questions.take(requestedLimit).toList();
  }

  /// 難易度バランスを考慮した問題取得
  Future<List<Question>> _getQuestionsWithDifficultyBalance({
    String? category,
    String? tags,
    String? country,
    String? range,
    int? limit,
    List<String>? excludeIds,
  }) async {
    final difficulties = [
      AppConstants.difficultyEasy,
      AppConstants.difficultyNormal,
      AppConstants.difficultyHard,
      AppConstants.difficultyExtreme,
    ];

    // 各難易度から均等に取得
    final questionsPerDifficulty = (limit! / difficulties.length).ceil();
    final List<Question> balancedQuestions = [];

    for (final diff in difficulties) {
      final questions = await getQuestions(
        category: category,
        difficulty: diff,
        tags: tags,
        country: country,
        range: range,
        limit: questionsPerDifficulty,
        excludeIds: excludeIds,
      );
      balancedQuestions.addAll(questions);
    }

    // シャッフルしてランダム性を向上
    balancedQuestions.shuffle();
    return balancedQuestions.take(limit).toList();
  }


  /// MapからQuestionオブジェクトに変換（キャッシュ対応）
  Question _mapToQuestion(Map<String, dynamic> map) {
    final id = map['id'] as String;
    
    // キャッシュから取得を試みる
    if (_questionCache.containsKey(id)) {
      return _questionCache[id]!;
    }
    
    // キャッシュにない場合は新規作成
    final question = Question(
      id: id,
      text: map['text'] as String,
      options: (map['options'] as String).split('|||'),
      answerIndex: map['answerIndex'] as int,
      explanation: map['explanation'] as String,
      trivia: map['trivia'] as String?,
      category: map['category'] as String,
      difficulty: map['difficulty'] as String,
      tags: map['tags'] as String,
    );
    
    // キャッシュに追加（サイズ制限あり）
    _addToCache(id, question);
    
    return question;
  }
  
  /// キャッシュに追加（サイズ制限あり）
  void _addToCache(String id, Question question) {
    // キャッシュサイズが上限に達している場合、古いエントリを削除
    if (_questionCache.length >= _maxCacheSize) {
      // 最初のエントリを削除（FIFO方式）
      final firstKey = _questionCache.keys.first;
      _questionCache.remove(firstKey);
    }
    
    _questionCache[id] = question;
  }
  
  /// キャッシュをクリア
  void clearCache() {
    _questionCache.clear();
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
