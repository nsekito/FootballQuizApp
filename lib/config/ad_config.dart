import 'package:flutter/foundation.dart';

/// 広告設定を管理するクラス
///
/// デバッグビルドはテスト用ID、リリースビルドは本番用IDを自動で使います。
class AdConfig {
  // テスト用広告ID（Google提供）
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  // 本番用広告ID
  static const String productionRewardedAdUnitId = 'ca-app-pub-3503998658068569/5673150572';
  static const String productionBannerAdUnitId = 'ca-app-pub-3503998658068569/1738040927';

  /// 広告を非表示にするかどうか（ストア用スクリーンショット撮影時のみtrue）
  static const bool hideAdsForScreenshot = false;

  /// リワード広告のユニットIDを取得
  static String get rewardedAdUnitId {
    return kReleaseMode ? productionRewardedAdUnitId : testRewardedAdUnitId;
  }

  /// バナー広告のユニットIDを取得
  static String get bannerAdUnitId {
    return kReleaseMode ? productionBannerAdUnitId : testBannerAdUnitId;
  }
}
