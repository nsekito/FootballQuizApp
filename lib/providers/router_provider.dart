import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/configuration_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/result_screen.dart';
import '../screens/history_screen.dart';
import '../screens/statistics_screen.dart';

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
          final category = state.uri.queryParameters['category'] ?? '';
          return ConfigurationScreen(category: category);
        },
      ),
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) {
          final category = state.uri.queryParameters['category'] ?? '';
          final difficulty = state.uri.queryParameters['difficulty'] ?? '';
          final country = state.uri.queryParameters['country'] ?? '';
          final region = state.uri.queryParameters['region'] ?? '';
          final range = state.uri.queryParameters['range'] ?? '';
          final year = state.uri.queryParameters['year'];
          final date = state.uri.queryParameters['date'];
          return QuizScreen(
            category: category,
            difficulty: difficulty,
            country: country,
            region: region,
            range: range,
            year: year,
            date: date,
          );
        },
      ),
      GoRoute(
        path: '/result',
        name: 'result',
        builder: (context, state) {
          final score = int.tryParse(state.uri.queryParameters['score'] ?? '0') ?? 0;
          final total = int.tryParse(state.uri.queryParameters['total'] ?? '0') ?? 0;
          final earnedPoints = int.tryParse(state.uri.queryParameters['points'] ?? '0') ?? 0;
          final category = state.uri.queryParameters['category'] ?? '';
          final difficulty = state.uri.queryParameters['difficulty'] ?? '';
          return ResultScreen(
            score: score,
            total: total,
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
    ],
  );
});
