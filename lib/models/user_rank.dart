import '../constants/game_config.dart';

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
  final int rankIndex; // ranks配列のインデックス

  const UserRank(
    this.englishName,
    this.japaneseName,
    this.rankIndex,
  );

  /// ranks定数からランク情報を取得
  RankConfig get config {
    if (rankIndex >= 0 && rankIndex < ranks.length) {
      return ranks[rankIndex];
    }
    return ranks[0]; // フォールバック
  }

  /// 累計expからランクを取得（ranks定数を参照）
  static UserRank fromExp(int totalExp) {
    // ranksを逆順に走査して、totalExpがrequiredExp以上になる最初のランクを返す
    for (int i = ranks.length - 1; i >= 0; i--) {
      if (totalExp >= ranks[i].requiredExp) {
        return UserRank.values[i];
      }
    }
    return UserRank.ballPicker;
  }

  /// 次のランクまでの必要exp数を取得
  int? expToNextRank(int currentExp) {
    if (rankIndex < UserRank.values.length - 1) {
      final nextRankIndex = rankIndex + 1;
      final nextRankConfig = ranks[nextRankIndex];
      return nextRankConfig.requiredExp - currentExp;
    }
    return null; // 最高ランクの場合
  }
  
  int get minExp => config.requiredExp;

  int? get maxExp {
    if (rankIndex < UserRank.values.length - 1) {
      return ranks[rankIndex + 1].requiredExp - 1;
    }
    return null;
  }
}
