/// アプリ全体で使用する定数
class AppConstants {
  // ポイントシステム
  static const int pointsPerCorrectAnswer = 10;
  static const int pointsPerfectScoreBonus = 50;
  static const int pointsRewardedAd = 100;

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
  static const String githubRepoOwner = 'your-username'; // GitHubユーザー名
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
}
