import 'package:flutter/material.dart';

import '../models/damage_point_model.dart';
import '../registro_danos_colors.dart';
import 'damage_point_widget.dart';

/// ! Widget que muestra la vista del vehículo con puntos interactivos.
/// 
/// Renderiza el contorno del vehículo según la vista seleccionada
/// y superpone los puntos de daño correspondientes.
class VehicleViewWidget extends StatelessWidget {
  const VehicleViewWidget({
    super.key,
    required this.view,
    required this.points,
    required this.onPointTap,
  });

  final VehicleView view;
  final List<DamagePoint> points;
  final void Function(DamagePoint point) onPointTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            Positioned.fill(
              child: _buildVehicleView(),
            ),
            ...points.map((point) {
              final x = point.relativeX * width - 16;
              final y = point.relativeY * height - 16;
              return Positioned(
                left: x,
                top: y,
                child: DamagePointWidget(
                  point: point,
                  onTap: () => onPointTap(point),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildVehicleView() {
    final imagePath = _getImagePath();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
      ),
    );
  }

  String _getImagePath() {
    switch (view) {
      case VehicleView.lateralIzquierdo:
        return 'assets/images/vehicle_lateral_izquierdo.png';
      case VehicleView.lateralDerecho:
        return 'assets/images/vehicle_lateral_derecho.png';
      case VehicleView.frontal:
        return 'assets/images/vehicle_frontal.png';
      case VehicleView.trasera:
        return 'assets/images/vehicle_trasera.png';
    }
  }
}

/// Painter para dibujar el contorno del vehículo.
class _VehiclePainter extends CustomPainter {
  _VehiclePainter({
    required this.view,
    required this.outlineColor,
    required this.fillColor,
  });

  final VehicleView view;
  final Color outlineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = outlineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    switch (view) {
      case VehicleView.lateralIzquierdo:
      case VehicleView.lateralDerecho:
        _drawLateralView(canvas, size, paint, fillPaint, view == VehicleView.lateralDerecho);
        break;
      case VehicleView.frontal:
        _drawFrontalView(canvas, size, paint, fillPaint);
        break;
      case VehicleView.trasera:
        _drawTraseraView(canvas, size, paint, fillPaint);
        break;
    }
  }

  void _drawLateralView(Canvas canvas, Size size, Paint paint, Paint fillPaint, bool flip) {
    final w = size.width;
    final h = size.height;
    
    final vehicleWidth = w * 0.9;
    final vehicleHeight = h * 0.35;
    final offsetX = (w - vehicleWidth) / 2;
    final offsetY = (h - vehicleHeight) / 2;

    canvas.save();
    if (flip) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    final path = Path();
    
    path.moveTo(offsetX + vehicleWidth * 0.05, offsetY + vehicleHeight * 0.7);
    path.lineTo(offsetX + vehicleWidth * 0.08, offsetY + vehicleHeight * 0.5);
    path.quadraticBezierTo(
      offsetX + vehicleWidth * 0.1, offsetY + vehicleHeight * 0.35,
      offsetX + vehicleWidth * 0.15, offsetY + vehicleHeight * 0.35,
    );
    path.lineTo(offsetX + vehicleWidth * 0.3, offsetY + vehicleHeight * 0.35);
    path.lineTo(offsetX + vehicleWidth * 0.38, offsetY + vehicleHeight * 0.1);
    path.lineTo(offsetX + vehicleWidth * 0.7, offsetY + vehicleHeight * 0.1);
    path.lineTo(offsetX + vehicleWidth * 0.85, offsetY + vehicleHeight * 0.35);
    path.lineTo(offsetX + vehicleWidth * 0.95, offsetY + vehicleHeight * 0.35);
    path.quadraticBezierTo(
      offsetX + vehicleWidth * 0.98, offsetY + vehicleHeight * 0.4,
      offsetX + vehicleWidth * 0.95, offsetY + vehicleHeight * 0.7,
    );
    path.lineTo(offsetX + vehicleWidth * 0.05, offsetY + vehicleHeight * 0.7);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    final windowPaint = Paint()
      ..color = outlineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final windowFront = Path();
    windowFront.moveTo(offsetX + vehicleWidth * 0.32, offsetY + vehicleHeight * 0.33);
    windowFront.lineTo(offsetX + vehicleWidth * 0.39, offsetY + vehicleHeight * 0.13);
    windowFront.lineTo(offsetX + vehicleWidth * 0.48, offsetY + vehicleHeight * 0.13);
    windowFront.lineTo(offsetX + vehicleWidth * 0.48, offsetY + vehicleHeight * 0.33);
    windowFront.close();
    canvas.drawPath(windowFront, windowPaint);

    final windowBack = Path();
    windowBack.moveTo(offsetX + vehicleWidth * 0.5, offsetY + vehicleHeight * 0.33);
    windowBack.lineTo(offsetX + vehicleWidth * 0.5, offsetY + vehicleHeight * 0.13);
    windowBack.lineTo(offsetX + vehicleWidth * 0.68, offsetY + vehicleHeight * 0.13);
    windowBack.lineTo(offsetX + vehicleWidth * 0.75, offsetY + vehicleHeight * 0.33);
    windowBack.close();
    canvas.drawPath(windowBack, windowPaint);

    final wheelPaint = Paint()
      ..color = outlineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      Offset(offsetX + vehicleWidth * 0.22, offsetY + vehicleHeight * 0.7),
      vehicleHeight * 0.18,
      wheelPaint,
    );
    canvas.drawCircle(
      Offset(offsetX + vehicleWidth * 0.22, offsetY + vehicleHeight * 0.7),
      vehicleHeight * 0.1,
      wheelPaint,
    );

    canvas.drawCircle(
      Offset(offsetX + vehicleWidth * 0.78, offsetY + vehicleHeight * 0.7),
      vehicleHeight * 0.18,
      wheelPaint,
    );
    canvas.drawCircle(
      Offset(offsetX + vehicleWidth * 0.78, offsetY + vehicleHeight * 0.7),
      vehicleHeight * 0.1,
      wheelPaint,
    );

    canvas.restore();
  }

  void _drawFrontalView(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final w = size.width;
    final h = size.height;
    
    final vehicleWidth = w * 0.6;
    final vehicleHeight = h * 0.5;
    final offsetX = (w - vehicleWidth) / 2;
    final offsetY = (h - vehicleHeight) / 2;

    final path = Path();
    
    path.moveTo(offsetX + vehicleWidth * 0.1, offsetY + vehicleHeight * 0.9);
    path.lineTo(offsetX + vehicleWidth * 0.1, offsetY + vehicleHeight * 0.5);
    path.quadraticBezierTo(
      offsetX + vehicleWidth * 0.1, offsetY + vehicleHeight * 0.35,
      offsetX + vehicleWidth * 0.2, offsetY + vehicleHeight * 0.3,
    );
    path.lineTo(offsetX + vehicleWidth * 0.25, offsetY + vehicleHeight * 0.1);
    path.lineTo(offsetX + vehicleWidth * 0.75, offsetY + vehicleHeight * 0.1);
    path.lineTo(offsetX + vehicleWidth * 0.8, offsetY + vehicleHeight * 0.3);
    path.quadraticBezierTo(
      offsetX + vehicleWidth * 0.9, offsetY + vehicleHeight * 0.35,
      offsetX + vehicleWidth * 0.9, offsetY + vehicleHeight * 0.5,
    );
    path.lineTo(offsetX + vehicleWidth * 0.9, offsetY + vehicleHeight * 0.9);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    final windowPath = Path();
    windowPath.moveTo(offsetX + vehicleWidth * 0.28, offsetY + vehicleHeight * 0.28);
    windowPath.lineTo(offsetX + vehicleWidth * 0.3, offsetY + vehicleHeight * 0.12);
    windowPath.lineTo(offsetX + vehicleWidth * 0.7, offsetY + vehicleHeight * 0.12);
    windowPath.lineTo(offsetX + vehicleWidth * 0.72, offsetY + vehicleHeight * 0.28);
    windowPath.close();
    canvas.drawPath(windowPath, paint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(offsetX + vehicleWidth * 0.25, offsetY + vehicleHeight * 0.55),
        width: vehicleWidth * 0.12,
        height: vehicleHeight * 0.1,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(offsetX + vehicleWidth * 0.75, offsetY + vehicleHeight * 0.55),
        width: vehicleWidth * 0.12,
        height: vehicleHeight * 0.1,
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(offsetX + vehicleWidth * 0.5, offsetY + vehicleHeight * 0.65),
          width: vehicleWidth * 0.35,
          height: vehicleHeight * 0.08,
        ),
        const Radius.circular(4),
      ),
      paint,
    );
  }

  void _drawTraseraView(Canvas canvas, Size size, Paint paint, Paint fillPaint) {
    final w = size.width;
    final h = size.height;
    
    final vehicleWidth = w * 0.6;
    final vehicleHeight = h * 0.5;
    final offsetX = (w - vehicleWidth) / 2;
    final offsetY = (h - vehicleHeight) / 2;

    final path = Path();
    
    path.moveTo(offsetX + vehicleWidth * 0.1, offsetY + vehicleHeight * 0.9);
    path.lineTo(offsetX + vehicleWidth * 0.1, offsetY + vehicleHeight * 0.4);
    path.quadraticBezierTo(
      offsetX + vehicleWidth * 0.1, offsetY + vehicleHeight * 0.25,
      offsetX + vehicleWidth * 0.2, offsetY + vehicleHeight * 0.2,
    );
    path.lineTo(offsetX + vehicleWidth * 0.22, offsetY + vehicleHeight * 0.1);
    path.lineTo(offsetX + vehicleWidth * 0.78, offsetY + vehicleHeight * 0.1);
    path.lineTo(offsetX + vehicleWidth * 0.8, offsetY + vehicleHeight * 0.2);
    path.quadraticBezierTo(
      offsetX + vehicleWidth * 0.9, offsetY + vehicleHeight * 0.25,
      offsetX + vehicleWidth * 0.9, offsetY + vehicleHeight * 0.4,
    );
    path.lineTo(offsetX + vehicleWidth * 0.9, offsetY + vehicleHeight * 0.9);
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);

    final windowPath = Path();
    windowPath.moveTo(offsetX + vehicleWidth * 0.25, offsetY + vehicleHeight * 0.22);
    windowPath.lineTo(offsetX + vehicleWidth * 0.27, offsetY + vehicleHeight * 0.12);
    windowPath.lineTo(offsetX + vehicleWidth * 0.73, offsetY + vehicleHeight * 0.12);
    windowPath.lineTo(offsetX + vehicleWidth * 0.75, offsetY + vehicleHeight * 0.22);
    windowPath.close();
    canvas.drawPath(windowPath, paint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(offsetX + vehicleWidth * 0.2, offsetY + vehicleHeight * 0.45),
          width: vehicleWidth * 0.12,
          height: vehicleHeight * 0.12,
        ),
        const Radius.circular(4),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(offsetX + vehicleWidth * 0.8, offsetY + vehicleHeight * 0.45),
          width: vehicleWidth * 0.12,
          height: vehicleHeight * 0.12,
        ),
        const Radius.circular(4),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(offsetX + vehicleWidth * 0.5, offsetY + vehicleHeight * 0.7),
          width: vehicleWidth * 0.25,
          height: vehicleHeight * 0.08,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _VehiclePainter oldDelegate) {
    return oldDelegate.view != view;
  }
}
