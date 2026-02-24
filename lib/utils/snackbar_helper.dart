import 'package:flutter/material.dart';

/// アプリ全体で使用するSnackBar表示ヘルパー。
///
/// 成功・エラー・警告の表示パターンを統一し、各画面での重複を排除する。
void showSuccessSnackBar(BuildContext context, String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green.shade700,
      duration: duration,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

void showErrorSnackBar(BuildContext context, String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      duration: duration,
    ),
  );
}

void showWarningSnackBar(BuildContext context, String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.orange.shade700,
      duration: duration,
    ),
  );
}
