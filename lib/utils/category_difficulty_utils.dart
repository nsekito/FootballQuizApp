import '../constants/app_constants.dart';

/// カテゴリ名と難易度名の変換ユーティリティ
class CategoryDifficultyUtils {
  /// カテゴリ名を問題カード用の短いラベルに変換
  static String getCategoryShortName(String category) {
    switch (category) {
      case AppConstants.categoryRules:
        return 'ルール';
      case AppConstants.categoryHistory:
        return '歴史';
      case AppConstants.categoryTeams:
        return 'チーム';
      case AppConstants.categoryMatchRecap:
        return 'MATCHDAY';
      default:
        return category;
    }
  }

  /// カテゴリ名を日本語に変換
  static String getCategoryName(String category) {
    switch (category) {
      case AppConstants.categoryRules:
        return 'ルールクイズ';
      case AppConstants.categoryHistory:
        return '歴史クイズ';
      case AppConstants.categoryTeams:
        return 'チームクイズ';
      case AppConstants.categoryMatchRecap:
        return 'Monday Match Recap';
      case AppConstants.categoryDailyQuiz:
        return 'Daily Quiz';
      default:
        return category;
    }
  }

  /// 難易度名を表示用に変換
  static String getDifficultyName(String difficulty) {
    switch (difficulty) {
      case AppConstants.difficultyEasy:
        return 'EASY';
      case AppConstants.difficultyNormal:
        return 'NORMAL';
      case AppConstants.difficultyHard:
        return 'HARD';
      default:
        return difficulty.toUpperCase();
    }
  }
}
