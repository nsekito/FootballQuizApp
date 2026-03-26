import '../constants/game_config.dart';
import '../providers/user_data_provider.dart';
import '../utils/unlock_key_utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 昇格試験サービス
/// 昇格試験のビジネスロジックを集約
class PromotionExamService {
  final Ref _ref;

  PromotionExamService(this._ref);

  /// カテゴリ名をunlockConfigのキーに変換
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
    
    if (!unlockConfig.containsKey(difficultyUpper)) {
      return null;
    }
    
    final categoryConfig = unlockConfig[difficultyUpper]!;
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
    // ranks配列のインデックスで比較（1ベースのrankから0ベースのインデックスに変換）
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
  }) async {
    final config = getExamConfig(
      category: category,
      targetDifficulty: targetDifficulty,
    );
    
    if (config == null) return;

    // 参加費はクイズ開始前にウォレットからは引いていないため、不合格時は没収分のみを差し引く
    // （旧: 返還 addPoints をすると consume と相殺され実質没収にならない）
    await _ref.read(totalPointsProvider.notifier).consumePoints(config.forfeit);
  }

  /// 不合格時リワード広告でキャッシュバックするPT（没収分に対する割合は [adBonus.promotionExamFailCashbackRatio]）
  int calculateFailForfeitCashback({
    required String category,
    required String targetDifficulty,
  }) {
    final config = getExamConfig(
      category: category,
      targetDifficulty: targetDifficulty,
    );
    if (config == null) return 0;
    return (config.forfeit * adBonus.promotionExamFailCashbackRatio).floor();
  }

  /// 不合格時リワードのキャッシュバックを付与
  Future<void> grantFailCashbackFromAd({
    required String category,
    required String targetDifficulty,
  }) async {
    final amount = calculateFailForfeitCashback(
      category: category,
      targetDifficulty: targetDifficulty,
    );
    if (amount <= 0) return;
    await _ref.read(totalPointsProvider.notifier).addPoints(amount);
  }
}

/// 昇格試験サービスのプロバイダー
final promotionExamServiceProvider = Provider<PromotionExamService>((ref) {
  return PromotionExamService(ref);
});
