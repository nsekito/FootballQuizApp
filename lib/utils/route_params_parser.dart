/// ルーターのqueryParametersをパースするためのヘルパー関数
class RouteParamsParser {
  /// 文字列パラメータを取得（デフォルト値: 空文字列）
  static String parseStringParam(
    Map<String, String> queryParameters,
    String key, {
    String defaultValue = '',
  }) {
    return queryParameters[key] ?? defaultValue;
  }

  /// 整数パラメータを取得（デフォルト値: 0）
  static int parseIntParam(
    Map<String, String> queryParameters,
    String key, {
    int defaultValue = 0,
  }) {
    return int.tryParse(queryParameters[key] ?? '') ?? defaultValue;
  }

  /// オプショナルな文字列パラメータを取得（存在しない場合はnull）
  static String? parseOptionalStringParam(
    Map<String, String> queryParameters,
    String key,
  ) {
    final value = queryParameters[key];
    return value != null && value.isNotEmpty ? value : null;
  }

  /// オプショナルな整数パラメータを取得（存在しない場合またはパース失敗時はnull）
  static int? parseOptionalIntParam(
    Map<String, String> queryParameters,
    String key,
  ) {
    final value = queryParameters[key];
    if (value == null || value.isEmpty) return null;
    return int.tryParse(value);
  }

  /// ブール値パラメータを取得（デフォルト値: false）
  static bool parseBoolParam(
    Map<String, String> queryParameters,
    String key, {
    bool defaultValue = false,
  }) {
    final value = queryParameters[key];
    if (value == null || value.isEmpty) return defaultValue;
    return value.toLowerCase() == 'true' || value == '1';
  }
}
