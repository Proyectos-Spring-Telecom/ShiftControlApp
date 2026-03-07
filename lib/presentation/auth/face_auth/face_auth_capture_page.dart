import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'face_auth_colors.dart';

/// Pantalla reutilizable para capturar el rostro (encuadre tipo KYC).
/// Abre la cámara frontal automáticamente y muestra un marco óvalo; devuelve la imagen en bytes.
/// Si [autoCapture] es true, toma la foto automáticamente tras [autoCaptureDelaySeconds] sin usar botón.
/// Si [twoCaptures] es true: captura 1 (rostro de frente, mensaje "Mantenga la posición al frente", captura en 2 s) → mensaje "Gira un poco el rostro..." → captura 2; devuelve [bytes1, bytes2] para usar en /embed/liveness-check.
class FaceAuthCapturePage extends StatefulWidget {
  const FaceAuthCapturePage({
    super.key,
    required this.title,
    this.subtitle = 'Coloca tu rostro dentro del marco.',
    this.onCaptured,
    this.onCancel,
    this.autoCapture = false,
    this.autoCaptureDelaySeconds = 3,
    this.twoCaptures = false,
  });

  final String title;
  final String subtitle;
  final void Function(Uint8List imageBytes)? onCaptured;
  final VoidCallback? onCancel;
  /// Si true, captura automáticamente tras el delay sin botón "Capturar".
  final bool autoCapture;
  final int autoCaptureDelaySeconds;
  /// Si true, hace dos capturas en la misma pantalla (mensaje 2 s entre ellas) y devuelve ambas.
  final bool twoCaptures;

  @override
  State<FaceAuthCapturePage> createState() => _FaceAuthCapturePageState();
}

class _FaceAuthCapturePageState extends State<FaceAuthCapturePage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _cameraError = false;
  Uint8List? _imageBytes;
  bool _isCapturing = false;
  int? _autoCaptureCountdown;
  bool _waitingForSecondCapture = false;
  int? _secondCaptureCountdown;
  bool _capture1Success = false;
  bool _capture2Success = false;
  Uint8List? _firstCaptureBytes;
  final ImagePicker _picker = ImagePicker();

  static const Color _ovalSuccessGreen = Color(0xFF2E7D32);

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
      _cameras = await availableCameras();
      final front = _cameras!.where((c) => c.lensDirection == CameraLensDirection.front).firstOrNull;
      final camera = front ?? _cameras!.first;
      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _cameraError = false;
        });
        if (widget.autoCapture || widget.twoCaptures) _startAutoCapture();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraReady = false;
          _cameraError = true;
        });
      }
    }
  }

  Future<void> _takePhotoFromCamera() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    setState(() => _isCapturing = true);
    try {
      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _imageBytes = bytes);
    } catch (e) {
      if (mounted) setState(() => _isCapturing = false);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _startAutoCapture() async {
    final delay = widget.autoCaptureDelaySeconds;
    for (var i = delay; i >= 1 && mounted; i--) {
      setState(() => _autoCaptureCountdown = i);
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    setState(() => _autoCaptureCountdown = 0);
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final XFile file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (widget.twoCaptures) {
        setState(() {
          _firstCaptureBytes = bytes;
          _autoCaptureCountdown = null;
          _capture1Success = true;
          _waitingForSecondCapture = true;
          _secondCaptureCountdown = 2;
        });
        for (var i = 2; i >= 1 && mounted; i--) {
          setState(() => _secondCaptureCountdown = i);
          await Future<void>.delayed(const Duration(seconds: 1));
        }
        if (!mounted) return;
        setState(() {
          _waitingForSecondCapture = false;
          _secondCaptureCountdown = null;
        });
        final XFile file2 = await _cameraController!.takePicture();
        final bytes2 = await file2.readAsBytes();
        if (!mounted) return;
        setState(() => _capture2Success = true);
        await Future<void>.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;
        Navigator.of(context).pop(<Uint8List>[bytes, bytes2]);
      } else {
        widget.onCaptured?.call(bytes);
        if (widget.onCaptured == null) {
          Navigator.of(context).pop(bytes);
        }
      }
    } catch (e) {
      if (mounted) setState(() {
        _autoCaptureCountdown = null;
        _waitingForSecondCapture = false;
        _secondCaptureCountdown = null;
      });
    }
  }

  Future<void> _takePhotoFromPicker() async {
    setState(() => _isCapturing = true);
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );
      if (photo != null && mounted) {
        final bytes = await photo.readAsBytes();
        if (mounted) setState(() => _imageBytes = bytes);
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _confirm() {
    if (_imageBytes != null) {
      widget.onCaptured?.call(_imageBytes!);
      if (widget.onCaptured == null) {
        Navigator.of(context).pop(_imageBytes);
      }
    }
  }

  void _retake() {
    setState(() => _imageBytes = null);
  }

  void _cancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  String _statusMessage() {
    if (widget.twoCaptures && _autoCaptureCountdown != null) {
      return 'Mantenga la posición al frente.';
    }
    if (widget.twoCaptures && _waitingForSecondCapture) {
      return 'Gira un poco el rostro a la derecha o izquierda.';
    }
    return widget.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FaceAuthColors.background(context),
      appBar: AppBar(
        backgroundColor: FaceAuthColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: FaceAuthColors.textPrimary(context)),
          onPressed: _cancel,
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
                _statusMessage(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: FaceAuthColors.textSecondary(context),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _imageBytes != null
                        ? _buildPreview(context)
                        : _buildCameraOrPlaceholder(context),
                    if (_waitingForSecondCapture)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Gira un poco el rostro a la derecha o izquierda.',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_secondCaptureCountdown != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _secondCaptureCountdown == 1
                                        ? 'Segunda captura en 1 segundo…'
                                        : 'Segunda captura en $_secondCaptureCountdown segundos…',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                          color: Colors.white70,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      )
                    else if (widget.autoCapture && _autoCaptureCountdown != null)
                      Container(
                        color: Colors.black45,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _autoCaptureCountdown! > 0
                                    ? '$_autoCaptureCountdown'
                                    : 'Capturando...',
                                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.twoCaptures
                                    ? (_autoCaptureCountdown! > 0
                                        ? (_autoCaptureCountdown == 1
                                            ? 'Captura en 1 segundo.'
                                            : 'Captura en $_autoCaptureCountdown segundos.')
                                        : 'Mantenga la posición al frente.')
                                    : (_autoCaptureCountdown! > 0
                                        ? (_autoCaptureCountdown == 1
                                            ? 'Capturando en 1 segundo'
                                            : 'Capturando en $_autoCaptureCountdown segundos')
                                        : 'Capturando...'),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (widget.autoCapture)
                TextButton(
                  onPressed: _cancel,
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: FaceAuthColors.textSecondary(context)),
                  ),
                )
              else ...[
                if (_imageBytes == null)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_isCameraReady && !_isCapturing)
                          ? _takePhotoFromCamera
                          : (_cameraError && !_isCapturing)
                              ? _takePhotoFromPicker
                              : null,
                      icon: _isCapturing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Icon(Icons.camera_alt_outlined, size: 24),
                      label: Text(
                        _isCapturing
                            ? 'Capturando...'
                            : _cameraError
                                ? 'Abrir cámara'
                                : 'Capturar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FaceAuthColors.buttonPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _retake,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: FaceAuthColors.textPrimary(context),
                            side: BorderSide(color: FaceAuthColors.textSecondary(context)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Tomar otra'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _confirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FaceAuthColors.buttonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Confirmar'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _cancel,
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: FaceAuthColors.textSecondary(context)),
                  ),
                ),
              ],
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
        child: Material(
          color: FaceAuthColors.placeholder(context).withValues(alpha: 0.15),
          child: InkWell(
            onTap: _takePhotoFromPicker,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 72,
                    color: FaceAuthColors.placeholder(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Toca para abrir cámara',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: FaceAuthColors.placeholder(context),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
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
    final ovalSuccess = widget.twoCaptures && (_capture1Success || _capture2Success);
    final frameColor = ovalSuccess ? _ovalSuccessGreen : FaceAuthColors.frameBorder(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _cameraController!.value.previewSize?.height ?? 1,
                    height: _cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _OvalFramePainter(
                frameColor: frameColor,
                backgroundColor: Colors.black54,
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
          painter: _OvalFramePainter(
            frameColor: FaceAuthColors.frameBorder(context),
            backgroundColor: Colors.transparent,
          ),
          child: Center(
            child: _OvalClip(
              width: _ovalWidth(constraints.maxWidth),
              height: _ovalHeight(constraints.maxHeight),
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreview(BuildContext context) {
    return Center(
      child: _OvalClip(
        width: 280,
        height: 360,
        child: Image.memory(
          _imageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }

  double _ovalWidth(double maxWidth) {
    return (maxWidth - 48).clamp(240.0, 320.0);
  }

  double _ovalHeight(double maxHeight) {
    return (maxHeight * 0.75).clamp(300.0, 420.0);
  }
}

/// Marco óvalo: recorte exterior oscuro y borde elíptico azul.
class _OvalFramePainter extends CustomPainter {
  _OvalFramePainter({required this.frameColor, required this.backgroundColor});

  final Color frameColor;
  final Color backgroundColor;

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

/// Recorte en forma de óvalo (elipse).
class _OvalClip extends StatelessWidget {
  const _OvalClip({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _OvalClipper(width: width, height: height),
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}

class _OvalClipper extends CustomClipper<Path> {
  _OvalClipper({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromLTWH(0, 0, width, height));
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
