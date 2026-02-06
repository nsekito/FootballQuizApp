import '../utils/constants.dart';

/// カテゴリ名と難易度名の変換ユーティリティ
class CategoryDifficultyUtils {
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
      case AppConstants.difficultyExtreme:
        return 'EXTREME';
      default:
        return difficulty.toUpperCase();
    }
  }

  /// カテゴリのタイトルを取得
  static String getCategoryTitle(String category) {
    return getCategoryName(category);
  }
}
