import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/question_unlock_service.dart';
import '../models/question.dart';
import '../providers/user_data_provider.dart';
import '../utils/constants.dart';
import '../constants/gameConfig.dart';
import 'database_provider.dart';

/// 問題開放サービスプロバイダー
final questionUnlockServiceProvider = Provider<QuestionUnlockService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return QuestionUnlockService(databaseService);
});

/// 開放済み問題IDのリストを管理するプロバイダー
final unlockedQuestionIdsProvider = FutureProvider<List<String>>((ref) async {
  final unlockService = ref.watch(questionUnlockServiceProvider);
  return await unlockService.getUnlockedQuestionIds();
});

/// 開放済み問題のリストを管理するプロバイダー
final unlockedQuestionsProvider = FutureProvider<List<Question>>((ref) async {
  final unlockService = ref.watch(questionUnlockServiceProvider);
  return await unlockService.getUnlockedQuestions();
});

/// 問題IDから問題を取得するプロバイダー
final questionByIdProvider = FutureProvider.family<Question?, String>((ref, questionId) async {
  final unlockService = ref.watch(questionUnlockServiceProvider);
  return await unlockService.getQuestionById(questionId);
});

/// 問題開放処理を実行するプロバイダー
final unlockQuestionProvider = FutureProvider.family<bool, String>((ref, questionId) async {
  final unlockService = ref.watch(questionUnlockServiceProvider);
  final totalPoints = ref.watch(totalPointsProvider);
  
  // ポイントが十分かチェック
  if (totalPoints < HISTORY_UNLOCK.singleQuestionCost) {
    throw Exception('ポイントが不足しています。${HISTORY_UNLOCK.singleQuestionCost}ポイント必要です。');
  }
  
  // ポイントを消費
  await ref.read(totalPointsProvider.notifier).consumePoints(HISTORY_UNLOCK.singleQuestionCost);
  
  // 問題を開放
  final success = await unlockService.unlockQuestion(questionId, HISTORY_UNLOCK.singleQuestionCost);
  
  // 開放済み問題リストを更新
  ref.invalidate(unlockedQuestionIdsProvider);
  ref.invalidate(unlockedQuestionsProvider);
  
  return success;
});

/// 問題解放をリセットするプロバイダー
final resetUnlockedQuestionsProvider = FutureProvider<void>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  await databaseService.resetUnlockedQuestions();
  // 開放済み問題リストを更新
  ref.invalidate(unlockedQuestionIdsProvider);
  ref.invalidate(unlockedQuestionsProvider);
});
