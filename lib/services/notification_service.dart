import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

/// ローカル通知を管理するサービス
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;
  static const String _lastNotificationDateKey = 'last_notification_date';

  /// 通知サービスを初期化
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('通知サービス: Webプラットフォームではスキップします');
      return;
    }

    if (_isInitialized) {
      return;
    }

    try {
      // Android初期化設定
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS初期化設定
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 通知タップ時のコールバックを設定
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Android通知チャンネルを作成
      if (Platform.isAndroid) {
        await _createNotificationChannel();
      }

      _isInitialized = true;
      debugPrint('通知サービスを初期化しました');
    } catch (e) {
      debugPrint('通知サービスの初期化に失敗しました: $e');
    }
  }

  /// Android通知チャンネルを作成
  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'weekly_recap_channel', // チャンネルID
      'Weekly Recap', // チャンネル名
      description: '新しいMATCH DAY問題の通知', // 説明
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 通知権限をリクエスト
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return false;
    }

    try {
      if (Platform.isAndroid) {
        // Android 13以上では権限リクエストが必要
        final androidImplementation = _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          // Android 13以上の場合、areNotificationsEnabledで確認
          // 権限がなければ、ユーザーに設定画面を開いてもらう必要がある
          final enabled = await androidImplementation.areNotificationsEnabled();
          return enabled ?? true; // nullの場合はtrueを返す（Android 12以下）
        }
        return true; // Android 12以下では権限は自動的に付与される
      } else if (Platform.isIOS) {
        // iOSでは初期化時に権限をリクエスト済み
        final iosImplementation = _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImplementation != null) {
          final settings = await iosImplementation.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return settings ?? false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('通知権限のリクエストに失敗しました: $e');
      return false;
    }
  }

  /// 通知権限が付与されているか確認
  Future<bool> isPermissionGranted() async {
    if (kIsWeb) {
      return false;
    }

    try {
      if (Platform.isAndroid) {
        final androidImplementation = _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidImplementation != null) {
          final granted = await androidImplementation.areNotificationsEnabled();
          return granted ?? false;
        }
        return true;
      } else if (Platform.isIOS) {
        final iosImplementation = _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        
        if (iosImplementation != null) {
          final settings = await iosImplementation.checkPermissions();
          return settings?.isEnabled ?? false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('通知権限の確認に失敗しました: $e');
      return false;
    }
  }

  /// Weekly Recap新着通知を送信
  /// 
  /// [date] 日付（YYYY-MM-DD形式）
  /// [leagueType] リーグタイプ（オプション）
  Future<void> showWeeklyRecapNotification({
    required String date,
    String? leagueType,
  }) async {
    if (kIsWeb) {
      return;
    }

    // 既にこの日付の通知を送信済みかチェック
    final lastNotificationDate = await _getLastNotificationDate();
    if (lastNotificationDate == date) {
      debugPrint('既に$dateの通知を送信済みです');
      return;
    }

    // 権限を確認
    final hasPermission = await isPermissionGranted();
    if (!hasPermission) {
      debugPrint('通知権限が付与されていません');
      return;
    }

    try {
      final leagueTypeText = leagueType == 'j1' 
          ? 'J1リーグ' 
          : leagueType == 'europe' 
              ? 'ヨーロッパサッカー' 
              : '';

      final title = '新しいMATCH DAYが利用可能です！';
      final body = leagueTypeText.isNotEmpty
          ? '今週の$leagueTypeTextの試合結果をクイズで確認しましょう'
          : '今週の試合結果をクイズで確認しましょう';

      // ペイロードに遷移先のルート情報を設定
      final payload = '/configuration?category=match_recap';

      const androidDetails = AndroidNotificationDetails(
        'weekly_recap_channel',
        'Weekly Recap',
        channelDescription: '新しいMATCH DAY問題の通知',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(
        0, // 通知ID
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      // 通知送信日時を保存
      await _saveLastNotificationDate(date);
      debugPrint('Weekly Recap通知を送信しました: $date');
    } catch (e) {
      debugPrint('通知の送信に失敗しました: $e');
    }
  }

  /// 通知タップ時の処理
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('通知がタップされました: ${response.payload}');
    
    // ペイロードが設定されている場合、GoRouterで遷移
    if (response.payload != null && response.payload!.isNotEmpty) {
      // GoRouterのインスタンスを取得するために、グローバルなNavigatorKeyを使用
      // または、後でmain.dartから設定できるようにする
      _pendingPayload = response.payload;
    }
  }

  String? _pendingPayload;

  /// 保留中の通知ペイロードを取得（アプリ起動時に呼び出し）
  String? getPendingPayload() {
    final payload = _pendingPayload;
    _pendingPayload = null; // 取得後はクリア
    return payload;
  }

  /// 通知タップ時のペイロードを取得（外部から呼び出し可能）
  String? getNotificationPayload() {
    // このメソッドは、アプリ起動時に通知から起動された場合のペイロードを取得するために使用
    // 実装は必要に応じて追加
    return null;
  }

  /// 前回通知を送信した日付を取得
  Future<String?> _getLastNotificationDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastNotificationDateKey);
    } catch (e) {
      debugPrint('前回通知日時の取得に失敗しました: $e');
      return null;
    }
  }

  /// 前回通知を送信した日付を保存
  Future<void> _saveLastNotificationDate(String date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastNotificationDateKey, date);
    } catch (e) {
      debugPrint('前回通知日時の保存に失敗しました: $e');
    }
  }

  /// すべての通知をキャンセル
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      return;
    }
    await _notifications.cancelAll();
  }
}
