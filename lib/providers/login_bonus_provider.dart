import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/login_bonus_service.dart';
import 'user_data_provider.dart';
import '../constants/game_config.dart';

/// ログインボーナスサービスのプロバイダー
final loginBonusServiceProvider = Provider<LoginBonusService>((ref) {
  return LoginBonusService();
});

/// ログインボーナスの状態
class LoginBonusStatus {
  final bool canClaim;
  final int streakDays;
  final int points;
  final String? lastDate;
  final String currentDate;
  final bool hasClaimedToday;
  final bool hasWatchedAd;

  LoginBonusStatus({
    required this.canClaim,
    required this.streakDays,
    required this.points,
    required this.lastDate,
    required this.currentDate,
    required this.hasClaimedToday,
    required this.hasWatchedAd,
  });

  LoginBonusStatus copyWith({
    bool? canClaim,
    int? streakDays,
    int? points,
    String? lastDate,
    String? currentDate,
    bool? hasClaimedToday,
    bool? hasWatchedAd,
  }) {
    return LoginBonusStatus(
      canClaim: canClaim ?? this.canClaim,
      streakDays: streakDays ?? this.streakDays,
      points: points ?? this.points,
      lastDate: lastDate ?? this.lastDate,
      currentDate: currentDate ?? this.currentDate,
      hasClaimedToday: hasClaimedToday ?? this.hasClaimedToday,
      hasWatchedAd: hasWatchedAd ?? this.hasWatchedAd,
    );
  }
}

/// ログインボーナスの状態を管理するプロバイダー
final loginBonusStatusProvider =
    StateNotifierProvider<LoginBonusNotifier, LoginBonusStatus>((ref) {
  final service = ref.watch(loginBonusServiceProvider);
  return LoginBonusNotifier(service, ref);
});

class LoginBonusNotifier extends StateNotifier<LoginBonusStatus> {
  final LoginBonusService _service;
  final Ref _ref;
  int? _claimedPoints;
  bool _hasWatchedAd = false;

  LoginBonusNotifier(this._service, this._ref)
      : super(LoginBonusStatus(
          canClaim: false,
          streakDays: 0,
          points: 0,
          lastDate: null,
          currentDate: '',
          hasClaimedToday: false,
          hasWatchedAd: false,
        )) {
    _loadStatus();
  }

  /// 状態を読み込む
  Future<void> _loadStatus() async {
    final status = await _service.getLoginBonusStatus();
    final currentDate = _service.getCurrentDateString();
    final hasClaimedToday = status['lastDate'] == currentDate;
    
    state = LoginBonusStatus(
      canClaim: status['canClaim'] as bool,
      streakDays: status['streakDays'] as int,
      points: status['points'] as int,
      lastDate: status['lastDate'] as String?,
      currentDate: status['currentDate'] as String,
      hasClaimedToday: hasClaimedToday,
      hasWatchedAd: _hasWatchedAd,
    );
  }

  /// ログインボーナスを受け取る
  Future<Map<String, dynamic>> claimLoginBonus() async {
    if (!state.canClaim) {
      throw Exception('今日は既にログインボーナスを受け取りました');
    }

    final result = await _service.claimLoginBonus();
    final points = result['points'] as int;
    final exp = result['exp'] as int;
    _claimedPoints = points;
    
    // ポイントを追加
    await _ref.read(totalPointsProvider.notifier).addPoints(points);
    
    // 7日連続の場合はEXPも付与
    if (exp > 0) {
      await _ref.read(totalExpProvider.notifier).addExp(exp);
    }
    
    // 状態を即座に更新（hasClaimedTodayをtrueに設定）
    final currentDate = _service.getCurrentDateString();
    state = state.copyWith(
      canClaim: false,
      hasClaimedToday: true,
      lastDate: currentDate,
    );
    
    // その後、非同期で完全な状態を読み込む
    _loadStatus();
    
    return result;
  }

  /// 広告視聴後にポイントをAD_BONUS.LOGIN_BONUS_MULTIPLIER倍にする
  Future<void> multiplyPointsWithAd() async {
    if (_claimedPoints == null) {
      throw Exception('ログインボーナスを受け取っていません');
    }
    
    if (_hasWatchedAd) {
      throw Exception('既に広告を視聴済みです');
    }

    // AD_BONUS.LOGIN_BONUS_MULTIPLIER（2.0倍）を適用
    final additionalPoints = (_claimedPoints! * AD_BONUS.loginBonusMultiplier).floor() - _claimedPoints!;
    await _ref.read(totalPointsProvider.notifier).addPoints(additionalPoints);
    _hasWatchedAd = true;
    
    // 状態を更新
    state = state.copyWith(hasWatchedAd: true);
  }
  
  // 後方互換性のため、doublePointsWithAdメソッドを残す
  @Deprecated('Use multiplyPointsWithAd instead')
  Future<void> doublePointsWithAd() async {
    await multiplyPointsWithAd();
  }

  /// 状態をリフレッシュ
  Future<void> refresh() async {
    await _loadStatus();
  }

  /// ログインボーナスをリセットする（管理者用）
  Future<void> resetLoginBonus() async {
    await _service.resetLoginBonus();
    _claimedPoints = null;
    _hasWatchedAd = false;
    await _loadStatus();
  }
}
