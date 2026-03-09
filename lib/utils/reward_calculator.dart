import 'dart:math' as math;
import '../constants/game_config.dart';

/// 報酬計算ユーティリティ
/// すべての報酬計算はこのクラスを通じて行う
class RewardCalculator {
  /// 正答数(0-10)を報酬区分に変換
  /// 0-3問 → '0-3'
  /// 4-5問 → '4-5'
  /// 6-7問 → '6-7'
  /// 8-9問 → '8-9'
  /// 10問 → '10'
  static String getRewardTier(int correctCount) {
    if (correctCount >= 10) {
      return '10';
    } else if (correctCount >= 8) {
      return '8-9';
    } else if (correctCount >= 6) {
      return '6-7';
    } else if (correctCount >= 4) {
      return '4-5';
    } else {
      return '0-3';
    }
  }

  /// matchDay報酬を計算
  /// 
  /// [correctCount] 正答数(0-10)
  /// [playCount] 今週のプレイ回数(1-3)
  /// [watchedAd] 広告視聴したかどうか
  /// [weeklyCorrectTotal] 今週の合計正答数
  /// 
  /// 戻り値: (exp, pt) のタプル
  static (int exp, int pt) calculateMatchDayReward({
    required int correctCount,
    required int playCount,
    required bool watchedAd,
    required int weeklyCorrectTotal,
  }) {
    // 1. quizRewards.matchDayから正答数区分に対応するbase報酬を取得
    final tier = getRewardTier(correctCount);
    final baseReward = quizRewards['matchDay']!.rewards[tier]!;
    var exp = baseReward.exp;
    var pt = baseReward.pt;

    // 2. matchDay.PLAY_MULTIPLIERS[playCount - 1]を乗算（小数点以下切り捨て）
    if (playCount >= 1 && playCount <= matchDay.playMultipliers.length) {
      final multiplier = matchDay.playMultipliers[playCount - 1];
      exp = math.max(0, (exp * multiplier).floor());
      pt = math.max(0, (pt * multiplier).floor());
    }

    // 3. 広告視聴した場合は上記結果にadBonus.RESULT_SCREEN_MULTIPLIERを乗算して加算（小数点以下切り捨て）
    if (watchedAd) {
      final adBonusExp = math.max(0, (exp * adBonus.resultScreenMultiplier).floor());
      final adBonusPt = math.max(0, (pt * adBonus.resultScreenMultiplier).floor());
      exp += adBonusExp;
      pt += adBonusPt;
    }

    // 4. 週3回プレイかつ合計正答数が25問以上ならmatchDay.WEEKLY_BONUSを追加付与
    if (playCount >= matchDay.weeklyBonus.requiredPlays &&
        weeklyCorrectTotal >= matchDay.weeklyBonus.requiredCorrectTotal) {
      exp += matchDay.weeklyBonus.bonusExp;
      pt += matchDay.weeklyBonus.bonusPt;
    }

    return (exp, pt);
  }

  /// 定常クイズ報酬を計算
  /// 
  /// [difficulty] 難易度 ('EASY' | 'NORMAL' | 'HARD')
  /// [correctCount] 正答数(0-10)
  /// [watchedAd] 広告視聴したかどうか
  /// 
  /// 戻り値: (exp, pt) のタプル
  static (int exp, int pt) calculateRegularQuizReward({
    required String difficulty,
    required int correctCount,
    required bool watchedAd,
  }) {
    // 1. クイズの難易度に応じてquizRewardsから区分を取得
    final difficultyUpper = difficulty.toUpperCase();
    if (!quizRewards.containsKey(difficultyUpper)) {
      // 難易度が存在しない場合はEASYとして扱う
      return calculateRegularQuizReward(
        difficulty: 'EASY',
        correctCount: correctCount,
        watchedAd: watchedAd,
      );
    }

    final tier = getRewardTier(correctCount);
    final baseReward = quizRewards[difficultyUpper]!.rewards[tier]!;
    var exp = baseReward.exp;
    var pt = baseReward.pt;

    // 2. 広告視聴した場合はadBonus.RESULT_SCREEN_MULTIPLIERを乗算して加算（小数点以下切り捨て）
    if (watchedAd) {
      final adBonusExp = math.max(0, (exp * adBonus.resultScreenMultiplier).floor());
      final adBonusPt = math.max(0, (pt * adBonus.resultScreenMultiplier).floor());
      exp += adBonusExp;
      pt += adBonusPt;
    }

    return (exp, pt);
  }
}
