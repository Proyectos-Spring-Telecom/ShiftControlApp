import 'dart:io';
import 'dart:typed_data';

/// En plataformas con dart:io lee los bytes del archivo en [path].
Future<Uint8List?> readFileBytes(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) return await f.readAsBytes();
  } catch (_) {}
  return null;
}
