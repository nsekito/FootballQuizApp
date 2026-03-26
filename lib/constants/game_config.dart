/// ゲーム設定定数
/// アプリ内のすべてのポイント・EXP計算はこの定数ファイルを参照すること。
/// ハードコーディングは禁止。
library;

// ============================================
// ランク設定
// ============================================
class RankConfig {
  final int rank;
  final String name;
  final int requiredExp;

  const RankConfig({
    required this.rank,
    required this.name,
    required this.requiredExp,
  });
}

final List<RankConfig> ranks = [
  const RankConfig(rank: 1, name: 'ボール拾い', requiredExp: 0),
  const RankConfig(rank: 2, name: 'コーン並べ係', requiredExp: 100),
  const RankConfig(rank: 3, name: '給水係', requiredExp: 300),
  const RankConfig(rank: 4, name: 'ビブス配り', requiredExp: 600),
  const RankConfig(rank: 5, name: '練習生', requiredExp: 1000),
  const RankConfig(rank: 6, name: 'ベンチ入り', requiredExp: 1600),
  const RankConfig(rank: 7, name: '途中出場', requiredExp: 2400),
  const RankConfig(rank: 8, name: 'スタメン', requiredExp: 3500),
  const RankConfig(rank: 9, name: '背番号10', requiredExp: 5000),
  const RankConfig(rank: 10, name: 'キャプテン', requiredExp: 7000),
  const RankConfig(rank: 11, name: '国内MVP', requiredExp: 9500),
  const RankConfig(rank: 12, name: '海外移籍', requiredExp: 13000),
  const RankConfig(rank: 13, name: 'ワールドクラス', requiredExp: 17500),
  const RankConfig(rank: 14, name: 'バロンドール', requiredExp: 23000),
  const RankConfig(rank: 15, name: 'レジェンド', requiredExp: 30000),
];

// ============================================
// クイズ報酬設定
// ============================================
/// 正答数の区分: '0-3' | '4-5' | '6-7' | '8-9' | '10'
class QuizReward {
  final int exp;
  final int pt;

  const QuizReward({required this.exp, required this.pt});
}

class QuizRewardsConfig {
  final Map<String, QuizReward> rewards;

  const QuizRewardsConfig({required this.rewards});
}

final Map<String, QuizRewardsConfig> quizRewards = {
  // matchDay報酬（広告視聴6回対応のため、基本報酬を半分に調整）
  'matchDay': const QuizRewardsConfig(rewards: {
    '0-3': QuizReward(exp: 7, pt: 4),      // 15→7, 8→4
    '4-5': QuizReward(exp: 12, pt: 10),    // 25→12, 20→10
    '6-7': QuizReward(exp: 22, pt: 20),    // 45→22, 40→20
    '8-9': QuizReward(exp: 37, pt: 30),    // 75→37, 60→30
    '10': QuizReward(exp: 60, pt: 45),     // 120→60, 90→45
  }),
  'EASY': const QuizRewardsConfig(rewards: {
    '0-3': QuizReward(exp: 3, pt: 2),
    '4-5': QuizReward(exp: 5, pt: 4),
    '6-7': QuizReward(exp: 10, pt: 7),
    '8-9': QuizReward(exp: 16, pt: 12),
    '10': QuizReward(exp: 25, pt: 18),
  }),
  'NORMAL': const QuizRewardsConfig(rewards: {
    '0-3': QuizReward(exp: 5, pt: 3),
    '4-5': QuizReward(exp: 9, pt: 7),
    '6-7': QuizReward(exp: 16, pt: 12),
    '8-9': QuizReward(exp: 28, pt: 20),
    '10': QuizReward(exp: 45, pt: 30),
  }),
  'HARD': const QuizRewardsConfig(rewards: {
    '0-3': QuizReward(exp: 7, pt: 5),
    '4-5': QuizReward(exp: 14, pt: 10),
    '6-7': QuizReward(exp: 25, pt: 18),
    '8-9': QuizReward(exp: 42, pt: 32),
    '10': QuizReward(exp: 70, pt: 50),
  }),
};

// ============================================
// MATCHDAY設定
// ============================================
class MatchDayConfig {
  final int maxPlaysPerWeek;
  final List<double> playMultipliers;
  final WeeklyBonusConfig weeklyBonus;

  const MatchDayConfig({
    required this.maxPlaysPerWeek,
    required this.playMultipliers,
    required this.weeklyBonus,
  });
}

class WeeklyBonusConfig {
  final int requiredPlays;
  final int requiredCorrectTotal;
  final int bonusExp;
  final int bonusPt;

  const WeeklyBonusConfig({
    required this.requiredPlays,
    required this.requiredCorrectTotal,
    required this.bonusExp,
    required this.bonusPt,
  });
}

// MATCHDAY設定
// 広告視聴で最大6回プレイ可能（J1とEuropeをそれぞれ3回ずつ）
// 基本報酬は半分に調整されているため、ポイントの価値を維持
const matchDay = MatchDayConfig(
  maxPlaysPerWeek: 6,  // 総プレイ回数（リーグタイプ別に3回ずつ）
  playMultipliers: [1.0, 1.0, 1.0, 1.0, 1.0, 1.0],  // 基本報酬が半分なので、すべて1.0倍
  weeklyBonus: WeeklyBonusConfig(
    requiredPlays: 6,  // 6回プレイでボーナス
    requiredCorrectTotal: 50,  // 60問中50問正解でボーナス
    bonusExp: 50,
    bonusPt: 30,
  ),
);

// ============================================
// DAILY QUIZ設定
// ============================================
class DailyQuizConfig {
  final int maxPlaysPerDay;

  const DailyQuizConfig({
    required this.maxPlaysPerDay,
  });
}

const dailyQuiz = DailyQuizConfig(
  maxPlaysPerDay: 2,
);

// ============================================
// 広告ボーナス設定
// ============================================
class AdBonusConfig {
  final double resultScreenMultiplier;
  final double loginBonusMultiplier;
  final int historyFreeUnlockDailyLimit;
  /// 昇格試験不合格時リワード広告で、没収PTに対して還元する割合（例: 0.5 で没収の半額をキャッシュバック）
  final double promotionExamFailCashbackRatio;

  const AdBonusConfig({
    required this.resultScreenMultiplier,
    required this.loginBonusMultiplier,
    required this.historyFreeUnlockDailyLimit,
    required this.promotionExamFailCashbackRatio,
  });
}

const adBonus = AdBonusConfig(
  resultScreenMultiplier: 0.5,
  loginBonusMultiplier: 2.0,
  historyFreeUnlockDailyLimit: 3,
  promotionExamFailCashbackRatio: 0.5,
);

// ============================================
// ログインボーナス設定
// ============================================
class LoginBonusConfig {
  final List<int> dailyPt;
  final int consecutive7DayBonusExp;

  const LoginBonusConfig({
    required this.dailyPt,
    required this.consecutive7DayBonusExp,
  });
}

const loginBonus = LoginBonusConfig(
  // 1日目: 10pt, 2日目: 10pt, 3日目: 10pt, 4日目: 30pt, 5日目: 10pt, 6日目: 10pt, 7日目: 50pt
  dailyPt: [10, 10, 10, 30, 10, 10, 50],
  consecutive7DayBonusExp: 20,
);

// ============================================
// 難易度解放設定
// ============================================
class UnlockCategoryConfig {
  final UnlockDifficultyConfig rule;
  final UnlockDifficultyConfig history;
  final UnlockDifficultyConfig team;

  const UnlockCategoryConfig({
    required this.rule,
    required this.history,
    required this.team,
  });
}

class UnlockDifficultyConfig {
  final int cost;
  final int forfeit;
  final int retryCost;
  final int bonusExp;
  final int bonusPt;
  final int requiredRank;

  const UnlockDifficultyConfig({
    required this.cost,
    required this.forfeit,
    required this.retryCost,
    required this.bonusExp,
    required this.bonusPt,
    required this.requiredRank,
  });
}

final Map<String, UnlockCategoryConfig> unlockConfig = {
  'NORMAL': const UnlockCategoryConfig(
    rule: UnlockDifficultyConfig(
      cost: 120,
      forfeit: 500,
      retryCost: 500,
      bonusExp: 50,
      bonusPt: 25,
      requiredRank: 4,
    ),
    history: UnlockDifficultyConfig(
      cost: 120,
      forfeit: 500,
      retryCost: 500,
      bonusExp: 50,
      bonusPt: 25,
      requiredRank: 4,
    ),
    team: UnlockDifficultyConfig(
      cost: 100,
      forfeit: 500,
      retryCost: 500,
      bonusExp: 40,
      bonusPt: 20,
      requiredRank: 4,
    ),
  ),
  'HARD': const UnlockCategoryConfig(
    rule: UnlockDifficultyConfig(
      cost: 500,
      forfeit: 500,
      retryCost: 500,
      bonusExp: 150,
      bonusPt: 75,
      requiredRank: 8,
    ),
    history: UnlockDifficultyConfig(
      cost: 500,
      forfeit: 500,
      retryCost: 500,
      bonusExp: 150,
      bonusPt: 75,
      requiredRank: 8,
    ),
    team: UnlockDifficultyConfig(
      cost: 400,
      forfeit: 500,
      retryCost: 500,
      bonusExp: 120,
      bonusPt: 60,
      requiredRank: 8,
    ),
  ),
};

// ============================================
// クイズ履歴解放設定
// ============================================
class HistoryUnlockConfig {
  final int singleQuestionCost;
  final int bundle10Cost;

  const HistoryUnlockConfig({
    required this.singleQuestionCost,
    required this.bundle10Cost,
  });
}

const historyUnlock = HistoryUnlockConfig(
  singleQuestionCost: 15,
  bundle10Cost: 25,
);
