/// 広告設定を管理するクラス
/// 
/// テスト用と本番用の広告IDを切り替え可能にします。
/// 開発中はuseTestAdsをtrueに設定してください。
class AdConfig {
  // テスト用広告ID（Google提供）
  static const String testRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  
  // 本番用広告ID（AdMobでアプリを登録した後に設定）
  // TODO: AdMobでアプリを登録したら、以下のIDを本番用に変更してください
  static const String productionRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String productionBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  
  /// テスト広告を使用するかどうか
  /// 開発中はtrue、本番リリース時はfalseに変更
  static const bool useTestAds = true;
  
  /// リワード広告のユニットIDを取得
  static String get rewardedAdUnitId {
    return useTestAds ? testRewardedAdUnitId : productionRewardedAdUnitId;
  }
  
  /// バナー広告のユニットIDを取得
  static String get bannerAdUnitId {
    return useTestAds ? testBannerAdUnitId : productionBannerAdUnitId;
  }
}
