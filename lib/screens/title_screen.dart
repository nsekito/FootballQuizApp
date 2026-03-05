import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../providers/sample_data_provider.dart';
import '../providers/recap_data_provider.dart';

/// タイトル画面
class TitleScreen extends ConsumerStatefulWidget {
  const TitleScreen({super.key});

  @override
  ConsumerState<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends ConsumerState<TitleScreen> {
  bool _isDownloading = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          // 背景画像（画面全体）
          Image.asset(
            'assets/images/title/title_background.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // 画像が存在しない場合は背景色で表示
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: AppColors.techWhite,
                child: const Center(
                  child: Text(
                    'SOCCER QUIZ MASTER',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.techIndigo,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // 画像内STARTボタンのタップ領域
          if (!_isDownloading && _errorMessage == null)
            Positioned(
              bottom: screenHeight * 0.20, // 画面下部から20%の位置
              left: screenWidth * 0.15,    // 画面左から15%の位置
              right: screenWidth * 0.15,   // 画面右から15%の位置
              height: screenHeight * 0.10, // 画面高さの10%
              child: GestureDetector(
                onTap: _handleGameStart,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          
          // ダウンロード中/エラー時のオーバーレイ
          if (_isDownloading || _errorMessage != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: _isDownloading
                    ? _buildDownloadingIndicator()
                    : _buildErrorMessage(),
              ),
            ),
        ],
      ),
    );
  }


  /// ダウンロード中のインジケーターを表示
  Widget _buildDownloadingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
        const SizedBox(height: 24),
        if (_statusMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _statusMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// エラーメッセージを表示
  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.techBlue,
            ),
            child: const Text('再試行'),
          ),
        ],
      ),
    );
  }

  /// GAME STARTボタンが押されたときの処理
  Future<void> _handleGameStart() async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
      _errorMessage = null;
      _statusMessage = 'データをダウンロード中...';
    });

    try {
      // 1. サンプルデータの初期化確認
      setState(() {
        _statusMessage = '初期データを確認中...';
      });
      await ref.read(sampleDataInitializedProvider.future);

      // 2. Weekly Recapデータのダウンロード
      setState(() {
        _statusMessage = 'Weekly Recapデータをダウンロード中...';
      });
      try {
        final recapDataService = ref.read(recapDataServiceProvider);
        await recapDataService.syncWeeklyRecapToDatabase();
      } catch (e) {
        // ネットワークエラーなどは正常な動作としてスキップ
        debugPrint('Weekly Recapダウンロードエラー（スキップ）: $e');
      }

      // 3. その他の更新データがあればダウンロード
      // （現在はWeekly Recapのみのため、ここに将来の拡張用の処理を追加可能）

      // 4. ダウンロード完了後、トップ画面に遷移
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      // 予期しないエラーが発生した場合
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _errorMessage = 'データのダウンロードに失敗しました。\nネットワーク接続を確認してください。';
        });
      }
      debugPrint('タイトル画面でのデータダウンロードエラー: $e');
    }
  }
}
