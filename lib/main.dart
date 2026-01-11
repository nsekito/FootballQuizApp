import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/router_provider.dart';

void main() {
  runApp(
    const ProviderScope(
      child: SoccerQuizMasterApp(),
    ),
  );
}

class SoccerQuizMasterApp extends ConsumerWidget {
  const SoccerQuizMasterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Soccer Quiz Master',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
