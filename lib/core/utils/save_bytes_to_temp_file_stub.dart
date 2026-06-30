import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

Future<XFile> saveBytesToTempFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  return XFile.fromData(bytes, mimeType: mimeType, name: fileName);
}
