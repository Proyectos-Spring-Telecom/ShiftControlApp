import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Dimensiones del recuadro verde en pantalla (igual que el overlay).
const double kOverlayWidth = 280.0;
const double kOverlayHeight = 120.0;

/// Resultado del recorte: bytes JPEG y ruta del archivo guardado (para debug).
class PlateCropResult {
  const PlateCropResult({
    required this.bytes,
    this.savedPath,
  });
  final List<int> bytes;
  final String? savedPath;
}

/// Calcula el rectángulo de recorte en coordenadas de la imagen capturada.
/// [layoutWidth], [layoutHeight]: tamaño del área donde se dibuja el preview (body).
/// [previewWidth], [previewHeight]: tamaño del contenido del preview (previewSize.height, previewSize.width).
/// [imageWidth], [imageHeight]: dimensiones de la imagen capturada.
/// El recuadro verde está centrado en el layout con tamaño [kOverlayWidth] x [kOverlayHeight].
void _computeCropRect({
  required double layoutWidth,
  required double layoutHeight,
  required double previewWidth,
  required double previewHeight,
  required int imageWidth,
  required int imageHeight,
  required void Function(int x, int y, int w, int h) onRect,
}) {
  if (previewWidth <= 0 || previewHeight <= 0) return;

  final scale = (layoutWidth / previewWidth) > (layoutHeight / previewHeight)
      ? layoutWidth / previewWidth
      : layoutHeight / previewHeight;
  final scaledW = previewWidth * scale;
  final scaledH = previewHeight * scale;
  final offsetX = scaledW > layoutWidth ? (scaledW - layoutWidth) / 2 : 0.0;
  final offsetY = scaledH > layoutHeight ? (scaledH - layoutHeight) / 2 : 0.0;

  final overlayLeft = (layoutWidth - kOverlayWidth) / 2;
  final overlayTop = (layoutHeight - kOverlayHeight) / 2;

  final cropX = (offsetX + overlayLeft) / scale;
  final cropY = (offsetY + overlayTop) / scale;
  final cropW = kOverlayWidth / scale;
  final cropH = kOverlayHeight / scale;

  final scaleX = imageWidth / previewWidth;
  final scaleY = imageHeight / previewHeight;

  int x = (cropX * scaleX).round();
  int y = (cropY * scaleY).round();
  int w = (cropW * scaleX).round();
  int h = (cropH * scaleY).round();

  x = x.clamp(0, imageWidth - 1);
  y = y.clamp(0, imageHeight - 1);
  w = (w.clamp(1, imageWidth - x));
  h = (h.clamp(1, imageHeight - y));

  onRect(x, y, w, h);
}

/// Recorta la imagen capturada al área del recuadro verde y devuelve los bytes JPEG.
/// Opcionalmente guarda la imagen recortada en el directorio de documentos para verificación.
Future<PlateCropResult?> cropPlateImage({
  required List<int> imageBytes,
  required double layoutWidth,
  required double layoutHeight,
  required double previewWidth,
  required double previewHeight,
  bool saveCroppedForDebug = true,
}) async {
  final decoded = img.decodeImage(Uint8List.fromList(imageBytes));
  if (decoded == null) {
    debugPrint('Plate crop: no se pudo decodificar la imagen');
    return null;
  }

  final imageWidth = decoded.width;
  final imageHeight = decoded.height;

  int cropX = 0, cropY = 0, cropW = 0, cropH = 0;
  _computeCropRect(
    layoutWidth: layoutWidth,
    layoutHeight: layoutHeight,
    previewWidth: previewWidth,
    previewHeight: previewHeight,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    onRect: (x, y, w, h) {
      cropX = x;
      cropY = y;
      cropW = w;
      cropH = h;
    },
  );

  if (cropW < 1 || cropH < 1) {
    debugPrint('Plate crop: área de recorte inválida');
    return null;
  }

  final cropped = img.copyCrop(
    decoded,
    x: cropX,
    y: cropY,
    width: cropW,
    height: cropH,
  );

  const jpegQuality = 95;
  final bytes = img.encodeJpg(cropped, quality: jpegQuality);
  if (bytes.isEmpty) {
    debugPrint('Plate crop: no se pudo codificar JPEG');
    return null;
  }

  String? savedPath;
  if (saveCroppedForDebug) {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/plate_crop_debug_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      savedPath = file.path;
      debugPrint('Plate crop: imagen recortada guardada en $savedPath (${bytes.length} bytes)');
    } catch (e) {
      debugPrint('Plate crop: no se pudo guardar debug: $e');
    }
  }

  return PlateCropResult(bytes: bytes.toList(), savedPath: savedPath);
}
