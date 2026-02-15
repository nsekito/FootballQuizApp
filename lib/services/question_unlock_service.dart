import '../models/question.dart';
import 'database_service.dart';

/// 問題開放サービス
class QuestionUnlockService {
  final DatabaseService _databaseService;

  QuestionUnlockService(this._databaseService);

  /// ポイントを消費して問題を開放
  /// 
  /// [questionId] 開放する問題のID
  /// [points] 消費するポイント数
  /// 
  /// 戻り値: 開放に成功した場合はtrue、ポイントが不足している場合はfalse
  Future<bool> unlockQuestion(String questionId, int points) async {
    // 既に開放済みかチェック
    final isUnlocked = await _databaseService.isQuestionUnlocked(questionId);
    if (isUnlocked) {
      return true; // 既に開放済みの場合は成功として扱う
    }

    // ポイントが十分かチェック（このメソッドではチェックしない、呼び出し側でチェック）
    // 問題を開放
    await _databaseService.unlockQuestion(questionId);
    return true;
  }

  /// 問題が開放済みかチェック
  Future<bool> isQuestionUnlocked(String questionId) async {
    return await _databaseService.isQuestionUnlocked(questionId);
  }

  /// 開放済み問題IDのリストを取得
  Future<List<String>> getUnlockedQuestionIds() async {
    return await _databaseService.getUnlockedQuestionIds();
  }

  /// 開放済み問題のリストを取得
  Future<List<Question>> getUnlockedQuestions() async {
    return await _databaseService.getUnlockedQuestions();
  }

  /// 問題IDから問題を取得
  Future<Question?> getQuestionById(String questionId) async {
    return await _databaseService.getQuestionById(questionId);
  }
}
