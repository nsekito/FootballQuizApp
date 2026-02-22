import '../constants/gameConfig.dart';

/// ユーザーのランク称号
enum UserRank {
  ballPicker('Ball Picker', 'ボール拾い', 0),
  coneSetter('Cone Setter', 'コーン並べ係', 1),
  waterCarrier('Water Carrier', '給水係', 2),
  bibDistributor('Bib Distributor', 'ビブス配り', 3),
  trainee('Trainee', '練習生', 4),
  benchPlayer('Bench Player', 'ベンチ入り', 5),
  substitute('Substitute', '途中出場', 6),
  starter('Starter', 'スタメン', 7),
  numberTen('Number Ten', '背番号10', 8),
  captain('Captain', 'キャプテン', 9),
  domesticMVP('Domestic MVP', '国内MVP', 10),
  overseasTransfer('Overseas Transfer', '海外移籍', 11),
  worldClass('World Class', 'ワールドクラス', 12),
  ballonDor('Ballon d\'Or', 'バロンドール', 13),
  legend('Legend', 'レジェンド', 14);

  final String englishName;
  final String japaneseName;
  final int rankIndex; // RANKS配列のインデックス

  const UserRank(
    this.englishName,
    this.japaneseName,
    this.rankIndex,
  );

  /// RANKS定数からランク情報を取得
  RankConfig get config {
    if (rankIndex >= 0 && rankIndex < RANKS.length) {
      return RANKS[rankIndex];
    }
    return RANKS[0]; // フォールバック
  }

  /// 累計expからランクを取得（RANKS定数を参照）
  static UserRank fromExp(int totalExp) {
    // RANKSを逆順に走査して、totalExpがrequiredExp以上になる最初のランクを返す
    for (int i = RANKS.length - 1; i >= 0; i--) {
      if (totalExp >= RANKS[i].requiredExp) {
        return UserRank.values[i];
      }
    }
    return UserRank.ballPicker;
  }

  /// 次のランクまでの必要exp数を取得
  int? expToNextRank(int currentExp) {
    if (rankIndex < UserRank.values.length - 1) {
      final nextRankIndex = rankIndex + 1;
      final nextRankConfig = RANKS[nextRankIndex];
      return nextRankConfig.requiredExp - currentExp;
    }
    return null; // 最高ランクの場合
  }
  
  // 後方互換性のため、fromPointsメソッドを残す（expとして扱う）
  @Deprecated('Use fromExp instead')
  static UserRank fromPoints(int totalPoints) {
    return fromExp(totalPoints);
  }
  
  // 後方互換性のため、pointsToNextRankメソッドを残す
  @Deprecated('Use expToNextRank instead')
  int? pointsToNextRank(int currentPoints) {
    return expToNextRank(currentPoints);
  }

  // 後方互換性のため、minExpとmaxExpのgetterを提供
  @Deprecated('Use config.requiredExp instead')
  int get minExp => config.requiredExp;
  
  @Deprecated('Use next rank\'s requiredExp instead')
  int? get maxExp {
    if (rankIndex < UserRank.values.length - 1) {
      return RANKS[rankIndex + 1].requiredExp - 1;
    }
    return null;
  }
}
