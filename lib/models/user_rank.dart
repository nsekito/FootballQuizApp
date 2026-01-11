/// ユーザーのランク称号
enum UserRank {
  academy('Academy', 'アカデミー生', 0, 499),
  rookie('Rookie', 'ルーキー', 500, 1999),
  regular('Regular', 'レギュラー', 2000, 4999),
  fantasista('Fantasista', 'ファンタジスタ', 5000, 9999),
  legend('Legend', 'レジェンド', 10000, null);

  final String englishName;
  final String japaneseName;
  final int minPoints;
  final int? maxPoints;

  const UserRank(
    this.englishName,
    this.japaneseName,
    this.minPoints,
    this.maxPoints,
  );

  /// 累計GPからランクを取得
  static UserRank fromPoints(int totalPoints) {
    for (final rank in UserRank.values.reversed) {
      if (totalPoints >= rank.minPoints) {
        if (rank.maxPoints == null || totalPoints <= rank.maxPoints!) {
          return rank;
        }
      }
    }
    return UserRank.academy;
  }

  /// 次のランクまでの必要ポイント数を取得
  int? pointsToNextRank(int currentPoints) {
    final currentIndex = UserRank.values.indexOf(this);
    if (currentIndex < UserRank.values.length - 1) {
      final nextRank = UserRank.values[currentIndex + 1];
      return nextRank.minPoints - currentPoints;
    }
    return null; // 最高ランクの場合
  }
}
