import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Preview de cámara compartido entre flujos con [CameraPreview] embebido.
///
/// En Flutter Web usa las dimensiones reales del stream (`BoxFit.contain`).
/// En Android/iOS aplica la rotación del sensor nativo (`BoxFit.cover`).
class CameraPreviewLayer extends StatelessWidget {
  const CameraPreviewLayer({
    super.key,
    required this.controller,
  });

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    final preview = _buildPreview(previewSize);

    if (kIsWeb) {
      return Positioned.fill(child: preview);
    }

    return preview;
  }

  Widget _buildPreview(Size? previewSize) {
    if (kIsWeb) {
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: previewSize?.width ?? 1,
            height: previewSize?.height ?? 1,
            child: CameraPreview(controller),
          ),
        ),
      );
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize?.height ?? 1,
            height: previewSize?.width ?? 1,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}
