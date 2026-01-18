import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/router_provider.dart';

// 条件付きインポート: デスクトッププラットフォームのみ（Android/iOSではスタブを使用）
import 'sqflite_ffi_stub.dart'
    if (dart.library.io) 'sqflite_ffi_io.dart' as sqflite_ffi;

// Webプラットフォーム用のインポート（条件付き）
import 'package:sqflite/sqflite.dart';
import 'sqflite_ffi_web_stub.dart'
    if (dart.library.html) 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' as sqflite_web;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Webプラットフォームでsqflite_common_ffi_webを初期化
  if (kIsWeb) {
    try {
      // Webプラットフォーム用のデータベースファクトリを設定
      databaseFactory = sqflite_web.databaseFactoryFfiWeb;
      debugPrint('Webプラットフォーム用のデータベースファクトリを初期化しました');
    } catch (e) {
      debugPrint('Webプラットフォーム用のデータベースファクトリの初期化に失敗: $e');
    }
  }
  // Windows/Linux/macOS（デスクトップ）でsqflite_common_ffiを初期化
  else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    try {
      sqflite_ffi.initDatabaseFactory();
    } catch (e) {
      // Android/iOSでは初期化をスキップ（通常のsqfliteを使用）
      debugPrint('sqflite_common_ffiの初期化をスキップ: $e');
    }
  }
  
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
