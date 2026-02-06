/// アプリ全体で使用する定数
class AppConstants {
  // 経験値（exp）システム
  static const int expPerCorrectAnswer = 10;
  static const int expPerfectScoreBonus = 50;
  static const int expRewardedAd = 100;
  
  // ポイントシステム
  static const int pointsPerCorrectAnswer = 10;
  static const int pointsPerfectScoreBonus = 50;
  static const int pointsRewardedAd = 100;
  
  // MATCH DAYの倍率
  static const double matchDayExpMultiplier = 5.0;
  static const double matchDayPointsMultiplier = 5.0;
  
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
  static const String categoryNews = 'news';

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
  static const String newsDataPath = 'data/news';

  // タイムアウト設定（秒）
  static const int remoteDataTimeoutSeconds = 30;

  // ニュースクイズフィルタ
  static const String regionDomestic = 'domestic';
  static const String regionWorld = 'world';

  // Weekly Recap リーグタイプ
  static const String leagueTypeJ1 = 'j1';
  static const String leagueTypeEurope = 'europe';

  // レスポンシブデザイン
  static const double maxContentWidth = 600.0;
}
