import 'package:flutter/material.dart';

import 'captura_odometro_colors.dart';

/// Contenedor con borde punteado para zona de foto (proporción rectangular 16:9).
class DashedBorderBox extends StatelessWidget {
  const DashedBorderBox({
    super.key,
    required this.child,
    this.aspectRatio = 16 / 9,
    this.height,
  });

  final Widget child;
  final double aspectRatio;
  /// Si se define, se usa altura fija en lugar de [aspectRatio] (compatibilidad).
  final double? height;

  @override
  Widget build(BuildContext context) {
    final painted = CustomPaint(
      painter: _DashedRectPainter(
        color: CapturaOdometroColors.dashedBorder(context),
        strokeWidth: 2,
        gap: 6,
        dashLength: 8,
        radius: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
      ),
    );

    if (height != null) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: painted,
      );
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: painted,
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  _DashedRectPainter({
    required this.color,
    this.strokeWidth = 2,
    this.gap = 4,
    this.dashLength = 8,
    this.radius = 8,
  });

  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ));

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final segment = metric.extractPath(distance, distance + dashLength);
        canvas.drawPath(segment, paint);
        distance += dashLength + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
