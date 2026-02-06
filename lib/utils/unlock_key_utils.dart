/// アンロックキー生成と管理のユーティリティ
class UnlockKeyUtils {
  /// アンロックキーを生成
  /// 形式: {category}_{difficulty}_{normalized_tags}
  /// 例: teams_normal_teams,japan,kashiwa
  static String generateUnlockKey({
    required String category,
    required String difficulty,
    required String tags,
  }) {
    final normalizedTags = _normalizeTags(tags);
    return '${category}_${difficulty}_$normalizedTags';
  }

  /// タグを正規化（ソート、重複除去）
  static String _normalizeTags(String tags) {
    if (tags.isEmpty) {
      return '';
    }
    
    // カンマ区切りで分割
    final tagList = tags.split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet() // 重複除去
        .toList();
    
    // ソート
    tagList.sort();
    
    // カンマ区切りで結合
    return tagList.join(',');
  }

  /// タグリストからアンロックキーを生成
  static String generateUnlockKeyFromList({
    required String category,
    required String difficulty,
    required List<String> tags,
  }) {
    final tagsString = tags.join(',');
    return generateUnlockKey(
      category: category,
      difficulty: difficulty,
      tags: tagsString,
    );
  }

  /// アンロックキーをパース
  static Map<String, String>? parseUnlockKey(String unlockKey) {
    final parts = unlockKey.split('_');
    if (parts.length < 3) {
      return null;
    }
    
    final category = parts[0];
    final difficulty = parts[1];
    final tags = parts.sublist(2).join('_'); // タグ部分は再結合
    
    return {
      'category': category,
      'difficulty': difficulty,
      'tags': tags,
    };
  }
}
