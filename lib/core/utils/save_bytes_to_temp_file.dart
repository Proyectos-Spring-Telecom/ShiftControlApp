import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

import 'save_bytes_to_temp_file_stub.dart'
    if (dart.library.io) 'save_bytes_to_temp_file_io.dart' as impl;

Future<XFile> saveBytesToTempFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) {
  return impl.saveBytesToTempFile(
    bytes: bytes,
    fileName: fileName,
    mimeType: mimeType,
  );
}
