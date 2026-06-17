import 'package:flutter/material.dart';

/// Abre un visor a pantalla completa con zoom para una imagen de red.
void showNetworkImagePreview(
  BuildContext context, {
  required String imageUrl,
  required String heroTag,
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black87,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(dialogContext).top + 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  tooltip: 'Cerrar',
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
