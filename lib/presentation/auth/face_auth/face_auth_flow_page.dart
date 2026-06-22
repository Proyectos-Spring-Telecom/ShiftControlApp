import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_alert_banner.dart';
import 'face_auth_capture_page.dart';
import 'face_auth_colors.dart';

/// Flujo: captura doble → liveness → embed → validateFace → sesión ShiftControl.
class FaceAuthFlowPage extends ConsumerStatefulWidget {
  const FaceAuthFlowPage({super.key});

  @override
  ConsumerState<FaceAuthFlowPage> createState() => _FaceAuthFlowPageState();
}

class _FaceAuthFlowPageState extends ConsumerState<FaceAuthFlowPage> {
  Uint8List? _capture1;
  Uint8List? _capture2;
  bool _isValidating = false;
  bool _redirectingToLogin = false;
  String? _livenessFailedReason;
  bool _validateFace404 = false;

  void _clearTemporaryState() {
    _capture1 = null;
    _capture2 = null;
  }

  Future<void> _returnToLogin({
    required String title,
    required String message,
  }) async {
    if (_redirectingToLogin || !mounted) return;
    _redirectingToLogin = true;

    _clearTemporaryState();
    setState(() {
      _isValidating = false;
      _livenessFailedReason = null;
      _validateFace404 = false;
    });

    if (!mounted) return;
    showAppAlertBanner(
      context,
      type: AppAlertType.error,
      title: title,
      message: message,
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteConstants.login,
      (_) => false,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openDoubleCapture());
  }

  Future<({double? latitud, double? longitud})> _tryGetLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return (latitud: null, longitud: null);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (latitud: null, longitud: null);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return (latitud: position.latitude, longitud: position.longitude);
    } catch (e) {
      debugPrint('[FaceAuth] ubicación no disponible: $e');
      return (latitud: null, longitud: null);
    }
  }

  Future<void> _openDoubleCapture() async {
    final result = await Navigator.of(context).push<List<Uint8List>>(
      MaterialPageRoute<List<Uint8List>>(
        builder: (_) => FaceAuthCapturePage(
          title: 'Captura de tu rostro',
          subtitle: 'Coloca tu rostro dentro del marco.',
          autoCapture: true,
          autoCaptureDelaySeconds: 2,
          twoCaptures: true,
        ),
      ),
    );
    if (!mounted) return;
    if (result == null || result.length < 2) {
      Navigator.of(context).pop();
      return;
    }
    final c1 = result[0];
    final c2 = result[1];
    if (c1.length < 100 || c2.length < 100) {
      showAppAlertBanner(
        context,
        type: AppAlertType.error,
        title: 'Capturas incompletas',
        message: 'No se pudieron obtener las dos capturas correctamente. Por favor, intente de nuevo.',
      );
      _openDoubleCapture();
      return;
    }
    debugPrint('[FaceAuth] Paso 3 - Capturas: imagen1=${c1.length} bytes, imagen2=${c2.length} bytes (guardadas en memoria, se envían a liveness-check)');
    setState(() {
      _capture1 = c1;
      _capture2 = c2;
    });
    _runLivenessAndValidate();
  }

  Future<void> _runLivenessAndValidate() async {
    final c1 = _capture1;
    final c2 = _capture2;
    if (c1 == null || c2 == null) return;
    setState(() => _isValidating = true);
    try {
      final ubicacion = await _tryGetLocation();
      final result = await ref.read(faceAuthServiceProvider).livenessEmbedAndValidateFace(
            capture1: c1,
            capture2: c2,
            latitud: ubicacion.latitud,
            longitud: ubicacion.longitud,
          );
      if (!mounted) return;
      await ref.read(authRepositoryProvider).saveSession(
            result.user,
            result.session.token,
            refreshToken: result.session.refreshToken,
            expiresIn: result.session.expiresIn,
          );
      await ref.read(authControllerProvider.notifier).checkAuth();
      if (!mounted) return;
      _clearTemporaryState();
      showAppAlertBanner(
        context,
        type: AppAlertType.success,
        title: 'Bienvenido',
        message: 'Iniciaste sesión con reconocimiento facial.',
      );
      Navigator.of(context).pushReplacementNamed(RouteConstants.home);
    } on AuthException catch (e) {
      if (!mounted) return;
      await _returnToLogin(
        title: 'Error',
        message: e.message.isNotEmpty ? e.message : 'No fue posible validar tu rostro. Intenta de nuevo.',
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      await _returnToLogin(
        title: 'Error de conexión',
        message: e.message.isNotEmpty ? e.message : 'No fue posible comunicarse con el servidor. Intenta nuevamente.',
      );
    } on SocketException catch (_) {
      if (!mounted) return;
      await _returnToLogin(
        title: 'Error de conexión',
        message: 'No fue posible comunicarse con el servidor. Intenta nuevamente.',
      );
    } on TimeoutException catch (_) {
      if (!mounted) return;
      await _returnToLogin(
        title: 'Error de conexión',
        message: 'No fue posible comunicarse con el servidor. Intenta nuevamente.',
      );
    } catch (e, st) {
      debugPrint('! FaceAuthFlowPage error: $e\n$st');
      if (!mounted) return;
      await _returnToLogin(
        title: 'Error',
        message: 'No fue posible validar tu rostro. Intenta de nuevo.',
      );
    } finally {
      if (mounted && !_redirectingToLogin) {
        setState(() => _isValidating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) {
      return Scaffold(
        backgroundColor: FaceAuthColors.background(context),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'Verificando tu identidad',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: FaceAuthColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estamos validando tu rostro para confirmar que eres tú. Esto tomará solo unos segundos.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: FaceAuthColors.textSecondary(context),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Analizando....',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FaceAuthColors.placeholder(context),
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_validateFace404) {
      return Scaffold(
        backgroundColor: FaceAuthColors.background(context),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.face_retouching_natural, size: 64, color: FaceAuthColors.textSecondary(context)),
                  const SizedBox(height: 24),
                  Text(
                    'Rostro no reconocido',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: FaceAuthColors.textPrimary(context),
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Es posible que no esté registrado en el sistema. Intente de nuevo o use otro método de inicio de sesión.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: FaceAuthColors.textSecondary(context),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _validateFace404 = false);
                        _openDoubleCapture();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FaceAuthColors.buttonPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Volver al login',
                      style: TextStyle(color: FaceAuthColors.textSecondary(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_livenessFailedReason != null) {
      return Scaffold(
        backgroundColor: FaceAuthColors.background(context),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 64, color: FaceAuthColors.textSecondary(context)),
                  const SizedBox(height: 24),
                  Text(
                    'No pudimos verificar tu rostro',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: FaceAuthColors.textPrimary(context),
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Después de varios intentos no logramos validar tu rostro (posible foto o pantalla), mantén tu rostro centrado y evita cubrirlo con lentes oscuros, gorra u otros objetos.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: FaceAuthColors.textSecondary(context),
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _livenessFailedReason = null);
                        _openDoubleCapture();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FaceAuthColors.buttonPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Volver al login',
                      style: TextStyle(color: FaceAuthColors.textSecondary(context)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
