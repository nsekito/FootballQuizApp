// lib/constants/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // メインカラー
  static const primary = Color(0xFF4A7C59); // 深い緑
  static const accent = Color(0xFFF5A623); // ゴールド
  static const background = Color(0xFFF5F3EF); // オフホワイト
  static const textDark = Color(0xFF2C2C2C); // 濃いグレー
  static const textLight = Color(0xFF808080); // 薄いグレー

  // カテゴリ別カラー
  static const categoryRules = Color(0xFFE3F2FD); // 淡い青
  static const categoryHistory = Color(0xFFFFF9E6); // 淡い黄色
  static const categoryTeam = Color(0xFFF3E5F5); // 淡い紫
  static const categoryNews = Color(0xFFFFF3E0); // 淡いオレンジ

  // 難易度別カラー
  static const difficultyEasy = Color(0xFF81C784); // 明るい緑
  static const difficultyNormal = Color(0xFF42A5F5); // ブルー
  static const difficultyHard = Color(0xFFFFA726); // オレンジ
  static const difficultyExtreme = Color(0xFFE53935); // 赤

  // 状態カラー
  static const success = Color(0xFF4CAF50); // 正解
  static const error = Color(0xFFD32F2F); // 不正解
  static const selected = Color(0xFFE8F5E9); // 選択中
}
