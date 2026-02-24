/// アプリ全体で使用する定数
class AppConstants {
  // 昇格試験の必要ポイント
  static const int promotionExamPointsEasyToNormal = 1000;
  static const int promotionExamPointsNormalToHard = 5000;
  static const int promotionExamPointsHardToExtreme = 10000;

  // 昇格試験の設定
  static const int promotionExamQuestionCount = 20;
  static const int promotionExamPassScore = 16;

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
  static const String githubRawBaseUrl = 'https://raw.githubusercontent.com';
  static const String githubRepoOwner = 'nsekito';
  static const String githubRepoName = 'FootballQuizApp';
  static const String githubBranch = 'main';

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
