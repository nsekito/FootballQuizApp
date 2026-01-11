import '../models/question.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

/// サンプルデータをデータベースに追加するサービス
class SampleDataService {
  /// サンプルクイズデータを追加
  static Future<void> addSampleData(DatabaseService databaseService) async {
    final sampleQuestions = [
      Question(
        id: 'rule_001',
        text: 'オフサイドの判定で、ボールより前にいる選手はオフサイドポジションにいることになる。',
        options: [
          '正しい',
          '間違い',
          'ゴールキーパー以外の場合のみ正しい',
          'ボールの位置は関係ない',
        ],
        answerIndex: 1,
        explanation:
            'オフサイドポジションは、相手陣内でボールより前にいる選手が対象です。ただし、ボールより前にいるだけではオフサイドにはなりません。',
        trivia: 'オフサイドルールは1863年に制定されましたが、現在のルールとは大きく異なっていました。',
        category: AppConstants.categoryRules,
        difficulty: AppConstants.difficultyEasy,
        tags: 'rules,offside',
      ),
      Question(
        id: 'rule_002',
        text: 'イエローカードを2枚もらった場合、その選手はどうなる？',
        options: [
          '警告のみで試合続行',
          '退場となる',
          '次の試合も出場停止',
          'ペナルティキックが与えられる',
        ],
        answerIndex: 1,
        explanation:
            'イエローカードを2枚もらうと、レッドカードと同等の扱いとなり、その場で退場となります。',
        trivia: 'レッドカードの制度は1970年のワールドカップから導入されました。',
        category: AppConstants.categoryRules,
        difficulty: AppConstants.difficultyNormal,
        tags: 'rules,card',
      ),
      Question(
        id: 'history_001',
        text: '日本が初めてワールドカップに出場したのは何年？',
        options: ['1994年', '1998年', '2002年', '2006年'],
        answerIndex: 1,
        explanation:
            '日本は1998年のフランス大会で初めてワールドカップ本大会に出場しました。',
        trivia: '2002年大会は日本と韓国の共同開催でした。',
        category: AppConstants.categoryHistory,
        difficulty: AppConstants.difficultyEasy,
        tags: 'history,japan,worldcup',
      ),
      Question(
        id: 'team_001',
        text: 'J1リーグで最多優勝回数を誇るクラブは？',
        options: ['横浜F・マリノス', '鹿島アントラーズ', '川崎フロンターレ', 'ガンバ大阪'],
        answerIndex: 0,
        explanation:
            '横浜F・マリノス（旧：横浜マリノス）はJ1リーグで最多の優勝回数を誇ります。',
        trivia: '横浜F・マリノスは1995年と2004年にJリーグチャンピオンシップで優勝しています。',
        category: AppConstants.categoryTeams,
        difficulty: AppConstants.difficultyNormal,
        tags: 'teams,japan,j1',
      ),
    ];

    await databaseService.insertQuestions(sampleQuestions);
  }
}
