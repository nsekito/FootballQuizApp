import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/router_provider.dart';
import 'constants/app_colors.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';

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
  
  // 広告SDKを初期化（Webプラットフォームではスキップ）
  if (!kIsWeb) {
    try {
      await AdService.initialize();
    } catch (e) {
      debugPrint('広告SDKの初期化に失敗しました（アプリは正常に動作します）: $e');
    }
  }
  
  // 通知サービスを初期化（Webプラットフォームではスキップ）
  if (!kIsWeb) {
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      // 通知タップ時の処理を設定
      // アプリ起動時に通知から起動された場合の処理は、SoccerQuizMasterApp内で処理
    } catch (e) {
      debugPrint('通知サービスの初期化に失敗しました（アプリは正常に動作します）: $e');
    }
  }
  
  runApp(
    const ProviderScope(
      child: SoccerQuizMasterApp(),
    ),
  );
}

class SoccerQuizMasterApp extends ConsumerStatefulWidget {
  const SoccerQuizMasterApp({super.key});

  @override
  ConsumerState<SoccerQuizMasterApp> createState() => _SoccerQuizMasterAppState();
}

class _SoccerQuizMasterAppState extends ConsumerState<SoccerQuizMasterApp> {
  @override
  void initState() {
    super.initState();
    
    // 通知タップ時の処理を設定（アプリ起動時）
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleNotificationTap();
      });
    }
  }

  /// 通知タップ時の処理
  void _handleNotificationTap() {
    if (kIsWeb) return;
    
    final notificationService = NotificationService();
    final payload = notificationService.getPendingPayload();
    
    if (payload != null && payload.isNotEmpty) {
      // ルーターが準備できたら遷移
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final router = ref.read(routerProvider);
        router.go(payload);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Soccer Quiz Master',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
        textTheme: TextTheme(
          displayLarge: GoogleFonts.notoSansJp(),
          displayMedium: GoogleFonts.notoSansJp(),
          displaySmall: GoogleFonts.notoSansJp(),
          headlineLarge: GoogleFonts.notoSansJp(),
          headlineMedium: GoogleFonts.notoSansJp(),
          headlineSmall: GoogleFonts.notoSansJp(),
          titleLarge: GoogleFonts.notoSansJp(),
          titleMedium: GoogleFonts.notoSansJp(),
          titleSmall: GoogleFonts.notoSansJp(),
          bodyLarge: GoogleFonts.notoSansJp(),
          bodyMedium: GoogleFonts.notoSansJp(),
          bodySmall: GoogleFonts.notoSansJp(),
          labelLarge: GoogleFonts.notoSansJp(),
          labelMedium: GoogleFonts.notoSansJp(),
          labelSmall: GoogleFonts.notoSansJp(),
        ),
      ),
      routerConfig: router,
    );
  }
}
