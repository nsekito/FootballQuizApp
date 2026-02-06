import '../models/user_rank.dart';
import '../utils/constants.dart';

/// 昇格試験の定義
class PromotionExam {
  final String targetDifficulty; // アンロックする難易度
  final String sourceDifficulty; // 出題元の難易度
  final UserRank requiredRank; // 必要なランク
  final int requiredPoints; // 必要なポイント
  final int questionCount; // 問題数（20問）
  final int passScore; // 合格スコア（16問以上）
  final String category; // 対象カテゴリ
  final String tags; // 対象タグ（カンマ区切り、例："teams,japan,kashiwa"）

  const PromotionExam({
    required this.targetDifficulty,
    required this.sourceDifficulty,
    required this.requiredRank,
    required this.requiredPoints,
    required this.questionCount,
    required this.passScore,
    required this.category,
    required this.tags,
  });

  /// EASY→NORMALの昇格試験を作成
  factory PromotionExam.easyToNormal({
    required String category,
    required String tags,
  }) {
    return PromotionExam(
      targetDifficulty: AppConstants.difficultyNormal,
      sourceDifficulty: AppConstants.difficultyEasy,
      requiredRank: UserRank.starterCandidate,
      requiredPoints: AppConstants.promotionExamPointsEasyToNormal,
      questionCount: AppConstants.promotionExamQuestionCount,
      passScore: AppConstants.promotionExamPassScore,
      category: category,
      tags: tags,
    );
  }

  /// NORMAL→HARDの昇格試験を作成
  factory PromotionExam.normalToHard({
    required String category,
    required String tags,
  }) {
    return PromotionExam(
      targetDifficulty: AppConstants.difficultyHard,
      sourceDifficulty: AppConstants.difficultyNormal,
      requiredRank: UserRank.j3RisingStar,
      requiredPoints: AppConstants.promotionExamPointsNormalToHard,
      questionCount: AppConstants.promotionExamQuestionCount,
      passScore: AppConstants.promotionExamPassScore,
      category: category,
      tags: tags,
    );
  }

  /// HARD→EXTREMEの昇格試験を作成
  factory PromotionExam.hardToExtreme({
    required String category,
    required String tags,
  }) {
    return PromotionExam(
      targetDifficulty: AppConstants.difficultyExtreme,
      sourceDifficulty: AppConstants.difficultyHard,
      requiredRank: UserRank.j1Regular,
      requiredPoints: AppConstants.promotionExamPointsHardToExtreme,
      questionCount: AppConstants.promotionExamQuestionCount,
      passScore: AppConstants.promotionExamPassScore,
      category: category,
      tags: tags,
    );
  }

  /// 昇格試験のタイトルを取得
  String getTitle() {
    final difficultyNames = {
      AppConstants.difficultyEasy: 'EASY',
      AppConstants.difficultyNormal: 'NORMAL',
      AppConstants.difficultyHard: 'HARD',
      AppConstants.difficultyExtreme: 'EXTREME',
    };
    
    final sourceName = difficultyNames[sourceDifficulty] ?? sourceDifficulty.toUpperCase();
    final targetName = difficultyNames[targetDifficulty] ?? targetDifficulty.toUpperCase();
    
    return '$sourceName → $targetName 昇格試験';
  }

  /// 昇格試験の説明を取得
  String getDescription() {
    return '${targetDifficulty.toUpperCase()}難易度をアンロックするための昇格試験です。\n'
        '$questionCount問中$passScore問以上正解で合格となります。';
  }
}
