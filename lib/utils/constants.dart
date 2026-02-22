/// アプリ全体で使用する定数
/// 後方互換性のため、既存の定数名は残すが、内部でgameConfig.dartを参照
class AppConstants {
  // 経験値（exp）システム（後方互換性のため残す）
  @Deprecated('Use QUIZ_REWARDS from gameConfig.dart instead')
  static const int expPerCorrectAnswer = 10;
  @Deprecated('Use QUIZ_REWARDS from gameConfig.dart instead')
  static const int expPerfectScoreBonus = 50;
  @Deprecated('Use AD_BONUS from gameConfig.dart instead')
  static const int expRewardedAd = 100;
  
  // ポイントシステム（後方互換性のため残す）
  @Deprecated('Use QUIZ_REWARDS from gameConfig.dart instead')
  static const int pointsPerCorrectAnswer = 10;
  @Deprecated('Use QUIZ_REWARDS from gameConfig.dart instead')
  static const int pointsPerfectScoreBonus = 50;
  @Deprecated('Use AD_BONUS from gameConfig.dart instead')
  static const int pointsRewardedAd = 100;
  
  // MATCH DAYの倍率（後方互換性のため残す）
  @Deprecated('Use MATCHDAY from gameConfig.dart instead')
  static const double matchDayExpMultiplier = 5.0;
  @Deprecated('Use MATCHDAY from gameConfig.dart instead')
  static const double matchDayPointsMultiplier = 5.0;
  
  // 昇格試験の必要ポイント（後方互換性のため残す）
  @Deprecated('Use UNLOCK_CONFIG from gameConfig.dart instead')
  static const int promotionExamPointsEasyToNormal = 1000;
  @Deprecated('Use UNLOCK_CONFIG from gameConfig.dart instead')
  static const int promotionExamPointsNormalToHard = 5000;
  @Deprecated('Use UNLOCK_CONFIG from gameConfig.dart instead')
  static const int promotionExamPointsHardToExtreme = 10000;
  
  // 昇格試験の設定（後方互換性のため残す）
  static const int promotionExamQuestionCount = 20;
  @Deprecated('Use UNLOCK_CONFIG from gameConfig.dart instead')
  static const int promotionExamPassScore = 16;
  
  // 問題開放システム（後方互換性のため残す）
  @Deprecated('Use HISTORY_UNLOCK from gameConfig.dart instead')
  static const int questionUnlockPoints = 3;

  // クイズ設定
  static const int defaultQuestionsPerQuiz = 10;
  static const int optionsPerQuestion = 4;

  // カテゴリ
  static const String categoryRules = 'rules';
  static const String categoryHistory = 'history';
  static const String categoryTeams = 'teams';
  static const String categoryMatchRecap = 'match_recap';

  // 難易度
  static const String difficultyEasy = 'easy';
  static const String difficultyNormal = 'normal';
  static const String difficultyHard = 'hard';
  static const String difficultyExtreme = 'extreme';

  // リモートデータ設定
  // 注意: 実際のGitHubリポジトリ情報に変更してください（README.mdを参照）
  static const String githubRawBaseUrl = 'https://raw.githubusercontent.com';
  static const String githubRepoOwner = 'nsekito'; // GitHubユーザー名
  static const String githubRepoName = 'FootballQuizApp'; // リポジトリ名
  static const String githubBranch = 'main'; // ブランチ名

  // リモートデータのパス
  static const String weeklyRecapDataPath = 'data/weekly_recap';

  // タイムアウト設定（秒）
  static const int remoteDataTimeoutSeconds = 30;

  // Weekly Recap リーグタイプ
  static const String leagueTypeJ1 = 'j1';
  static const String leagueTypeEurope = 'europe';

  // レスポンシブデザイン
  static const double maxContentWidth = 600.0;
}
