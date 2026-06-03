import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'escanear_vehiculo_colors.dart';

class EscanearVehiculoPage extends StatefulWidget {
  const EscanearVehiculoPage({
    super.key,
    this.onVehiculoEscaneado,
    this.onIngresarManualmente,
  });

  final void Function(String vehiculoId)? onVehiculoEscaneado;
  final VoidCallback? onIngresarManualmente;

  @override
  State<EscanearVehiculoPage> createState() => _EscanearVehiculoPageState();
}

class _EscanearVehiculoPageState extends State<EscanearVehiculoPage> {
  MobileScannerController? _scannerController;
  bool _isScanned = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      _scannerController = MobileScannerController();
      await _scannerController!.start();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanned = true);
        if (widget.onVehiculoEscaneado != null) {
          widget.onVehiculoEscaneado!(barcode.rawValue!);
        } else {
          Navigator.of(context).pop(barcode.rawValue);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EscanearVehiculoColors.background(context),
      appBar: AppBar(
        backgroundColor: EscanearVehiculoColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: EscanearVehiculoColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Escanear Vehículo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: EscanearVehiculoColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              'Escanea la placa del vehículo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: EscanearVehiculoColors.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coloca la placa del vehículo dentro del marco.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EscanearVehiculoColors.textSecondary(context),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Expanded(
              child: _buildQRScanner(context),
            ),
            const SizedBox(height: 24),
            Text(
              'Alinea la placa dentro del cuadro para\nidentificar la unidad automáticamente',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: EscanearVehiculoColors.textSecondary(context),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildScannerIcon(context),
            const SizedBox(height: 24),
            _buildRegresarButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildQRScanner(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.85;
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  if (_hasError || _scannerController == null)
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_2,
                              size: 80,
                              color: EscanearVehiculoColors.textSecondary(context).withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _hasError 
                                  ? 'Cámara no disponible'
                                  : 'Iniciando cámara...',
                              style: TextStyle(
                                color: EscanearVehiculoColors.textSecondary(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_2,
                                  size: 80,
                                  color: EscanearVehiculoColors.textSecondary(context).withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Cámara no disponible',
                                  style: TextStyle(
                                    color: EscanearVehiculoColors.textSecondary(context),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _QRFramePainter(),
                    ),
                  ),
                  if (!_hasError && _scannerController != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _buildScanLine(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanLine() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, value, child) {
        return Padding(
          padding: EdgeInsets.only(top: value * 200 + 20),
          child: Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  EscanearVehiculoColors.qrBorder,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildScannerIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: EscanearVehiculoColors.scannerIcon.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.document_scanner_outlined,
        color: EscanearVehiculoColors.scannerIcon,
        size: 32,
      ),
    );
  }

  Widget _buildRegresarButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: () {
          if (widget.onIngresarManualmente != null) {
            widget.onIngresarManualmente!();
          } else {
            Navigator.of(context).pop();
          }
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: EscanearVehiculoColors.buttonSecondary(context),
          foregroundColor: EscanearVehiculoColors.textPrimary(context),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_back, size: 20),
            const SizedBox(width: 8),
            Text(
              'Regresar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: EscanearVehiculoColors.textPrimary(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QRFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = EscanearVehiculoColors.qrBorder
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 40.0;
    const radius = 16.0;

    final topLeft = Offset.zero;
    final topRight = Offset(size.width, 0);
    final bottomLeft = Offset(0, size.height);
    final bottomRight = Offset(size.width, size.height);

    canvas.drawLine(
      Offset(topLeft.dx, topLeft.dy + cornerLength),
      Offset(topLeft.dx, topLeft.dy + radius),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, radius * 2, radius * 2),
      3.14159,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(topLeft.dx + radius, topLeft.dy),
      Offset(topLeft.dx + cornerLength, topLeft.dy),
      paint,
    );

    canvas.drawLine(
      Offset(topRight.dx - cornerLength, topRight.dy),
      Offset(topRight.dx - radius, topRight.dy),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(topRight.dx - radius * 2, topRight.dy, radius * 2, radius * 2),
      -1.5708,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(topRight.dx, topRight.dy + radius),
      Offset(topRight.dx, topRight.dy + cornerLength),
      paint,
    );

    canvas.drawLine(
      Offset(bottomLeft.dx, bottomLeft.dy - cornerLength),
      Offset(bottomLeft.dx, bottomLeft.dy - radius),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(bottomLeft.dx, bottomLeft.dy - radius * 2, radius * 2, radius * 2),
      3.14159,
      -1.5708,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(bottomLeft.dx + radius, bottomLeft.dy),
      Offset(bottomLeft.dx + cornerLength, bottomLeft.dy),
      paint,
    );

    canvas.drawLine(
      Offset(bottomRight.dx - cornerLength, bottomRight.dy),
      Offset(bottomRight.dx - radius, bottomRight.dy),
      paint,
    );
    canvas.drawArc(
      Rect.fromLTWH(bottomRight.dx - radius * 2, bottomRight.dy - radius * 2, radius * 2, radius * 2),
      0,
      1.5708,
      false,
      paint,
    );
    canvas.drawLine(
      Offset(bottomRight.dx, bottomRight.dy - radius),
      Offset(bottomRight.dx, bottomRight.dy - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
