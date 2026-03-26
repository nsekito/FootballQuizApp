/// アプリ全体で使用する定数
class AppConstants {
  // 昇格試験の必要ポイント
  static const int promotionExamPointsEasyToNormal = 1000;
  static const int promotionExamPointsNormalToHard = 5000;
  static const int promotionExamPointsHardToExtreme = 10000;

  // 昇格試験の設定
  static const int promotionExamQuestionCount = 20;
  /// 合格に必要な正解率（例: 20問なら 0.8 → 16問以上）
  static const double promotionExamPassRatio = 0.8;
  /// 合格に必要な正解数（問題数 × `promotionExamPassRatio` を切り上げ）
  static int get promotionExamPassLine =>
      (promotionExamQuestionCount * promotionExamPassRatio).ceil();

  // クイズ設定
  static const int defaultQuestionsPerQuiz = 10;
  static const int optionsPerQuestion = 4;

  // 問題開放画面のページネーション
  static const int questionUnlockPageSize = 50;

  // カテゴリ
  static const String categoryRules = 'rules';
  static const String categoryHistory = 'history';
  static const String categoryTeams = 'teams';
  static const String categoryMatchRecap = 'match_recap';
  static const String categoryDailyQuiz = 'daily_quiz';

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

  // 背景画像パス（Featured Cards）
  static const String assetStadiumBackground =
      'assets/images/03_Backgrounds/stadium_background.png';
  static const String assetDailyQuizBackground =
      'assets/images/03_Backgrounds/daily_quiz_background.png';
}
