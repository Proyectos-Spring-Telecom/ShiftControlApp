import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/face_affiliation_request.dart';
import '../auth/face_auth/face_auth_colors.dart';
import '../widgets/app_alert_banner.dart';
import 'face_affiliation_provider.dart';
import 'face_affiliation_single_capture_page.dart';
import 'models/face_affiliation_capture_result.dart';

class _AffiliationCaptureStep {
  const _AffiliationCaptureStep({
    required this.sampleIndex,
    required this.subtitle,
    required this.filename,
    required this.instructionDelaySeconds,
  });

  final int sampleIndex;
  final String subtitle;
  final String filename;
  final int instructionDelaySeconds;
}

/// Flujo de afiliación con la misma experiencia visual que el login facial.
class FaceAffiliationCapturePage extends ConsumerStatefulWidget {
  const FaceAffiliationCapturePage({
    super.key,
    required this.nombre,
    required this.paterno,
    required this.materno,
    required this.telefono,
  });

  final String nombre;
  final String paterno;
  final String materno;
  final String telefono;

  @override
  ConsumerState<FaceAffiliationCapturePage> createState() =>
      _FaceAffiliationCapturePageState();
}

class _FaceAffiliationCapturePageState extends ConsumerState<FaceAffiliationCapturePage> {
  static const _instructionDelaySeconds = 3;

  static const _steps = [
    _AffiliationCaptureStep(
      sampleIndex: 1,
      subtitle: 'Mira al frente',
      filename: 'frente.jpg',
      instructionDelaySeconds: _instructionDelaySeconds,
    ),
    _AffiliationCaptureStep(
      sampleIndex: 2,
      subtitle: 'Gira un poco el rostro a la izquierda',
      filename: 'izquierda.jpg',
      instructionDelaySeconds: _instructionDelaySeconds,
    ),
    _AffiliationCaptureStep(
      sampleIndex: 3,
      subtitle: 'Gira un poco el rostro a la derecha',
      filename: 'derecha.jpg',
      instructionDelaySeconds: _instructionDelaySeconds,
    ),
  ];

  bool _isProcessing = false;
  int _currentStepIndex = 0;

  final List<Uint8List> _captures = [];
  final List<List<double>> _embeddings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlow());
  }

  Future<void> _runFlow() async {
    if (_isProcessing) return;

    for (var i = _currentStepIndex; i < _steps.length; i++) {
      final step = _steps[i];
      final bytes = await _openCapture(step);
      if (!mounted) return;

      if (bytes == null) {
        Navigator.of(context).pop();
        return;
      }

      if (bytes.length < 100) {
        showAppAlertError(
          context,
          message: 'No se pudo obtener la captura correctamente. Intente nuevamente.',
        );
        i--;
        continue;
      }

      setState(() => _isProcessing = true);

      try {
        final embedding = await ref.read(faceAffiliationRepositoryProvider).validarPoseYGenerarEmbedding(
              sampleIndex: step.sampleIndex,
              filename: step.filename,
              imageBytes: bytes.toList(),
            );

        if (!mounted) return;

        if (_captures.length > i) {
          _captures[i] = bytes;
          _embeddings[i] = embedding;
        } else {
          _captures.add(bytes);
          _embeddings.add(embedding);
        }

        setState(() {
          _currentStepIndex = i + 1;
          _isProcessing = false;
        });
      } on AuthException catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        showAppAlertError(context, message: e.message);
        i--;
        continue;
      } on NetworkException catch (e) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        showAppAlertError(context, message: e.message);
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() => _isProcessing = false);
        showAppAlertError(
          context,
          message: 'No fue posible validar tu rostro. Intente nuevamente.',
        );
        i--;
        continue;
      }
    }

    if (!mounted || _embeddings.length < 3) return;

    setState(() => _isProcessing = true);

    try {
      final response = await ref.read(faceAffiliationRepositoryProvider).registrarRostro(
            request: FaceAffiliationRequest(
              nombre: widget.nombre.trim(),
              paterno: widget.paterno.trim(),
              materno: widget.materno.trim(),
              telefono: widget.telefono.trim(),
              embeddingsList: _embeddings,
            ),
          );

      if (!mounted) return;

      if (!response.success) {
        setState(() => _isProcessing = false);
        showAppAlertError(
          context,
          message: 'No fue posible afiliar el rostro. Intente nuevamente.',
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(
        FaceAffiliationCaptureResult.exitoso(rostroId: response.id ?? 0),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      showAppAlertError(context, message: e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (e.code == '409') {
        Navigator.of(context).pop(
          FaceAffiliationCaptureResult.conflictoRegistro(mensaje: e.message),
        );
        return;
      }
      showAppAlertError(context, message: e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      showAppAlertError(
        context,
        message: 'No fue posible afiliar el rostro.\nIntenta nuevamente.',
      );
    }
  }

  Future<Uint8List?> _openCapture(_AffiliationCaptureStep step) async {
    final result = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        builder: (_) => FaceAffiliationSingleCapturePage(
          instruction: step.subtitle,
          secondsAfterInstruction: step.instructionDelaySeconds,
        ),
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
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
                  'Estamos validando tu rostro para confirmar tu registro. Esto tomará solo unos segundos.',
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

    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
