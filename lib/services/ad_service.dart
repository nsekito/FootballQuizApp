import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

/// 広告サービスの実装
/// 
/// Google Mobile Ads SDKを使用して広告の読み込み・表示を管理します。
class AdService {
  static bool _isInitialized = false;
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  
  /// 広告SDKを初期化
  /// 
  /// アプリ起動時に一度だけ呼び出します。
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('広告SDKの初期化が完了しました');
    } catch (e) {
      debugPrint('広告SDKの初期化に失敗しました: $e');
      // エラーが発生してもアプリは動作するようにする
    }
  }
  
  /// リワード広告を読み込む
  /// 
  /// 広告が読み込まれると自動的に_isRewardedAdReadyがtrueになります。
  Future<void> loadRewardedAd({
    required Function(int rewardAmount, String rewardType) onRewarded,
    Function(String error)? onError,
  }) async {
    // 既に読み込み済みの場合は何もしない
    if (_isRewardedAdReady && _rewardedAd != null) {
      return;
    }
    
    // 既存の広告を破棄
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
    
    try {
      await RewardedAd.load(
        adUnitId: AdConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            debugPrint('リワード広告の読み込みが完了しました');
            
            // 広告が閉じられたときの処理
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                debugPrint('リワード広告が閉じられました');
                ad.dispose();
                _rewardedAd = null;
                _isRewardedAdReady = false;
                // 次の広告を事前に読み込む
                loadRewardedAd(onRewarded: onRewarded, onError: onError);
              },
              onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
                debugPrint('リワード広告の表示に失敗しました: $error');
                ad.dispose();
                _rewardedAd = null;
                _isRewardedAdReady = false;
                onError?.call(error.message);
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('リワード広告の読み込みに失敗しました: $error');
            _isRewardedAdReady = false;
            onError?.call(error.message);
          },
        ),
      );
    } catch (e) {
      debugPrint('リワード広告の読み込み中にエラーが発生しました: $e');
      _isRewardedAdReady = false;
      onError?.call(e.toString());
    }
  }
  
  /// リワード広告を表示する
  /// 
  /// 広告が読み込まれていない場合はfalseを返します。
  /// 広告視聴が完了するとonRewardedコールバックが呼ばれます。
  Future<bool> showRewardedAd({
    required Function(int rewardAmount, String rewardType) onRewarded,
    Function(String error)? onError,
  }) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('リワード広告が読み込まれていません');
      // 広告が読み込まれていない場合、読み込みを試みる
      await loadRewardedAd(onRewarded: onRewarded, onError: onError);
      return false;
    }
    
    try {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('報酬を獲得しました: ${reward.amount} ${reward.type}');
          onRewarded(reward.amount.toInt(), reward.type);
        },
      );
      return true;
    } catch (e) {
      debugPrint('リワード広告の表示中にエラーが発生しました: $e');
      onError?.call(e.toString());
      return false;
    }
  }
  
  /// リワード広告が読み込まれているかどうか
  bool get isRewardedAdReady => _isRewardedAdReady;
  
  /// リソースを解放
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
  }
}
