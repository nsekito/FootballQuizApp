import 'dart:math';
import '../models/question.dart';

/// 問題処理ユーティリティ
/// すべてのクイズ画面で共通のロジックを提供
class QuestionUtils {
  /// 管理者モードに応じて問題を処理
  /// 
  /// [questions] 処理する問題のリスト
  /// [adminMode] 管理者モードがONかどうか
  /// 
  /// 戻り値: 処理済みの問題のリスト
  /// - 管理者モードON: answerIndexを0に強制設定（先頭が正解）
  /// - 管理者モードOFF: 選択肢をシャッフル
  static List<Question> processQuestionsForAdminMode(
    List<Question> questions,
    bool adminMode,
  ) {
    if (adminMode) {
      return questions.map((q) => ensureAnswerIndexZero(q)).toList();
    } else {
      return questions.map((q) => shuffleQuestionOptions(q)).toList();
    }
  }

  /// 管理者モード時：answerIndexを0に強制設定（先頭が正解になるように）
  /// 
  /// [question] 処理する問題
  /// 
  /// 戻り値: answerIndexが0に設定された問題（既に0の場合はそのまま返す）
  static Question ensureAnswerIndexZero(Question question) {
    if (question.answerIndex == 0) {
      // 既に0の場合はそのまま返す
      return question;
    }

    // 正解の選択肢を取得
    final correctAnswer = question.options[question.answerIndex];

    // 選択肢を再配置：正解を先頭に移動
    final newOptions = <String>[
      correctAnswer,
      ...question.options.where((opt) => opt != correctAnswer),
    ];

    // 新しいQuestionオブジェクトを作成（answerIndexを0に設定）
    return Question(
      id: question.id,
      text: question.text,
      options: newOptions,
      answerIndex: 0, // 強制的に0に設定
      explanation: question.explanation,
      trivia: question.trivia,
      category: question.category,
      difficulty: question.difficulty,
      tags: question.tags,
      referenceDate: question.referenceDate,
      quizType: question.quizType,
      categoryId: question.categoryId,
      region: question.region,
      league: question.league,
      team: question.team,
      teamId: question.teamId,
      weeklyMeta: question.weeklyMeta,
    );
  }

  /// 問題の選択肢をシャッフルし、answerIndexを更新する
  /// 
  /// [question] 処理する問題
  /// 
  /// 戻り値: 選択肢がシャッフルされた問題（選択肢が4つでない場合はそのまま返す）
  static Question shuffleQuestionOptions(Question question) {
    if (question.options.length != 4) {
      // 選択肢が4つでない場合はそのまま返す
      return question;
    }

    // 正解の選択肢を取得
    final correctAnswer = question.options[question.answerIndex];

    // 正解以外の選択肢をシャッフル
    final otherOptions = List<String>.from(question.options);
    otherOptions.removeAt(question.answerIndex);
    otherOptions.shuffle();

    // ランダムな位置に正解を挿入
    final random = Random();
    final newIndex = random.nextInt(4);
    otherOptions.insert(newIndex, correctAnswer);

    // 新しいQuestionオブジェクトを作成
    return Question(
      id: question.id,
      text: question.text,
      options: otherOptions,
      answerIndex: newIndex,
      explanation: question.explanation,
      trivia: question.trivia,
      category: question.category,
      difficulty: question.difficulty,
      tags: question.tags,
      referenceDate: question.referenceDate,
      quizType: question.quizType,
      categoryId: question.categoryId,
      region: question.region,
      league: question.league,
      team: question.team,
      teamId: question.teamId,
      weeklyMeta: question.weeklyMeta,
    );
  }
}
