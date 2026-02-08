import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import '../utils/constants.dart';
import '../utils/unlock_key_utils.dart';

/// SQLiteデータベースサービス
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'questions.db';  // アセットファイル名と一致させる
  static const int _databaseVersion = 7;  // バージョンを上げて新しいデータベースを強制的に適用
  
  // キャッシュ用のマップ（問題ID -> Question）
  final Map<String, Question> _questionCache = {};
  
  // キャッシュの最大サイズ
  static const int _maxCacheSize = 100;

  /// データベースインスタンスを取得（静的メソッド）
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// データベースインスタンスを取得（インスタンスメソッド）
  Future<Database> getDatabase() async {
    return await database;
  }

  /// データベースを初期化
  static Future<Database> _initDatabase() async {
    String dbPath;
    
    if (kIsWeb) {
      // Webプラットフォームでは、IndexedDBを使用（getDatabasesPath()はWebでも動作する）
      dbPath = join(await getDatabasesPath(), _databaseName);
      debugPrint('Webプラットフォーム: データベースパス: $dbPath');
      
      // Webプラットフォームでは、データベースが存在しない場合、アセットから読み込む
      if (!await databaseFactory.databaseExists(dbPath)) {
        debugPrint('Webプラットフォーム: データベースが存在しないため、アセットから読み込みます');
        await _loadDatabaseFromAssetsForWeb(dbPath);
      } else {
        debugPrint('Webプラットフォーム: 既存のデータベースファイルが見つかりました');
      }
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // デスクトップ環境では、プロジェクトディレクトリを使用
      dbPath = join(Directory.current.path, 'data', _databaseName);
      debugPrint('デスクトップ環境: データベースパス: $dbPath');
      
      // データベースファイルが存在しない場合、アセットからコピー
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        debugPrint('データベースファイルが存在しないため、アセットからコピーします');
        await _copyDatabaseFromAssets(dbPath);
      } else {
        debugPrint('既存のデータベースファイルが見つかりました');
      }
    } else {
      // モバイル環境では、getDatabasesPath()を使用
      dbPath = join(await getDatabasesPath(), _databaseName);
      debugPrint('モバイル環境: データベースパス: $dbPath');
      
      // データベースファイルが存在しない場合、アセットからコピー
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        debugPrint('データベースファイルが存在しないため、アセットからコピーします');
        await _copyDatabaseFromAssets(dbPath);
      } else {
        debugPrint('既存のデータベースファイルが見つかりました');
      }
    }
    
    final path = dbPath;

    final database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    
    // データベースが空の場合（アセットからコピーした場合）、onCreateは呼ばれないため
    // 既存のデータベースに問題があるか確認
    final count = await database.rawQuery('SELECT COUNT(*) as count FROM questions');
    final questionCount = count.first['count'] as int;
    debugPrint('データベース内の問題数: $questionCount');
    
    if (questionCount == 0) {
      debugPrint('データベースが空のため、アセットからコピーを試みます');
      if (kIsWeb) {
        // Webプラットフォームでは、アセットからデータベースを再読み込み
        await database.close();
        await _loadDatabaseFromAssetsForWeb(path);
        final newDatabase = await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
        final newCount = await newDatabase.rawQuery('SELECT COUNT(*) as count FROM questions');
        final newQuestionCount = newCount.first['count'] as int;
        debugPrint('Webプラットフォーム: 再読み込み後の問題数: $newQuestionCount');
        return newDatabase;
      } else {
        // モバイル/デスクトップ環境では、アセットからコピーを試みる
        await _copyDatabaseFromAssets(path);
        // データベースを再オープンして、コピーしたデータを読み込む
        await database.close();
        final newDatabase = await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
        final newCount = await newDatabase.rawQuery('SELECT COUNT(*) as count FROM questions');
        final newQuestionCount = newCount.first['count'] as int;
        debugPrint('コピー後の問題数: $newQuestionCount');
        return newDatabase;
      }
    }
    
    return database;
  }

  /// アセットからデータベースをコピー（Webプラットフォーム以外）
  static Future<void> _copyDatabaseFromAssets(String targetPath) async {
    try {
      // アセットからデータベースファイルを読み込み
      final ByteData data = await rootBundle.load('data/questions.db');
      final List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      
      // ターゲットパスに書き込み
      final File file = File(targetPath);
      await file.writeAsBytes(bytes);
      
      debugPrint('データベースをアセットからコピーしました: $targetPath');
    } catch (e) {
      debugPrint('アセットからのデータベースコピーに失敗しました: $e');
      // アセットがない場合は、空のデータベースを作成（onCreateが呼ばれる）
    }
  }

  /// Webプラットフォーム用: アセットからデータベースを読み込む
  /// sqflite_common_ffi_webでは、writeDatabaseBytesメソッドを使用してアセットからデータベースを読み込む
  static Future<void> _loadDatabaseFromAssetsForWeb(String dbPath) async {
    try {
      // アセットからデータベースファイルを読み込み
      final ByteData data = await rootBundle.load('data/questions.db');
      final Uint8List bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      
      // Webプラットフォームでは、sqflite_common_ffi_webのwriteDatabaseBytesを使用
      // このメソッドは、バイト配列からデータベースファイルを書き込む
      // NoSuchMethodErrorをキャッチして、メソッドが存在しない場合は別の方法を試す
      try {
        // writeDatabaseBytesメソッドを呼び出す（dynamic型でキャスト）
        await (databaseFactory as dynamic).writeDatabaseBytes(dbPath, bytes);
        debugPrint('Webプラットフォーム: データベースをアセットから読み込みました: $dbPath');
        return;
      } on NoSuchMethodError catch (e) {
        debugPrint('writeDatabaseBytesメソッドが存在しません: $e');
        // メソッドが存在しない場合、別の方法を試す
      } catch (e) {
        debugPrint('writeDatabaseBytesメソッドの呼び出しに失敗しました: $e');
        // その他のエラーの場合も続行
      }
      
      // フォールバック: メソッドが存在しない場合の処理
      // Webプラットフォームでは、アセットからデータベースを直接読み込むことができない場合、
      // データベースは空の状態で作成され、必要に応じてデータを追加する必要があります
      debugPrint('Webプラットフォーム: writeDatabaseBytesメソッドが使用できないため、データベースは空の状態で作成されます');
      debugPrint('注意: Webプラットフォームでは、アセットからのデータベース読み込みは、sqflite_common_ffi_webのバージョンによってサポートされていない可能性があります');
    } catch (e) {
      debugPrint('Webプラットフォーム: アセットからのデータベース読み込みに失敗しました: $e');
      // エラーが発生した場合でも、空のデータベースは作成される（onCreateが呼ばれる）
    }
  }

  /// データベース作成時の処理
  static Future<void> _onCreate(Database db, int version) async {
    // クイズ問題テーブル（IF NOT EXISTSを追加して、既存テーブルがある場合でもエラーにならないようにする）
    await db.execute('''
      CREATE TABLE IF NOT EXISTS questions (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        options TEXT NOT NULL,
        answerIndex INTEGER NOT NULL,
        explanation TEXT NOT NULL,
        trivia TEXT,
        category TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        tags TEXT NOT NULL,
        reference_date TEXT,
        quiz_type TEXT,
        category_id TEXT,
        region TEXT,
        league TEXT,
        team TEXT,
        team_id TEXT,
        weekly_meta TEXT
      )
    ''');

    // ユーザーデータテーブル
    await db.execute('''
      CREATE TABLE IF NOT EXISTS user_data (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // クイズ履歴テーブル
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

    // Weekly Recap同期履歴テーブル
    await db.execute('''
      CREATE TABLE IF NOT EXISTS recap_sync_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        league_type TEXT NOT NULL,
        synced_at TEXT NOT NULL,
        question_count INTEGER NOT NULL,
        UNIQUE(date, league_type)
      )
    ''');

    // インデックスの追加（パフォーマンス向上のため、IF NOT EXISTSを追加）
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
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_recap_sync_history_date ON recap_sync_history(date)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_recap_sync_history_league_type ON recap_sync_history(league_type)
    ''');

    // 初期ユーザーデータを挿入（既に存在する場合はスキップ）
    await db.insert(
      'user_data',
      {
        'key': 'total_points',
        'value': '0',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    
    await db.insert(
      'user_data',
      {
        'key': 'total_exp',
        'value': '0',
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    
    // EASY難易度を最初からアンロック
    final initialUnlocked = [
      UnlockKeyUtils.generateUnlockKey(
        category: AppConstants.categoryRules,
        difficulty: AppConstants.difficultyEasy,
        tags: AppConstants.categoryRules,
      ),
      UnlockKeyUtils.generateUnlockKey(
        category: AppConstants.categoryHistory,
        difficulty: AppConstants.difficultyEasy,
        tags: 'history,japan',
      ),
      UnlockKeyUtils.generateUnlockKey(
        category: AppConstants.categoryTeams,
        difficulty: AppConstants.difficultyEasy,
        tags: 'teams,japan',
      ),
    ];
    
    await db.insert(
      'user_data',
      {
        'key': 'unlocked_difficulties',
        'value': jsonEncode(initialUnlocked),
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    
    // match_day_play_historyテーブルを作成
    await db.execute('''
      CREATE TABLE IF NOT EXISTS match_day_play_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        week_start_date TEXT NOT NULL,
        play_date TEXT NOT NULL,
        play_count INTEGER NOT NULL DEFAULT 1,
        UNIQUE(week_start_date)
      )
    ''');
    
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_match_day_play_history_week_start_date ON match_day_play_history(week_start_date)
    ''');
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
    
    // バージョン2から3へのマイグレーション
    if (oldVersion < 3) {
      // reference_dateカラムを追加
      try {
        await db.execute('''
          ALTER TABLE questions ADD COLUMN reference_date TEXT
        ''');
        debugPrint('reference_dateカラムを追加しました');
      } catch (e) {
        debugPrint('reference_dateカラムの追加に失敗しました（既に存在する可能性があります）: $e');
      }
    }
    
    // バージョン3から4へのマイグレーション
    if (oldVersion < 4) {
      // recap_sync_historyテーブルの追加
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recap_sync_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          league_type TEXT NOT NULL,
          synced_at TEXT NOT NULL,
          question_count INTEGER NOT NULL,
          UNIQUE(date, league_type)
        )
      ''');
      
      // インデックスの追加
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_recap_sync_history_date ON recap_sync_history(date)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_recap_sync_history_league_type ON recap_sync_history(league_type)
      ''');
      debugPrint('recap_sync_historyテーブルを追加しました');
    }
    
    // バージョン4から5へのマイグレーション
    if (oldVersion < 5) {
      // total_expを追加（既存のtotal_pointsの値をコピー）
      final totalPointsResult = await db.query(
        'user_data',
        where: 'key = ?',
        whereArgs: ['total_points'],
      );
      int existingPoints = 0;
      if (totalPointsResult.isNotEmpty) {
        existingPoints = int.tryParse(totalPointsResult.first['value'] as String) ?? 0;
      }
      
      // total_expを追加
      await db.insert(
        'user_data',
        {
          'key': 'total_exp',
          'value': existingPoints.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // unlocked_difficultiesを追加（EASY難易度を最初からアンロック）
      final initialUnlocked = [
        UnlockKeyUtils.generateUnlockKey(
          category: AppConstants.categoryRules,
          difficulty: AppConstants.difficultyEasy,
          tags: AppConstants.categoryRules,
        ),
        UnlockKeyUtils.generateUnlockKey(
          category: AppConstants.categoryHistory,
          difficulty: AppConstants.difficultyEasy,
          tags: 'history,japan',
        ),
        UnlockKeyUtils.generateUnlockKey(
          category: AppConstants.categoryTeams,
          difficulty: AppConstants.difficultyEasy,
          tags: 'teams,japan',
        ),
      ];
      
      await db.insert(
        'user_data',
        {
          'key': 'unlocked_difficulties',
          'value': jsonEncode(initialUnlocked),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      // match_day_play_historyテーブルを追加（週単位のプレイ履歴管理）
      await db.execute('''
        CREATE TABLE IF NOT EXISTS match_day_play_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          week_start_date TEXT NOT NULL,
          play_date TEXT NOT NULL,
          play_count INTEGER NOT NULL DEFAULT 1,
          UNIQUE(week_start_date)
        )
      ''');
      
      // インデックスの追加
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_match_day_play_history_week_start_date ON match_day_play_history(week_start_date)
      ''');
      
      debugPrint('バージョン5へのマイグレーション完了: total_expとunlocked_difficultiesを追加しました');
    }
    
    // バージョン5から6へのマイグレーション
    if (oldVersion < 6) {
      // 新しいスキーマのカラムを追加
      try {
        await db.execute('''
          ALTER TABLE questions ADD COLUMN quiz_type TEXT
        ''');
        debugPrint('quiz_typeカラムを追加しました');
      } catch (e) {
        debugPrint('quiz_typeカラムの追加に失敗しました（既に存在する可能性があります）: $e');
      }
      
      try {
        await db.execute('''
          ALTER TABLE questions ADD COLUMN category_id TEXT
        ''');
        debugPrint('category_idカラムを追加しました');
      } catch (e) {
        debugPrint('category_idカラムの追加に失敗しました（既に存在する可能性があります）: $e');
      }
      
      try {
        await db.execute('''
          ALTER TABLE questions ADD COLUMN region TEXT
        ''');
        debugPrint('regionカラムを追加しました');
      } catch (e) {
        debugPrint('regionカラムの追加に失敗しました（既に存在する可能性があります）: $e');
      }
      
      try {
        await db.execute('''
          ALTER TABLE questions ADD COLUMN league TEXT
        ''');
        debugPrint('leagueカラムを追加しました');
      } catch (e) {
        debugPrint('leagueカラムの追加に失敗しました（既に存在する可能性があります）: $e');
      }
      
      try {
        await db.execute('''
          ALTER TABLE questions ADD COLUMN team TEXT
        ''');
        debugPrint('teamカラムを追加しました');
      } catch (e) {
        debugPrint('teamカラムの追加に失敗しました（既に存在する可能性があります）: $e');
      }
      
      try {
        await db.execute('''
          ALTER TABLE questions ADD COLUMN team_id TEXT
        ''');
        debugPrint('team_idカラムを追加しました');
      } catch (e) {
        debugPrint('team_idカラムの追加に失敗しました（既に存在する可能性があります）: $e');
      }
      
      try {
        await db.execute('''
          ALTER TABLE questions ADD COLUMN weekly_meta TEXT
        ''');
        debugPrint('weekly_metaカラムを追加しました');
      } catch (e) {
        debugPrint('weekly_metaカラムの追加に失敗しました（既に存在する可能性があります）: $e');
      }
      
      debugPrint('バージョン6へのマイグレーション完了: 新しいスキーマのカラムを追加しました');
    }
    
    // バージョン6から7へのマイグレーション
    if (oldVersion < 7) {
      debugPrint('バージョン7へのマイグレーション開始: questionsテーブルを再作成してアセットからデータを読み込みます');
      
      // questionsテーブルを削除して再作成（アセットから新しいデータを読み込むため）
      await db.execute('DROP TABLE IF EXISTS questions');
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
          tags TEXT NOT NULL,
          reference_date TEXT,
          quiz_type TEXT,
          category_id TEXT,
          region TEXT,
          league TEXT,
          team TEXT,
          team_id TEXT,
          weekly_meta TEXT
        )
      ''');
      
      // インデックスを再作成
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_questions_category_difficulty ON questions(category, difficulty)
      ''');
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_questions_tags ON questions(tags)
      ''');
      
      debugPrint('バージョン7へのマイグレーション完了: questionsテーブルを再作成しました');
      debugPrint('注意: アセットからデータベースをコピーするには、アプリを再起動してください');
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
        'reference_date': question.referenceDate,
        'quiz_type': question.quizType,
        'category_id': question.categoryId,
        'region': question.region,
        'league': question.league,
        'team': question.team,
        'team_id': question.teamId,
        'weekly_meta': question.weeklyMeta,
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
          'reference_date': question.referenceDate,
          'quiz_type': question.quizType,
          'category_id': question.categoryId,
          'region': question.region,
          'league': question.league,
          'team': question.team,
          'team_id': question.teamId,
          'weekly_meta': question.weeklyMeta,
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
    String? region,
    String? team,
    int? limit,
    List<String>? excludeIds,
    // 後方互換性のため（非推奨: teamパラメータを使用してください）
    String? range,
  }) async {
    // 後方互換性: rangeパラメータが指定されている場合はteamに変換
    final teamParam = team ?? range;
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

    // tagsパラメータによるフィルタリングは削除
    // regionフィールドとteam_idフィールドで検索するため、tagsでのフィルタリングは不要

    // 地域によるフィルタリング（regionフィールドを使用）
    // regionが指定されている場合はそれを優先し、指定されていない場合はcountryを使用
    final regionParam = region ?? country;
    if (regionParam != null && regionParam.isNotEmpty) {
      query += ' AND region = ?';
      args.add(regionParam);
    }

    // チームによるフィルタリング
    if (teamParam != null && teamParam.isNotEmpty) {
      if (teamParam == 'j1全チーム' || teamParam == 'j1_all_teams') {
        // J1全チーム: japanタグとj1タグを含む
        query += ' AND tags LIKE ? AND tags LIKE ?';
        args.add('%japan%');
        args.add('%j1%');
      } else if (teamParam == 'j2全チーム' || teamParam == 'j2_all_teams') {
        // J2全チーム: japanタグとj2タグを含む
        query += ' AND tags LIKE ? AND tags LIKE ?';
        args.add('%japan%');
        args.add('%j2%');
      } else if (teamParam == '海外top3' || teamParam == 'overseas_top3') {
        // 海外Top3: イタリア、スペイン、イングランドのいずれか
        query += ' AND (tags LIKE ? OR tags LIKE ? OR tags LIKE ?)';
        args.add('%italy%');
        args.add('%spain%');
        args.add('%england%');
      } else {
        // チームIDへの変換（設定画面の値やチーム名からteam_idに変換）
        final teamId = _convertRangeToTeamId(teamParam);
        
        // デバッグログ（一時的）
        debugPrint('チーム検索: teamParam=$teamParam, teamId=$teamId');
        
        // team_idフィールドで直接検索（最も確実）
        // データベースにはteam_idフィールドに値が設定されているため、これで確実にマッチする
        query += ' AND team_id = ?';
        args.add(teamId);
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

    // デバッグログ（一時的）
    debugPrint('SQLクエリ: $query');
    debugPrint('SQL引数: $args');

    maps = await db.rawQuery(query, args);
    
    // デバッグログ（一時的）
    debugPrint('取得した問題数: ${maps.length}');

    return maps.map((map) => _mapToQuestion(map)).toList();
  }

  /// 改善されたクイズ問題取得（重複回避、難易度バランス調整、テーマ多様性確保）
  Future<List<Question>> getQuestionsOptimized({
    String? category,
    String? difficulty,
    String? tags,
    String? country,
    String? region,
    String? team,
    int? limit,
    List<String>? excludeIds,
    bool balanceDifficulty = false,
    // 後方互換性のため（非推奨: teamパラメータを使用してください）
    String? range,
  }) async {
    // 後方互換性: rangeパラメータが指定されている場合はteamに変換
    final teamParam = team ?? range;
    
    final requestedLimit = limit ?? AppConstants.defaultQuestionsPerQuiz;
    
    // 難易度バランス調整が有効な場合
    if (balanceDifficulty && difficulty == null) {
      final balancedQuestions = await _getQuestionsWithDifficultyBalance(
        category: category,
        country: country,
        region: region,
        team: teamParam,
        limit: requestedLimit,
        excludeIds: excludeIds,
      );
      // テーマの多様性を確保
      return _ensureThemeDiversity(balancedQuestions);
    }

    // 通常の取得（重複回避付き）
    final questions = await getQuestions(
      category: category,
      difficulty: difficulty,
      tags: tags,
      country: country,
      region: region,
      team: teamParam,
      limit: requestedLimit * 3, // より多く取得してテーマ多様性を確保
      excludeIds: excludeIds,
    );

    // ランダム性を向上させるため、取得した問題をシャッフル
    questions.shuffle();

    // テーマの多様性を確保しながら、指定された数だけ返す
    final diverseQuestions = _ensureThemeDiversity(questions);
    return diverseQuestions.take(requestedLimit).toList();
  }

  /// 難易度バランスを考慮した問題取得
  Future<List<Question>> _getQuestionsWithDifficultyBalance({
    String? category,
    String? country,
    String? region,
    String? team,
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
        tags: null, // tagsパラメータは使用しない
        country: country,
        region: region,
        team: team,
        limit: questionsPerDifficulty * 2, // 余分に取得
        excludeIds: excludeIds,
      );
      balancedQuestions.addAll(questions);
    }

    // シャッフルしてランダム性を向上
    balancedQuestions.shuffle();
    return balancedQuestions;
  }

  /// 設定画面の値やチーム名をteamIdに変換（検索用）
  /// rangeパラメータ（設定画面の値）やチーム名からteam_idに変換
  static String _convertRangeToTeamId(String rangeValue) {
    // 設定画面で使用される値からteam_idへのマッピング
    final rangeToTeamIdMap = {
      // J1リーグ
      'kashiwa_reysol': 'kashiwa',
      'kashima_antlers': 'kashima',
      'kyoto_sanga': 'kyoto',
      'sanfrecce_hiroshima': 'sanfrecce',
      'vissel_kobe': 'vissel',
      'machida_zelvia': 'machida',
      'urawa_reds': 'urawa',
      'kawasaki_frontale': 'kawasaki',
      'gamba_osaka': 'gamba',
      'cerezo_osaka': 'cerezo',
      'fc_tokyo': 'fc_tokyo',
      'avispa_fukuoka': 'avispa',
      'fagiano_okayama': 'fagiano',
      'shimizu_s_pulse': 'shimizu',
      'yokohama_f_marinos': 'yokohama',
      'nagoya_grampus': 'nagoya',
      'tokyo_verdy': 'verdy',
      'mito_hollyhock': 'mito',
      'v_varen_nagasaki': 'v_varen',
      'jef_united_chiba': 'jef_chiba',
      // 海外リーグ
      'juventus': 'juventus',
      'ac_milan': 'ac_milan',
      'inter_milan': 'inter_milan',
      'real_madrid': 'real_madrid',
      'barcelona': 'barcelona',
      'atletico_madrid': 'atletico_madrid',
      'liverpool': 'liverpool',
      'arsenal': 'arsenal',
      'manchester_city': 'manchester_city',
      'manchester_united': 'manchester_united',
      'chelsea': 'chelsea',
    };
    
    // 設定画面の値がマッピングにある場合はそれを返す
    if (rangeToTeamIdMap.containsKey(rangeValue)) {
      return rangeToTeamIdMap[rangeValue]!;
    }
    
    // チーム名とteamIdのマッピング（JSONファイルの実際のteamIdに合わせる）
    final teamNameToIdMap = {
      '柏レイソル': 'kashiwa',
      '鹿島アントラーズ': 'kashima',
      '京都サンガF.C.': 'kyoto',
      'サンフレッチェ広島': 'sanfrecce',
      'ヴィッセル神戸': 'vissel',
      'FC町田ゼルビア': 'machida',
      '浦和レッズ': 'urawa',
      '川崎フロンターレ': 'kawasaki',
      'ガンバ大阪': 'gamba',
      'セレッソ大阪': 'cerezo',
      'FC東京': 'fc_tokyo',
      'アビスパ福岡': 'avispa',
      'ファジアーノ岡山': 'fagiano',
      '清水エスパルス': 'shimizu',
      '横浜F・マリノス': 'yokohama',
      '名古屋グランパス': 'nagoya',
      '東京ヴェルディ': 'verdy',
    };
    
    // チーム名がマッピングにある場合はそれを返す
    if (teamNameToIdMap.containsKey(rangeValue)) {
      return teamNameToIdMap[rangeValue]!;
    }
    
    // 既にteam_id形式の場合はそのまま返す
    // それ以外の場合は小文字に変換してアンダースコアに置換
    return rangeValue.toLowerCase().replaceAll(' ', '_');
  }

  String _extractThemeKeyword(String text) {
    // 問題文の最初の30文字をテーマキーワードとして使用
    // 句読点や記号を除去して、主要なキーワードを抽出
    final prefix = text.length > 30 ? text.substring(0, 30) : text;
    
    // カテゴリ別のキーワード抽出パターン
    final keywords = <String>[];
    
    // ルール関連のキーワード
    if (prefix.contains('オフサイド') || prefix.contains('オフサイド')) {
      keywords.add('オフサイド');
    }
    if (prefix.contains('ファウル') || prefix.contains('反則')) {
      keywords.add('ファウル');
    }
    if (prefix.contains('イエローカード') || prefix.contains('警告')) {
      keywords.add('イエローカード');
    }
    if (prefix.contains('レッドカード') || prefix.contains('退場')) {
      keywords.add('レッドカード');
    }
    if (prefix.contains('スローイン')) {
      keywords.add('スローイン');
    }
    if (prefix.contains('コーナーキック') || prefix.contains('コーナー')) {
      keywords.add('コーナーキック');
    }
    if (prefix.contains('PK') || prefix.contains('ペナルティ') || prefix.contains('PK戦')) {
      keywords.add('PK');
    }
    if (prefix.contains('VAR') || prefix.contains('ビデオ判定')) {
      keywords.add('VAR');
    }
    if (prefix.contains('延長戦') || prefix.contains('延長')) {
      keywords.add('延長戦');
    }
    
    // チーム名や選手名を抽出（最初の名詞を取得）
    if (keywords.isEmpty) {
      // 問題文の最初の部分から主要なキーワードを抽出
      final words = prefix.split(RegExp(r'[、。？\s]'));
      if (words.isNotEmpty) {
        final firstWord = words.first.trim();
        if (firstWord.length > 2) {
          keywords.add(firstWord);
        }
      }
    }
    
    return keywords.isNotEmpty ? keywords.first : prefix.substring(0, prefix.length > 20 ? 20 : prefix.length);
  }

  /// 2つの問題が類似しているかを判定
  bool _areQuestionsSimilar(Question q1, Question q2) {
    final theme1 = _extractThemeKeyword(q1.text);
    final theme2 = _extractThemeKeyword(q2.text);
    
    // 完全一致または部分一致をチェック
    if (theme1 == theme2) return true;
    
    // 一方がもう一方を含む場合も類似と判定
    if (theme1.length > 5 && theme2.length > 5) {
      if (theme1.contains(theme2) || theme2.contains(theme1)) {
        return true;
      }
    }
    
    // 問題文の最初の20文字が50%以上一致する場合も類似と判定
    final text1 = q1.text.length > 20 ? q1.text.substring(0, 20) : q1.text;
    final text2 = q2.text.length > 20 ? q2.text.substring(0, 20) : q2.text;
    
    int matches = 0;
    final minLength = text1.length < text2.length ? text1.length : text2.length;
    for (int i = 0; i < minLength; i++) {
      if (text1[i] == text2[i]) matches++;
    }
    
    final similarity = matches / minLength;
    return similarity > 0.5;
  }

  /// テーマの多様性を確保して問題を並び替え
  List<Question> _ensureThemeDiversity(List<Question> questions) {
    if (questions.length <= 1) return questions;
    
    final List<Question> result = [];
    final List<Question> remaining = List.from(questions);
    
    // 最初の問題をランダムに選択
    remaining.shuffle();
    if (remaining.isNotEmpty) {
      result.add(remaining.removeAt(0));
    }
    
    // 残りの問題を、直前の問題と異なるテーマのものを優先的に選択
    while (remaining.isNotEmpty && result.length < questions.length) {
      Question? selectedQuestion;
      int selectedIndex = -1;
      
      // 直前の問題と異なるテーマの問題を探す
      for (int i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];
        final lastQuestion = result.last;
        
        // 直前の問題と類似していない場合
        if (!_areQuestionsSimilar(candidate, lastQuestion)) {
          selectedQuestion = candidate;
          selectedIndex = i;
          break;
        }
      }
      
      // 異なるテーマの問題が見つからない場合、ランダムに選択
      if (selectedQuestion == null) {
        selectedIndex = 0;
        selectedQuestion = remaining[selectedIndex];
      }
      
      result.add(selectedQuestion);
      remaining.removeAt(selectedIndex);
    }
    
    return result;
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
      referenceDate: map['reference_date'] as String?,
      quizType: map['quiz_type'] as String?,
      categoryId: map['category_id'] as String?,
      region: map['region'] as String?,
      league: map['league'] as String?,
      team: map['team'] as String?,
      teamId: map['team_id'] as String?,
      weeklyMeta: map['weekly_meta'] as String?,
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

  /// ユーザーの累計経験値（exp）を取得
  Future<int> getTotalExp() async {
    final db = await database;
    final result = await db.query(
      'user_data',
      where: 'key = ?',
      whereArgs: ['total_exp'],
    );
    if (result.isEmpty) {
      return 0;
    }
    return int.tryParse(result.first['value'] as String) ?? 0;
  }

  /// ユーザーの累計経験値（exp）を更新
  Future<void> updateTotalExp(int exp) async {
    final db = await database;
    await db.update(
      'user_data',
      {'value': exp.toString()},
      where: 'key = ?',
      whereArgs: ['total_exp'],
    );
  }

  /// 経験値（exp）を追加
  Future<void> addExp(int exp) async {
    final currentExp = await getTotalExp();
    await updateTotalExp(currentExp + exp);
  }

  /// アンロック済み難易度のリストを取得
  Future<List<String>> getUnlockedDifficulties() async {
    final db = await database;
    final result = await db.query(
      'user_data',
      where: 'key = ?',
      whereArgs: ['unlocked_difficulties'],
    );
    if (result.isEmpty) {
      return [];
    }
    try {
      final jsonString = result.first['value'] as String;
      if (jsonString.isEmpty || jsonString == '[]') {
        return [];
      }
      // JSON配列をパース
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('アンロック済み難易度のパースに失敗しました: $e');
      return [];
    }
  }

  /// アンロック済み難易度のリストを更新
  Future<void> updateUnlockedDifficulties(List<String> unlockedKeys) async {
    final db = await database;
    final jsonString = jsonEncode(unlockedKeys);
    await db.update(
      'user_data',
      {'value': jsonString},
      where: 'key = ?',
      whereArgs: ['unlocked_difficulties'],
    );
  }

  /// 難易度をアンロック
  Future<void> unlockDifficulty(String unlockKey) async {
    final unlocked = await getUnlockedDifficulties();
    if (!unlocked.contains(unlockKey)) {
      unlocked.add(unlockKey);
      await updateUnlockedDifficulties(unlocked);
    }
  }

  /// 難易度がアンロックされているかチェック
  Future<bool> isDifficultyUnlocked(String unlockKey) async {
    final unlocked = await getUnlockedDifficulties();
    return unlocked.contains(unlockKey);
  }

  /// 今週の週開始日を取得（月曜日を週の開始とする）
  String _getWeekStartDate(DateTime date) {
    // 月曜日を週の開始とする（月曜日=1、日曜日=7）
    final weekday = date.weekday;
    final daysFromMonday = weekday == 7 ? 0 : weekday - 1;
    final weekStart = date.subtract(Duration(days: daysFromMonday));
    return '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
  }

  /// MATCH DAYをプレイ可能かチェック（週1回制限）
  Future<bool> canPlayMatchDay() async {
    final db = await database;
    final now = DateTime.now();
    final weekStartDate = _getWeekStartDate(now);
    
    final result = await db.query(
      'match_day_play_history',
      where: 'week_start_date = ?',
      whereArgs: [weekStartDate],
    );
    
    // 今週のプレイ履歴がない場合、プレイ可能
    if (result.isEmpty) {
      return true;
    }
    
    // 今週のプレイ回数を取得
    final playCount = result.first['play_count'] as int;
    // 無料で1回、広告視聴で最大3回まで（合計4回まで）
    return playCount < 4;
  }

  /// MATCH DAYのプレイ回数を取得（今週）
  Future<int> getMatchDayPlayCount() async {
    final db = await database;
    final now = DateTime.now();
    final weekStartDate = _getWeekStartDate(now);
    
    final result = await db.query(
      'match_day_play_history',
      where: 'week_start_date = ?',
      whereArgs: [weekStartDate],
    );
    
    if (result.isEmpty) {
      return 0;
    }
    
    return result.first['play_count'] as int;
  }

  /// MATCH DAYのプレイを記録
  Future<void> recordMatchDayPlay() async {
    final db = await database;
    final now = DateTime.now();
    final weekStartDate = _getWeekStartDate(now);
    final playDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final existing = await db.query(
      'match_day_play_history',
      where: 'week_start_date = ?',
      whereArgs: [weekStartDate],
    );
    
    if (existing.isEmpty) {
      // 今週初めてのプレイ
      await db.insert(
        'match_day_play_history',
        {
          'week_start_date': weekStartDate,
          'play_date': playDate,
          'play_count': 1,
        },
      );
    } else {
      // 今週のプレイ回数を増やす
      final currentCount = existing.first['play_count'] as int;
      await db.update(
        'match_day_play_history',
        {
          'play_date': playDate,
          'play_count': currentCount + 1,
        },
        where: 'week_start_date = ?',
        whereArgs: [weekStartDate],
      );
    }
  }

  /// Weekly Recap同期履歴を記録
  Future<void> recordRecapSync({
    required String date,
    required String leagueType,
    required int questionCount,
  }) async {
    final db = await database;
    await db.insert(
      'recap_sync_history',
      {
        'date': date,
        'league_type': leagueType,
        'synced_at': DateTime.now().toIso8601String(),
        'question_count': questionCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 指定日付とリーグタイプのWeekly Recapが既に同期済みかチェック
  Future<bool> isRecapSynced({
    required String date,
    required String leagueType,
  }) async {
    final db = await database;
    final result = await db.query(
      'recap_sync_history',
      where: 'date = ? AND league_type = ?',
      whereArgs: [date, leagueType],
    );
    return result.isNotEmpty;
  }

  /// 同期済みの日付とリーグタイプのペアを取得
  Future<List<Map<String, dynamic>>> getSyncedRecapDates() async {
    final db = await database;
    return await db.query(
      'recap_sync_history',
      columns: ['date', 'league_type', 'synced_at', 'question_count'],
      orderBy: 'date DESC, league_type ASC',
    );
  }

  /// データベースを閉じる
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
