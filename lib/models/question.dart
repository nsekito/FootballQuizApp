/// クイズ問題のデータモデル
class Question {
  final String id;
  final String text; // 問題文
  final List<String> options; // 選択肢 (4択)
  final int answerIndex; // 正解インデックス
  final String explanation; // 解説
  final String? trivia; // 小ネタ・豆知識
  final String category; // rules, history, teams, match_recap
  final String difficulty; // easy, normal, hard, extreme
  final String tags; // 国名、リーグ名、年度など検索用タグ
  final String? referenceDate; // 対象年月（YYYYまたはYYYY-MM形式、オプション）
  
  // 新しいスキーマのフィールド（オプショナル）
  final String? quizType; // team/history/rule/weekly
  final String? categoryId; // システム用カテゴリID
  final String? region; // japan/world/null
  final String? league; // j1/j2/spain等/null
  final String? team; // 表示用チーム名/null
  final String? teamId; // システム用チームID/null
  final String? weeklyMeta; // JSON文字列/null

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.answerIndex,
    required this.explanation,
    this.trivia,
    required this.category,
    required this.difficulty,
    required this.tags,
    this.referenceDate,
    this.quizType,
    this.categoryId,
    this.region,
    this.league,
    this.team,
    this.teamId,
    this.weeklyMeta,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'options': options,
        'answerIndex': answerIndex,
        'explanation': explanation,
        'trivia': trivia,
        'category': category,
        'difficulty': difficulty,
        'tags': tags,
        'referenceDate': referenceDate,
        'quizType': quizType,
        'categoryId': categoryId,
        'region': region,
        'league': league,
        'team': team,
        'teamId': teamId,
        'weeklyMeta': weeklyMeta,
      };

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        id: json['id'] as String,
        text: json['text'] as String,
        options: List<String>.from(json['options'] as List),
        answerIndex: json['answerIndex'] as int,
        explanation: json['explanation'] as String,
        trivia: json['trivia'] as String?,
        category: json['category'] as String,
        difficulty: json['difficulty'] as String,
        tags: json['tags'] as String,
        referenceDate: json['referenceDate'] as String?,
        quizType: json['quizType']?.toString(),
        categoryId: json['categoryId']?.toString(),
        region: json['region']?.toString(),
        league: json['league']?.toString(),
        team: json['team']?.toString(),
        teamId: json['teamId']?.toString(),
        weeklyMeta: json['weeklyMeta']?.toString(),
      );
}
