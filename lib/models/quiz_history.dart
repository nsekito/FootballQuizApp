/// クイズ履歴のデータモデル
class QuizHistory {
  final int? id;
  final String category;
  final String difficulty;
  final int score;
  final int total;
  final int earnedPoints;
  final DateTime completedAt;

  QuizHistory({
    this.id,
    required this.category,
    required this.difficulty,
    required this.score,
    required this.total,
    required this.earnedPoints,
    required this.completedAt,
  });

  /// 正答率を取得（0.0〜1.0）
  double get accuracy => total > 0 ? score / total : 0.0;

  /// 正答率をパーセンテージで取得
  double get accuracyPercentage => accuracy * 100;

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'category': category,
        'difficulty': difficulty,
        'score': score,
        'total': total,
        'earned_points': earnedPoints,
        'completed_at': completedAt.toIso8601String(),
      };

  factory QuizHistory.fromJson(Map<String, dynamic> json) => QuizHistory(
        id: json['id'] as int?,
        category: json['category'] as String,
        difficulty: json['difficulty'] as String,
        score: json['score'] as int,
        total: json['total'] as int,
        earnedPoints: json['earned_points'] as int,
        completedAt: DateTime.parse(json['completed_at'] as String),
      );

  /// データベースのMapからQuizHistoryオブジェクトに変換
  factory QuizHistory.fromMap(Map<String, dynamic> map) => QuizHistory(
        id: map['id'] as int?,
        category: map['category'] as String,
        difficulty: map['difficulty'] as String,
        score: map['score'] as int,
        total: map['total'] as int,
        earnedPoints: map['earned_points'] as int,
        completedAt: DateTime.parse(map['completed_at'] as String),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category': category,
        'difficulty': difficulty,
        'score': score,
        'total': total,
        'earned_points': earnedPoints,
        'completed_at': completedAt.toIso8601String(),
      };
}
