import 'dart:io';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';

Future<XFile> saveBytesToTempFile({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return XFile(file.path, mimeType: mimeType, name: fileName);
}
