import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// レスポンシブ対応のコンテナウィジェット
/// 最大幅を設定し、それ以上広がった場合は中央配置で左右に空白を表示します
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final maxContentWidth = maxWidth ?? AppConstants.maxContentWidth;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: padding != null
            ? Padding(
                padding: padding!,
                child: child,
              )
            : child,
      ),
    );
  }
}
