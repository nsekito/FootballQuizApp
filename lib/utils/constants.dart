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
}
