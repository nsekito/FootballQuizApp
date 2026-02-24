import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ad_provider.dart';
import '../services/ad_service.dart';

/// リワード広告の読み込み・表示を共通化するヘルパー。
///
/// 各画面で重複していた広告ロジックを一元管理する。
/// [loadRewardedAd] で事前読み込み、[showRewardedAd] で表示＋報酬コールバック。
class RewardedAdHelper {
  final WidgetRef _ref;
  final VoidCallback _onStateChanged;
  final bool Function() _isMounted;

  bool isLoadingAd = false;
  bool isAdReady = false;

  RewardedAdHelper({
    required WidgetRef ref,
    required VoidCallback onStateChanged,
    required bool Function() isMounted,
  })  : _ref = ref,
        _onStateChanged = onStateChanged,
        _isMounted = isMounted;

  AdService get _adService => _ref.read(adServiceProvider);

  /// リワード広告を事前に読み込む。
  Future<void> loadRewardedAd() async {
    isLoadingAd = true;
    _onStateChanged();

    await _adService.loadRewardedAd(
      onRewarded: (_, __) {},
      onError: (error) {
        debugPrint('リワード広告の読み込みに失敗しました: $error');
        if (_isMounted()) {
          isLoadingAd = false;
          isAdReady = false;
          _onStateChanged();
        }
      },
    );

    if (_isMounted()) {
      isLoadingAd = false;
      isAdReady = _adService.isRewardedAdReady;
      _onStateChanged();
    }
  }

  /// リワード広告を表示し、成功時に [onRewarded] を呼ぶ。
  ///
  /// 広告が未読み込みの場合は自動で読み込みを試みる。
  /// 失敗時は [context] を使ってSnackBarでエラーを表示する。
  /// 戻り値: 広告が正常に表示されたかどうか。
  Future<bool> showRewardedAd({
    required BuildContext context,
    required Future<void> Function() onRewarded,
  }) async {
    if (isLoadingAd) return false;

    if (!_adService.isRewardedAdReady) {
      await loadRewardedAd();
      if (!_adService.isRewardedAdReady) {
        if (_isMounted() && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('広告の読み込みに失敗しました。しばらくしてから再度お試しください。'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return false;
      }
    }

    final success = await _adService.showRewardedAd(
      onRewarded: (_, __) async {
        await onRewarded();
      },
      onError: (error) {
        debugPrint('リワード広告の表示に失敗しました: $error');
        if (_isMounted() && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('広告の表示に失敗しました'),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );

    if (!success && _isMounted() && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('広告を表示できませんでした。しばらくしてから再度お試しください。'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    return success;
  }
}
