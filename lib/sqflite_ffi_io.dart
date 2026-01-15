// デスクトッププラットフォーム用の実装（Windows/Linux/macOSのみ）
import 'dart:io' show Platform;

// 条件付きインポート: デスクトッププラットフォームのみ
import 'sqflite_ffi_io_stub.dart'
    if (dart.library.io) 'sqflite_ffi_io_impl.dart' as ffi_impl;

void initDatabaseFactory() {
  // Windows/Linux/macOSでのみ実行
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    ffi_impl.initFfi();
  }
}
