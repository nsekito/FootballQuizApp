import '../constants/app_constants.dart';

/// 歴史クイズのタグ文字列（設定画面の `_generateTags` と同形式）から
/// [DatabaseService.getQuestions] が期待する region へ変換する。
///
/// 例: `history,japan` → region=japan
/// 例: `history,world` → region=world
class HistoryQuizQueryParams {
  final String? region;

  const HistoryQuizQueryParams({this.region});

  /// [tags] が空または `history` を含まない場合は [region] は null。
  static HistoryQuizQueryParams fromTags(String tags) {
    final raw = tags
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (!raw.contains(AppConstants.categoryHistory)) {
      return const HistoryQuizQueryParams();
    }

    final parts = List<String>.from(raw)
      ..remove(AppConstants.categoryHistory);
    if (parts.isEmpty) {
      return const HistoryQuizQueryParams();
    }

    return HistoryQuizQueryParams(region: parts.first);
  }
}
