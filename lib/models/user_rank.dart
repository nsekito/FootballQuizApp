/// ユーザーのランク称号
enum UserRank {
  ballPicker('Ball Picker', 'ボール拾い', 0, 99),
  coneSetter('Cone Setter', 'コーン並べ係', 100, 199),
  waterCarrier('Water Carrier', '給水係', 200, 299),
  bibDistributor('Bib Distributor', 'ビブス配り', 300, 449),
  trainee('Trainee', '練習生', 450, 649),
  benchPlayer('Bench Player', 'ベンチ入り', 650, 999),
  substitute('Substitute', '途中出場', 1000, 1499),
  starter('Starter', 'スタメン', 1500, 2199),
  numberTen('Number Ten', '背番号10', 2200, 3199),
  captain('Captain', 'キャプテン', 3200, 4699),
  domesticMVP('Domestic MVP', '国内MVP', 4700, 6999),
  overseasTransfer('Overseas Transfer', '海外移籍', 7000, 9999),
  worldClass('World Class', 'ワールドクラス', 10000, 14999),
  ballonDor('Ballon d\'Or', 'バロンドール', 15000, 24999),
  legend('Legend', 'レジェンド', 25000, null);

  final String englishName;
  final String japaneseName;
  final int minExp; // expベースに変更
  final int? maxExp; // expベースに変更

  const UserRank(
    this.englishName,
    this.japaneseName,
    this.minExp,
    this.maxExp,
  );

  /// 累計expからランクを取得
  static UserRank fromExp(int totalExp) {
    for (final rank in UserRank.values.reversed) {
      if (totalExp >= rank.minExp) {
        if (rank.maxExp == null || totalExp <= rank.maxExp!) {
          return rank;
        }
      }
    }
    return UserRank.ballPicker;
  }

  /// 次のランクまでの必要exp数を取得
  int? expToNextRank(int currentExp) {
    final currentIndex = UserRank.values.indexOf(this);
    if (currentIndex < UserRank.values.length - 1) {
      final nextRank = UserRank.values[currentIndex + 1];
      return nextRank.minExp - currentExp;
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
}
