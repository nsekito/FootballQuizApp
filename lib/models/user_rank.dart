/// ユーザーのランク称号
enum UserRank {
  ballPicker('Ball Picker', 'ボール拾い', 0, 99),
  coneSetter('Cone Setter', 'コーン並べ係', 100, 199),
  bibDistributor('Bib Distributor', 'ビブス配り担当', 200, 299),
  eternalBench('Eternal Bench', '万年ベンチ', 300, 449),
  stoppageTimePlayer('Stoppage Time Player', 'ロスタイム要員', 450, 649),
  starterCandidate('Starter Candidate', 'スタメン候補', 650, 999),
  localCelebrity('Local Celebrity', '地元の有名人', 1000, 1499),
  j3RisingStar('J3 Rising Star', 'J3の新星', 1500, 2199),
  j2NuclearStriker('J2 Nuclear Striker', 'J2の核弾頭', 2200, 3199),
  j1Regular('J1 Regular', 'J1レギュラー', 3200, 4699),
  nationalSecretWeapon('National Secret Weapon', '代表の秘密兵器', 4700, 6999),
  worldCupWarrior('World Cup Warrior', 'ワールドカップ戦士', 7000, 9999),
  overseasSamurai('Overseas Samurai', '海を渡った侍', 10000, 14999),
  ballonDor('Ballon d\'Or', 'バロンドーラー', 15000, 24999),
  soccerGod('Soccer God', 'サッカーの神', 25000, null);

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
