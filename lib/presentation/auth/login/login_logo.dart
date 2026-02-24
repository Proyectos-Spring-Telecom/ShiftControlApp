import 'package:flutter/material.dart';

const Color _springRed = Color(0xFFE63946);
const Color _telecomCyan = Color(0xFF48CAE4);
const Color _diamondBlue = Color(0xFF1D3557);
const Color _diamondRed = Color(0xFFE63946);

/// Logo SPRING telecom para la pantalla de login.
class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(56, 48),
          painter: _DiamondLogoPainter(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'SPRING',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _springRed,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'telecom',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _telecomCyan,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DiamondLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.5, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height * 0.5)
      ..close();

    canvas.clipPath(path);

    final topPaint = Paint()..color = _diamondBlue;
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height * 0.5), topPaint);

    final bottomPaint = Paint()..color = _diamondRed;
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.5, size.width, size.height),
      bottomPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
