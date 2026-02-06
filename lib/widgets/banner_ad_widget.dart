import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

/// バナー広告を表示するウィジェット
/// 
/// 画面下部に固定表示されるバナー広告です。
/// エラー時は自動的に非表示になります。
class BannerAdWidget extends StatefulWidget {
  /// 広告のサイズ
  final AdSize? adSize;
  
  /// 広告の配置位置（デフォルトは下部中央）
  final Alignment alignment;
  
  const BannerAdWidget({
    super.key,
    this.adSize,
    this.alignment = Alignment.bottomCenter,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  /// バナー広告を読み込む
  void _loadBannerAd() {
    // Webプラットフォームでは広告を表示しない
    if (kIsWeb) {
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      size: widget.adSize ?? AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) {
            setState(() {
              _isAdReady = true;
            });
          }
          debugPrint('バナー広告の読み込みが完了しました');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('バナー広告の読み込みに失敗しました: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdReady = false;
            });
          }
          // エラー時は再試行しない（無限ループを防ぐ）
        },
        onAdOpened: (_) {
          debugPrint('バナー広告が開かれました');
        },
        onAdClosed: (_) {
          debugPrint('バナー広告が閉じられました');
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Webプラットフォームでは何も表示しない
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    // 広告が読み込まれていない、またはエラーの場合は何も表示しない
    if (!_isAdReady || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // 広告の高さに合わせてコンテナを作成
    final adHeight = (widget.adSize?.height ?? 50.0).toDouble();
    
    return Container(
      alignment: widget.alignment,
      width: double.infinity,
      height: adHeight,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
