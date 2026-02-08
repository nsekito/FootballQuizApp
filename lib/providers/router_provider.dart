import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/configuration_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/result_screen.dart';
import '../screens/history_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/promotion_exam_screen.dart';
import '../screens/promotion_exam_quiz_screen.dart';
import '../utils/route_params_parser.dart';

/// アプリのルーティング設定
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/configuration',
        name: 'configuration',
        builder: (context, state) {
          final category = RouteParamsParser.parseStringParam(
            state.uri.queryParameters,
            'category',
          );
          return ConfigurationScreen(category: category);
        },
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          // 後方互換性: teamパラメータが指定されていない場合はrangeパラメータを使用
          final teamParam = RouteParamsParser.parseStringParam(params, 'team');
          final rangeParam = RouteParamsParser.parseStringParam(params, 'range');
          return QuizScreen(
            category: RouteParamsParser.parseStringParam(params, 'category'),
            difficulty: RouteParamsParser.parseStringParam(params, 'difficulty'),
            country: RouteParamsParser.parseStringParam(params, 'country'),
            region: RouteParamsParser.parseStringParam(params, 'region'),
            team: teamParam.isNotEmpty ? teamParam : rangeParam,
            date: RouteParamsParser.parseOptionalStringParam(params, 'date'),
            leagueType: RouteParamsParser.parseOptionalStringParam(
              params,
              'leagueType',
            ),
          );
        },
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          final score = RouteParamsParser.parseIntParam(params, 'score');
          final total = RouteParamsParser.parseIntParam(params, 'total');
          // 後方互換性のため、expが指定されていない場合はpointsから計算
          final earnedExp = RouteParamsParser.parseIntParam(params, 'exp');
          final earnedPoints = RouteParamsParser.parseIntParam(params, 'points');
          final category = RouteParamsParser.parseStringParam(params, 'category');
          final difficulty = RouteParamsParser.parseStringParam(
            params,
            'difficulty',
          );
          return ResultScreen(
            score: score,
            total: total,
            earnedExp: earnedExp > 0 ? earnedExp : earnedPoints, // 後方互換性
            earnedPoints: earnedPoints,
            category: category,
            difficulty: difficulty,
          );
        },
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        path: '/promotion-exam',
        name: 'promotion-exam',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return PromotionExamScreen(
            category: RouteParamsParser.parseStringParam(params, 'category'),
            tags: RouteParamsParser.parseStringParam(params, 'tags'),
            targetDifficulty: RouteParamsParser.parseStringParam(
              params,
              'targetDifficulty',
            ),
          );
        },
      ),
      GoRoute(
        path: '/promotion-exam-quiz',
        name: 'promotion-exam-quiz',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return PromotionExamQuizScreen(
            category: RouteParamsParser.parseStringParam(params, 'category'),
            sourceDifficulty: RouteParamsParser.parseStringParam(
              params,
              'sourceDifficulty',
            ),
            targetDifficulty: RouteParamsParser.parseStringParam(
              params,
              'targetDifficulty',
            ),
            tags: RouteParamsParser.parseStringParam(params, 'tags'),
          );
        },
      ),
    ],
  );
});
