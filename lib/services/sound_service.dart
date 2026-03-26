import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 短い効果音を再生する。
///
/// [AssetSource] のパスは [AudioCache] のデフォルト接頭辞 `assets/` に対する
/// **相対パス**（例: `sounds/foo.mp3`）とすること。
class SoundService {
  SoundService() : _player = AudioPlayer();

  final AudioPlayer _player;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _player.setPlayerMode(PlayerMode.mediaPlayer);
    await _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.game,
        ),
      ),
    );
    _configured = true;
  }

  Future<void> _playAsset(String relativePath) async {
    try {
      await _ensureConfigured();
      await _player.stop();
      await _player.play(AssetSource(relativePath));
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('SoundService._playAsset($relativePath): $e\n$stackTrace');
      }
    }
  }

  /// タイトルからゲーム開始したとき。
  Future<void> playTitleStart() => _playAsset('sounds/title_start.mp3');

  /// クイズの出題が始まるとき（問題読み込み完了後）。
  Future<void> playQuizStart() => _playAsset('sounds/quiz_start.mp3');

  /// クイズ結果画面を表示したとき。
  Future<void> playQuizResultScreen() => _playAsset('sounds/quiz_result.mp3');

  /// 正解／不正解の SE。
  Future<void> playQuizResult(bool isCorrect) async {
    await _playAsset(
      isCorrect ? 'sounds/quiz_correct.mp3' : 'sounds/quiz_wrong.mp3',
    );
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
