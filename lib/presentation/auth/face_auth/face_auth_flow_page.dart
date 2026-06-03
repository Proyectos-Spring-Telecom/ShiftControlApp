import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/user_model.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_alert_banner.dart';
import 'face_auth_capture_page.dart';
import 'face_auth_colors.dart';

/// Credenciales internas para el uso de los servicios Face Auth (login API).
const String _faceAuthUsuario = 'admin@shiftcontrol.mx';
const String _faceAuthContrasena = 'P@ssw0rd.';

/// Flujo: login interno → una pantalla con dos capturas (misma pantalla, 2 s entre ellas) → liveness → embed → validateFace.
class FaceAuthFlowPage extends ConsumerStatefulWidget {
  const FaceAuthFlowPage({super.key});

  @override
  ConsumerState<FaceAuthFlowPage> createState() => _FaceAuthFlowPageState();
}

class _FaceAuthFlowPageState extends ConsumerState<FaceAuthFlowPage> {
  String? _token;
  String? _idCliente;
  String? _usuarioFromMe;
  Uint8List? _capture1;
  Uint8List? _capture2;
  bool _isLoadingCredentials = true;
  bool _isValidating = false;
  String? _livenessFailedReason;
  bool _validateFace404 = false;

  Future<void> _start() async {
    setState(() => _isLoadingCredentials = true);
    try {
      final credentials = await ref.read(faceAuthServiceProvider).loginAndGetIdCliente(
            _faceAuthUsuario,
            _faceAuthContrasena,
          );
      if (!mounted) return;
      setState(() {
        _token = credentials.token;
        _idCliente = credentials.idCliente;
        _usuarioFromMe = credentials.usuario;
        _isLoadingCredentials = false;
      });
      _openDoubleCapture();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCredentials = false);
      showAppAlertBanner(context, type: AppAlertType.error, title: 'Error de acceso', message: e.message);
      Navigator.of(context).pop();
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCredentials = false);
      showAppAlertBanner(context, type: AppAlertType.error, title: 'Error de conexión', message: e.message);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCredentials = false);
      showAppAlertBanner(
        context,
        type: AppAlertType.error,
        title: 'Error',
        message: 'No se pudo conectar con el servicio. Intenta de nuevo.',
      );
      Navigator.of(context).pop();
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
    final token = _token;
    final idCliente = _idCliente;
    final c1 = _capture1;
    final c2 = _capture2;
    if (token == null || idCliente == null || c1 == null || c2 == null) return;
    setState(() => _isValidating = true);
    try {
      final validateResult = await ref.read(faceAuthServiceProvider).livenessEmbedAndValidateFace(
            token: token,
            idCliente: idCliente,
            capture1: c1,
            capture2: c2,
          );
      if (!mounted) return;
      final name = [
        validateResult.nombre,
        validateResult.paterno,
        validateResult.materno,
      ].where((e) => e != null && e.isNotEmpty).join(' ');
      final user = UserModel(
        id: idCliente,
        email: _usuarioFromMe ?? _faceAuthUsuario,
        name: name.isNotEmpty ? name : validateResult.nombre,
        apellidoPaterno: validateResult.paterno,
        apellidoMaterno: validateResult.materno,
        userName: _usuarioFromMe,
      );
      await ref.read(authControllerProvider.notifier).setSessionFromFaceAuth(user, token);
      if (!mounted) return;
      showAppAlertBanner(
        context,
        type: AppAlertType.success,
        title: 'Bienvenido',
        message: 'Iniciaste sesión con reconocimiento facial.',
      );
      Navigator.of(context).pushReplacementNamed(RouteConstants.home);
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.code == '404') {
        setState(() => _validateFace404 = true);
      } else {
        if (e.code == 'liveness_failed') {
          setState(() => _livenessFailedReason = e.message);
          // No mostrar banner: se muestra la pantalla completa "No pudimos verificar tu rostro".
        } else {
          showAppAlertBanner(
            context,
            type: AppAlertType.error,
            title: 'Rostro no reconocido',
            message: e.message,
          );
        }
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      showAppAlertBanner(context, type: AppAlertType.error, title: 'Error', message: e.message);
    } catch (e) {
      if (!mounted) return;
      showAppAlertBanner(
        context,
        type: AppAlertType.error,
        title: 'Error',
        message: e is Exception ? e.toString() : 'No se pudo validar tu rostro. Intenta de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
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
    return Scaffold(
      backgroundColor: FaceAuthColors.background(context),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Conectando...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: FaceAuthColors.textPrimary(context),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
