/// チームクイズのタグ文字列（設定画面の `_generateTags` と同形式）から
/// [DatabaseService.getQuestions] が期待する region / team へ変換する。
///
/// 例: `teams,japan,j1,kashiwa_reysol` → region=japan, team=kashiwa_reysol
/// 例: `teams,japan,j1` → region=japan, team=j1_all_teams
class TeamQuizQueryParams {
  final String? region;
  final String? team;

  const TeamQuizQueryParams({this.region, this.team});

  static const Set<String> _leagueTags = {
    'j1',
    'j2',
    'serie_a',
    'la_liga',
    'premier_league',
  };

  /// [tags] が空または `teams` を含まない場合はフィールドは null。
  static TeamQuizQueryParams fromTags(String tags) {
    final raw = tags
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (!raw.contains('teams')) {
      return const TeamQuizQueryParams();
    }

    final parts = List<String>.from(raw)..remove('teams');
    if (parts.isEmpty) {
      return const TeamQuizQueryParams();
    }

    // teams の直後は国コード（DB の region と一致させる）
    final region = parts.first;
    parts.removeAt(0);
    if (parts.isEmpty) {
      return TeamQuizQueryParams(region: region);
    }

    if (parts.length == 1) {
      final p = parts.single;
      if (p == 'j1') {
        return TeamQuizQueryParams(region: region, team: 'j1_all_teams');
      }
      if (p == 'j2') {
        return TeamQuizQueryParams(region: region, team: 'j2_all_teams');
      }
      return TeamQuizQueryParams(region: region, team: p);
    }

    // 例: j1 + kashiwa_reysol / serie_a + juventus
    if (_leagueTags.contains(parts.first)) {
      parts.removeAt(0);
      if (parts.isEmpty) {
        return TeamQuizQueryParams(region: region);
      }
      final teamSlug = parts.length == 1 ? parts.single : parts.join(',');
      return TeamQuizQueryParams(region: region, team: teamSlug);
    }

    return TeamQuizQueryParams(region: region);
  }
}
