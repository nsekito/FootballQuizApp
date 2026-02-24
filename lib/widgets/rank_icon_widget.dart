import 'package:flutter/material.dart';
import '../models/user_rank.dart';

/// ランクに応じたボーダーカラーを返す。
List<Color> getRankBorderColors(UserRank rank) {
  switch (rank) {
    case UserRank.ballPicker:
    case UserRank.coneSetter:
    case UserRank.waterCarrier:
    case UserRank.bibDistributor:
    case UserRank.trainee:
    case UserRank.benchPlayer:
      return [Colors.grey.shade400, Colors.grey.shade600];
    case UserRank.substitute:
    case UserRank.starter:
      return [Colors.blue.shade300, Colors.blue.shade600];
    case UserRank.numberTen:
    case UserRank.captain:
      return [Colors.green.shade300, Colors.green.shade600];
    case UserRank.domesticMVP:
    case UserRank.overseasTransfer:
      return [Colors.amber.shade300, Colors.orange.shade600];
    case UserRank.worldClass:
      return [Colors.purple.shade300, Colors.purple.shade600];
    case UserRank.ballonDor:
      return [Colors.deepOrange.shade300, Colors.deepOrange.shade700];
    case UserRank.legend:
      return [Colors.red.shade300, Colors.red.shade700];
  }
}

/// ランクに応じたグロー効果の色を返す。
Color getRankGlowColor(UserRank rank) {
  switch (rank) {
    case UserRank.ballPicker:
    case UserRank.coneSetter:
    case UserRank.waterCarrier:
    case UserRank.bibDistributor:
    case UserRank.trainee:
    case UserRank.benchPlayer:
      return Colors.grey.shade400;
    case UserRank.substitute:
    case UserRank.starter:
      return Colors.blue.shade400;
    case UserRank.numberTen:
    case UserRank.captain:
      return Colors.green.shade400;
    case UserRank.domesticMVP:
    case UserRank.overseasTransfer:
      return Colors.amber.shade400;
    case UserRank.worldClass:
      return Colors.purple.shade400;
    case UserRank.ballonDor:
      return Colors.deepOrange.shade400;
    case UserRank.legend:
      return Colors.red.shade400;
  }
}

/// 枠付きランクアイコンウィジェット。
///
/// home_screen と result_screen で共用。
class RankIconWidget extends StatelessWidget {
  final UserRank rank;
  final double size;

  static const String _rankIconsPath = 'assets/images/rank_icons';

  const RankIconWidget({
    super.key,
    required this.rank,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final borderColors = getRankBorderColors(rank);
    final glowColor = getRankGlowColor(rank);
    final borderWidth = size * 0.05;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: borderWidth,
          color: borderColors[0],
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.6),
            blurRadius: size * 0.15,
            spreadRadius: size * 0.05,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.4),
            blurRadius: size * 0.25,
            spreadRadius: size * 0.1,
          ),
          BoxShadow(
            color: glowColor.withValues(alpha: 0.2),
            blurRadius: size * 0.35,
            spreadRadius: size * 0.15,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: size * 0.1,
            spreadRadius: -size * 0.05,
          ),
        ],
      ),
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              width: borderWidth * 0.5,
              color: borderColors[1],
            ),
          ),
          child: Image.asset(
            '$_rankIconsPath/${rank.name}.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) =>
                _FallbackRankBadge(rank: rank, size: size),
          ),
        ),
      ),
    );
  }
}

/// ランクアイコン画像がない場合のフォールバック表示。
class _FallbackRankBadge extends StatelessWidget {
  final UserRank rank;
  final double size;

  const _FallbackRankBadge({required this.rank, required this.size});

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData iconData;

    switch (rank) {
      case UserRank.ballPicker:
      case UserRank.coneSetter:
      case UserRank.waterCarrier:
      case UserRank.bibDistributor:
      case UserRank.trainee:
      case UserRank.benchPlayer:
        badgeColor = Colors.grey.shade400;
        iconData = Icons.sports_soccer;
      case UserRank.substitute:
      case UserRank.starter:
        badgeColor = Colors.blue.shade400;
        iconData = Icons.star;
      case UserRank.numberTen:
      case UserRank.captain:
        badgeColor = Colors.green.shade400;
        iconData = Icons.emoji_events;
      case UserRank.domesticMVP:
      case UserRank.overseasTransfer:
        badgeColor = Colors.amber.shade400;
        iconData = Icons.workspace_premium;
      case UserRank.worldClass:
        badgeColor = Colors.purple.shade400;
        iconData = Icons.auto_awesome;
      case UserRank.ballonDor:
        badgeColor = Colors.deepOrange.shade400;
        iconData = Icons.auto_awesome;
      case UserRank.legend:
        badgeColor = Colors.red.shade400;
        iconData = Icons.auto_awesome;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            badgeColor,
            badgeColor.withValues(alpha: 0.7),
            badgeColor.withValues(alpha: 0.5),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        iconData,
        size: size * 0.5,
        color: Colors.white,
      ),
    );
  }
}
