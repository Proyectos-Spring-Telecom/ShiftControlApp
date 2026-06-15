import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Vista rectangular estándar (16:9) para evidencias fotográficas capturadas.
class CapturedEvidenceImage extends StatelessWidget {
  const CapturedEvidenceImage({
    super.key,
    required this.bytes,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 12,
  });

  final Uint8List bytes;
  final double aspectRatio;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          bytes,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
