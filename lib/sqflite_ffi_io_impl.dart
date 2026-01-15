// デスクトッププラットフォーム用の実装（実際の初期化コード）
// このファイルはWindows/Linux/macOSでのみコンパイルされる
// Android/iOSでは条件付きインポートにより読み込まれない

// ignore: avoid_relative_lib_imports
import 'dart:io' show Platform;

// 条件付きインポート: デスクトッププラットフォームのみ
import 'sqflite_ffi_io_impl_stub.dart'
    if (dart.library.ffi) 'sqflite_ffi_io_impl_ffi.dart' as ffi_impl;

void initFfi() {
  // Windows/Linux/macOSでのみ実行
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    ffi_impl.initFfiImpl();
  }
}
