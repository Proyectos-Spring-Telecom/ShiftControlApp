import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_alert_banner.dart';
import '../inicio_turno/inicio_turno_colors.dart';
import 'plate_image_crop.dart';

/// Pantalla de identificación de placa por cámara.
/// Flujo: 1) Tap "Seleccionar vehículo" → abre cámara. 2) Captura foto de la placa (takePicture).
/// 3) POST /plate/read con la imagen (file, plate.jpg, image/jpeg, bytes tal cual). 4) Respuesta 200/201 → plate_number. 5) Se muestra plate_number en el input.
class IdentificarPlacaPage extends ConsumerStatefulWidget {
  const IdentificarPlacaPage({
    super.key,
    this.onPlacaIdentificada,
    this.onRegresar,
  });

  final void Function(String vehiculoId)? onPlacaIdentificada;
  final VoidCallback? onRegresar;

  @override
  ConsumerState<IdentificarPlacaPage> createState() => _IdentificarPlacaPageState();
}

class _IdentificarPlacaPageState extends ConsumerState<IdentificarPlacaPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraReady = false;
  bool _cameraError = false;
  bool _isLoading = false;
  bool _autoCaptureDone = false;

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
      final back = _cameras!.where((c) => c.lensDirection == CameraLensDirection.back).firstOrNull;
      final camera = back ?? _cameras!.first;
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
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (mounted && !_autoCaptureDone) _captureAndSend();
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

  Future<void> _captureAndSend() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isLoading) return;

    final token = await ref.read(authLocalDatasourceProvider).getStoredToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión expirada. Inicie sesión de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      // takePicture() → readAsBytes() → bytes enviados sin redimensionar ni reajustar calidad (JPEG tal cual)
      final XFile file = await _cameraController!.takePicture();
      print('Plate capture file.path: ${file.path}');
      debugPrint('Plate capture file.path: ${file.path}');
      final bytes = await file.readAsBytes();
      if (!mounted) return;

      final imageBytes = bytes.toList();
      if (imageBytes.isEmpty) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo capturar la imagen. Intente de nuevo.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      // Tamaño mínimo razonable para un JPEG (evitar envío de imagen corrupta)
      if (imageBytes.length < 500) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La imagen capturada no es válida. Coloque la placa en el marco y toque Reintentar.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      // Validar firma JPEG (FF D8 FF) para asegurar que el servidor reciba imagen válida
      final isJpeg = imageBytes.length >= 3 &&
          imageBytes[0] == 0xFF &&
          imageBytes[1] == 0xD8 &&
          imageBytes[2] == 0xFF;
      if (!isJpeg) {
        setState(() => _isLoading = false);
        debugPrint('Plate read: imagen sin firma JPEG válida (primeros bytes: ${imageBytes.take(3).toList()})');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Formato de imagen no válido. Toque Reintentar.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Recortar al área del recuadro verde antes de enviar al API
      final layoutWidth = MediaQuery.sizeOf(context).width;
      final layoutHeight = MediaQuery.sizeOf(context).height -
          (AppBar().preferredSize.height + MediaQuery.paddingOf(context).top);
      final previewSize = _cameraController!.value.previewSize;
      final previewWidth = previewSize != null ? previewSize.height.toDouble() : layoutWidth;
      final previewHeight = previewSize != null ? previewSize.width.toDouble() : layoutHeight;

      final cropResult = await cropPlateImage(
        imageBytes: imageBytes,
        layoutWidth: layoutWidth,
        layoutHeight: layoutHeight,
        previewWidth: previewWidth,
        previewHeight: previewHeight,
        saveCroppedForDebug: true,
      );

      final bytesToSend = cropResult?.bytes ?? imageBytes;
      if (cropResult?.savedPath != null) {
        print('Plate crop guardado en: ${cropResult!.savedPath}');
        debugPrint('Plate crop guardado en: ${cropResult.savedPath}');
      }
      if (cropResult == null) {
        debugPrint('Plate read: recorte falló, se envía imagen completa');
      } else {
        debugPrint('Plate read: enviando imagen recortada al API (${bytesToSend.length} bytes, JPEG)');
      }

      final result = await ref.read(plateReadRemoteDatasourceProvider).readPlate(
            token,
            bytesToSend,
          );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _autoCaptureDone = true;
      });
      _returnPlaca(result.plateNumber);
      if (mounted) {
        showAppAlertBanner(
          context,
          type: AppAlertType.success,
          title: 'Placa identificada',
          message: result.plateNumber,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Plate read: NetworkException code=${e.code}, message=${e.message}');
      String msg = e.message;
      if (e.code == '400' || e.code == '404') {
        msg = 'No se detectó placa. Coloque la placa en el marco y toque Reintentar.';
      } else if (e.code == '403') {
        msg = 'Servicio de placa no habilitado para esta solución.';
      } else if (e.code == '503') {
        msg = 'Servicio no disponible. Intente más tarde.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al leer la placa. Intente de nuevo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _returnPlaca(String plateNumber) {
    if (widget.onPlacaIdentificada != null) {
      widget.onPlacaIdentificada!(plateNumber);
    } else {
      Navigator.of(context).pop(plateNumber);
    }
  }

  void _regresar() {
    if (widget.onRegresar != null) {
      widget.onRegresar!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: InicioTurnoColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: InicioTurnoColors.textPrimary(context)),
          onPressed: _regresar,
        ),
        title: Text(
          'Identificar vehículo por placa',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: InicioTurnoColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraError)
            _buildErrorPlaceholder()
          else if (!_isCameraReady || _cameraController == null)
            _buildLoadingCamera()
          else
            _buildCameraPreview(),
          _buildOverlay(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActions(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 64, color: InicioTurnoColors.placeholder(context)),
            const SizedBox(height: 16),
            Text(
              'No se pudo abrir la cámara.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: InicioTurnoColors.textPrimary(context),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _regresar,
              style: OutlinedButton.styleFrom(
                foregroundColor: InicioTurnoColors.buttonPrimary,
                side: BorderSide(color: InicioTurnoColors.buttonPrimary),
              ),
              child: const Text('Regresar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCamera() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Abriendo cámara...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = controller.value.previewSize;
        if (size == null) return const SizedBox.shrink();
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.height,
            height: size.width,
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            'Coloca la placa del vehículo dentro del marco',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 280,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF66BB6A), width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : _regresar,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Regresar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _captureAndSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: InicioTurnoColors.buttonPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Identificando placa',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                          ),
                        ],
                      )
                    : const Text('Reintentar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
