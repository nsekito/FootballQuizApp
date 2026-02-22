import '../constants/gameConfig.dart';
import '../providers/user_data_provider.dart';
import '../utils/unlock_key_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 昇格試験サービス
/// 昇格試験のビジネスロジックを集約
class PromotionExamService {
  final Ref _ref;

  PromotionExamService(this._ref);

  /// カテゴリ名をUNLOCK_CONFIGのキーに変換
  String _getCategoryKey(String category) {
    switch (category.toUpperCase()) {
      case 'RULES':
        return 'rule';
      case 'HISTORY':
        return 'history';
      case 'TEAMS':
        return 'team';
      default:
        return 'rule';
    }
  }

  /// 昇格試験の設定を取得
  UnlockDifficultyConfig? getExamConfig({
    required String category,
    required String targetDifficulty,
  }) {
    final categoryKey = _getCategoryKey(category);
    final difficultyUpper = targetDifficulty.toUpperCase();
    
    if (!UNLOCK_CONFIG.containsKey(difficultyUpper)) {
      return null;
    }
    
    final categoryConfig = UNLOCK_CONFIG[difficultyUpper]!;
    switch (categoryKey) {
      case 'rule':
        return categoryConfig.rule;
      case 'history':
        return categoryConfig.history;
      case 'team':
        return categoryConfig.team;
      default:
        return categoryConfig.rule;
    }
  }

  /// ランク条件を満たしているかチェック
  bool checkRankRequirement(int requiredRank, int currentRankIndex) {
    // RANKS配列のインデックスで比較（1ベースのrankから0ベースのインデックスに変換）
    return currentRankIndex >= (requiredRank - 1);
  }

  /// PTを仮徴収（確定するまで保留）
  Future<bool> reservePoints(int points) async {
    final currentPoints = _ref.read(totalPointsProvider);
    if (currentPoints < points) {
      return false;
    }
    // 仮徴収は実際にはポイントを減らさず、結果画面で確定する
    return true;
  }

  /// 合格時の処理
  Future<void> handlePass({
    required String category,
    required String targetDifficulty,
    required String tags,
    required int reservedPoints,
  }) async {
    final config = getExamConfig(
      category: category,
      targetDifficulty: targetDifficulty,
    );
    
    if (config == null) return;

    // PTを確定消費
    await _ref.read(totalPointsProvider.notifier).consumePoints(reservedPoints);
    
    // bonusExpとbonusPtを付与
    await _ref.read(totalExpProvider.notifier).addExp(config.bonusExp);
    await _ref.read(totalPointsProvider.notifier).addPoints(config.bonusPt);
    
    // 難易度をアンロック
    final unlockKey = UnlockKeyUtils.generateUnlockKey(
      category: category,
      difficulty: targetDifficulty,
      tags: tags,
    );
    await _ref.read(unlockedDifficultiesProvider.notifier).unlockDifficulty(unlockKey);
  }

  /// 不合格時の処理
  Future<void> handleFail({
    required String category,
    required String targetDifficulty,
    required int reservedPoints,
    required bool watchedAd,
  }) async {
    final config = getExamConfig(
      category: category,
      targetDifficulty: targetDifficulty,
    );
    
    if (config == null) return;

    // forfeit分のPTを没収
    await _ref.read(totalPointsProvider.notifier).consumePoints(config.forfeit);
    
    // 残り（cost - forfeit）をユーザーに返還
    final refund = reservedPoints - config.forfeit;
    if (refund > 0) {
      await _ref.read(totalPointsProvider.notifier).addPoints(refund);
    }
  }

  /// 再挑戦コストを計算（広告視聴時は割引）
  int calculateRetryCost({
    required String category,
    required String targetDifficulty,
    required bool watchedAd,
  }) {
    final config = getExamConfig(
      category: category,
      targetDifficulty: targetDifficulty,
    );
    
    if (config == null) return 0;

    var retryCost = config.retryCost;
    
    // 広告視聴時は割引
    if (watchedAd) {
      retryCost = (retryCost * AD_BONUS.promotionExamRetryDiscount).floor();
    }
    
    return retryCost;
  }
}

/// 昇格試験サービスのプロバイダー
final promotionExamServiceProvider = Provider<PromotionExamService>((ref) {
  return PromotionExamService(ref);
});
