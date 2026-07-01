import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/utils/web_viewport_lock.dart';
import '../widgets/camera_preview_layer.dart';
import '../auth/face_auth/face_auth_colors.dart';

/// Captura facial de una sola toma para afiliación de rostro.
/// Espera [secondsAfterInstruction] **después** de mostrar la instrucción en pantalla.
class FaceAffiliationSingleCapturePage extends StatefulWidget {
  const FaceAffiliationSingleCapturePage({
    super.key,
    required this.instruction,
    this.title = 'Captura de tu rostro',
    this.secondsAfterInstruction = 3,
  });

  final String title;
  final String instruction;
  final int secondsAfterInstruction;

  @override
  State<FaceAffiliationSingleCapturePage> createState() =>
      _FaceAffiliationSingleCapturePageState();
}

class _FaceAffiliationSingleCapturePageState extends State<FaceAffiliationSingleCapturePage> {
  CameraController? _cameraController;
  bool _isCameraReady = false;
  bool _cameraError = false;
  bool _isCapturing = false;
  int? _countdown;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.where((c) => c.lensDirection == CameraLensDirection.front).firstOrNull;
      final camera = front ?? cameras.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (kIsWeb) {
        lockWebViewportAfterCameraPermission();
      }
      if (!mounted) return;
      setState(() => _isCameraReady = true);
      await _waitInstructionThenCapture();
    } catch (_) {
      if (mounted) setState(() => _cameraError = true);
    }
  }

  Future<void> _waitInstructionThenCapture() async {
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;

    final seconds = widget.secondsAfterInstruction;
    for (var remaining = seconds; remaining >= 1; remaining--) {
      if (!mounted) return;
      setState(() => _countdown = remaining);
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;
    setState(() => _countdown = null);
    await _takePhotoAndReturn();
  }

  Future<void> _takePhotoAndReturn() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    setState(() => _isCapturing = true);
    try {
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop(bytes);
    } catch (_) {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FaceAuthColors.background(context),
      appBar: AppBar(
        backgroundColor: FaceAuthColors.background(context),
        surfaceTintColor: kIsWeb ? Colors.transparent : null,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: FaceAuthColors.textPrimary(context)),
          onPressed: _isCapturing ? null : _cancel,
        ),
        title: Text(
          widget.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: FaceAuthColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                widget.instruction,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: FaceAuthColors.textSecondary(context),
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildCameraOrPlaceholder(context),
                    if (_countdown != null && _isCameraReady)
                      IgnorePointer(
                        child: Container(
                          color: Colors.black26,
                          alignment: Alignment.center,
                          child: Text(
                            '$_countdown',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                    if (_isCapturing)
                      Container(
                        color: Colors.black45,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _isCapturing ? null : _cancel,
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: FaceAuthColors.textSecondary(context)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOrPlaceholder(BuildContext context) {
    if (_cameraError) {
      return _buildOvalFrame(
        context,
        child: Center(
          child: Text(
            'No se pudo abrir la cámara',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FaceAuthColors.placeholder(context),
                ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!_isCameraReady || _cameraController == null) {
      return _buildOvalFrame(
        context,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Preparando cámara...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: FaceAuthColors.placeholder(context),
                    ),
              ),
            ],
          ),
        ),
      );
    }
    return _buildCameraWithOvalOverlay(context);
  }

  Widget _buildCameraWithOvalOverlay(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (kIsWeb)
              Positioned.fill(
                child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
              ),
            CameraPreviewLayer(controller: _cameraController!),
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _AffiliationOvalFramePainter(
                frameColor: FaceAuthColors.ovalBorderGreen,
                backgroundColor: Colors.black54,
                overColor: FaceAuthColors.ovalBorderGreenOver,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOvalFrame(BuildContext context, {required Widget child}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _AffiliationOvalFramePainter(
            frameColor: FaceAuthColors.frameBorder(context),
            backgroundColor: Colors.transparent,
          ),
          child: Center(
            child: SizedBox(
              width: _ovalWidth(constraints.maxWidth),
              height: _ovalHeight(constraints.maxHeight),
              child: child,
            ),
          ),
        );
      },
    );
  }

  double _ovalWidth(double maxWidth) => (maxWidth - 48).clamp(240.0, 320.0);

  double _ovalHeight(double maxHeight) => (maxHeight * 0.75).clamp(300.0, 420.0);
}

class _AffiliationOvalFramePainter extends CustomPainter {
  _AffiliationOvalFramePainter({
    required this.frameColor,
    required this.backgroundColor,
    this.overColor,
  });

  final Color frameColor;
  final Color backgroundColor;
  final Color? overColor;

  @override
  void paint(Canvas canvas, Size size) {
    const padding = 24.0;
    final w = (size.width - padding * 2).clamp(240.0, 320.0);
    final h = (size.height * 0.75).clamp(300.0, 420.0);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: w,
      height: h,
    );

    if (backgroundColor != Colors.transparent) {
      final outer = Path()..addRect(Offset.zero & size);
      final oval = Path()..addOval(rect);
      final scrim = Path.combine(PathOperation.difference, outer, oval);
      canvas.drawPath(scrim, Paint()..color = backgroundColor);
    }

    if (overColor != null) {
      canvas.drawOval(
        rect,
        Paint()
          ..color = overColor!.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6,
      );
    }
    canvas.drawOval(
      rect,
      Paint()
        ..color = frameColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
