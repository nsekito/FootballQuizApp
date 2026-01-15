// デスクトッププラットフォーム用の実装（FFIを使用）
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void initFfiImpl() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
