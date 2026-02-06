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

  // 難易度別カラー
  static const difficultyEasy = Color(0xFF81C784); // 明るい緑
  static const difficultyNormal = Color(0xFF42A5F5); // ブルー
  static const difficultyHard = Color(0xFFFFA726); // オレンジ
  static const difficultyExtreme = Color(0xFFE53935); // 赤

  // 状態カラー
  static const success = Color(0xFF4CAF50); // 正解
  static const error = Color(0xFFD32F2F); // 不正解
  static const selected = Color(0xFFE8F5E9); // 選択中

  // グラデーション用カラー
  static const gradientStart = Color(0xFF4A7C59); // プライマリー開始
  static const gradientEnd = Color(0xFF6B9B7A); // プライマリー終了
  static const accentGradientStart = Color(0xFFF5A623); // アクセント開始
  static const accentGradientEnd = Color(0xFFFFB84D); // アクセント終了

  // シャドウカラー
  static const shadowLight = Color(0x1A000000); // 軽いシャドウ
  static const shadowMedium = Color(0x33000000); // 中程度のシャドウ
  static const shadowDark = Color(0x4D000000); // 濃いシャドウ

  // オーバーレイカラー
  static const overlayLight = Color(0x1AFFFFFF); // 軽いオーバーレイ
  static const overlayMedium = Color(0x33FFFFFF); // 中程度のオーバーレイ
  static const overlayDark = Color(0x4DFFFFFF); // 濃いオーバーレイ

  // Stitchデザイン用カラー
  static const techBlue = Color(0xFF0066FF); // テックブルー
  static const techGreen = Color(0xFF32D74B); // テックグリーン
  static const techWhite = Color(0xFFF8FAFC); // テックホワイト
  static const techIndigo = Color(0xFF0F172A); // テックインディゴ
  static const techGrey = Color(0xFFE2E8F0); // テックグレー
  static const slate100 = Color(0xFFF1F5F9); // スレート100
  static const slate200 = Color(0xFFE2E8F0); // スレート200
  static const slate400 = Color(0xFF94A3B8); // スレート400
  static const slate500 = Color(0xFF64748B); // スレート500

  // Stitchデザイン用カラー（新規追加）
  static const stitchEmerald = Color(0xFF10B981); // エメラルドグリーン（Configuration/Result用）
  static const stitchCyan = Color(0xFF06b6d4); // シアン（Quiz用）
  static const stitchBackgroundLight = Color(0xFFF8FAFC); // 背景ライト
  static const stitchBackgroundDark = Color(0xFF0F172A); // 背景ダーク
  static const stitchCardLight = Color(0xB3FFFFFF); // カードライト（70%透明度）
  static const stitchCardDark = Color(0xB31E293B); // カードダーク（70%透明度）
  
  // ガラスモーフィズム用カラー
  static const glassWhite = Color(0xB3FFFFFF); // ガラス白（70%透明度）
  static const glassBorder = Color(0x33FFFFFF); // ガラスボーダー（20%透明度）
}
