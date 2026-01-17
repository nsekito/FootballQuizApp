// Webプラットフォーム以外用のスタブ
import 'package:sqflite/sqflite.dart';

// スタブ用のダミー変数（実際には使用されない）
DatabaseFactory get databaseFactoryFfiWeb => throw UnsupportedError(
  'sqflite_common_ffi_web is only supported on web platform',
);
