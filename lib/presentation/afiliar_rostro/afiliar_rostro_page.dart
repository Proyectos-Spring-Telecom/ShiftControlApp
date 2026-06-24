import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_format_utils.dart';
import '../../data/models/afiliar_rostro_operador_info.dart';
import '../widgets/app_alert_banner.dart';
import 'afiliar_rostro_colors.dart';
import 'afiliar_rostro_provider.dart';
import 'face_affiliation_capture_page.dart';
import 'models/face_affiliation_capture_result.dart';

/// Pantalla para registro y afiliación de rostro del operador.
class AfiliarRostroPage extends ConsumerStatefulWidget {
  const AfiliarRostroPage({super.key});

  @override
  ConsumerState<AfiliarRostroPage> createState() => _AfiliarRostroPageState();
}

class _AfiliarRostroPageState extends ConsumerState<AfiliarRostroPage> {
  bool _rostrosAfiliado = false;
  String? _fechaAfiliacion;

  String? _validarDatosOperador(AfiliarRostroOperadorInfo operador) {
    if (operador.nombre.trim().isEmpty) {
      return 'El nombre es obligatorio para afiliar el rostro.';
    }
    if (operador.apellidoPaterno.trim().isEmpty) {
      return 'El apellido paterno es obligatorio para afiliar el rostro.';
    }
    if (operador.apellidoMaterno.trim().isEmpty) {
      return 'El apellido materno es obligatorio para afiliar el rostro.';
    }
    final tel = operador.telefono.trim();
    if (tel.isEmpty) {
      return 'El teléfono es obligatorio para afiliar el rostro.';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(tel)) {
      return 'El teléfono debe contener exactamente 10 dígitos.';
    }
    return null;
  }

  Future<void> _capturarRostro(AfiliarRostroOperadorInfo operador) async {
    if (_rostrosAfiliado) return;

    final errorDatos = _validarDatosOperador(operador);
    if (errorDatos != null) {
      showAppAlertError(context, message: errorDatos);
      return;
    }

    final result = await Navigator.of(context).push<FaceAffiliationCaptureResult>(
      MaterialPageRoute<FaceAffiliationCaptureResult>(
        builder: (_) => FaceAffiliationCapturePage(
          nombre: operador.nombre,
          paterno: operador.apellidoPaterno,
          materno: operador.apellidoMaterno,
          telefono: operador.telefono,
        ),
      ),
    );

    if (!mounted || result == null) return;

    if (result.yaRegistrado) {
      showAppAlertInfo(
        context,
        title: 'Rostro registrado',
        message: result.mensaje ??
            'El rostro ya ha sido registrado previamente en el sistema.',
      );
      return;
    }

    setState(() {
      _rostrosAfiliado = true;
      _fechaAfiliacion = formatearFechaHoraActual();
    });

    showAppAlertSuccess(
      context,
      message: 'Rostro afiliado correctamente.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final operadorAsync = ref.watch(afiliarRostroOperadorProvider);

    return Scaffold(
      backgroundColor: AfiliarRostroColors.background(context),
      appBar: AppBar(
        backgroundColor: AfiliarRostroColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AfiliarRostroColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Afiliar Rostro',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AfiliarRostroColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: operadorAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorOperador(context),
              data: (operador) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel(context, 'Información del operador'),
                      const SizedBox(height: 8),
                      _buildOperadorCard(context, operador),
                      if (_rostrosAfiliado) ...[
                        const SizedBox(height: 16),
                        _buildAfiliadoBanner(context),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          operadorAsync.maybeWhen(
            data: (operador) => _buildCapturarButton(context, operador),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorOperador(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AfiliarRostroColors.textSecondary(context)),
            const SizedBox(height: 16),
            Text(
              'No fue posible cargar la información del operador.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AfiliarRostroColors.textPrimary(context),
                  ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => ref.invalidate(afiliarRostroOperadorProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAfiliadoBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AfiliarRostroColors.statusSuccess.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AfiliarRostroColors.statusSuccess.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: AfiliarRostroColors.statusSuccess),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rostro afiliado',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AfiliarRostroColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (_fechaAfiliacion != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _fechaAfiliacion!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AfiliarRostroColors.textSecondary(context),
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AfiliarRostroColors.textSecondary(context),
      ),
    );
  }

  Widget _buildOperadorCard(BuildContext context, AfiliarRostroOperadorInfo operador) {
    final camposHabilitados = !_rostrosAfiliado;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AfiliarRostroColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AfiliarRostroColors.outline(context)),
      ),
      child: Column(
        children: [
          _buildOperadorTextField(
            context,
            label: 'Nombre',
            value: operador.nombre,
            leadingIcon: Icons.badge_outlined,
            enabled: camposHabilitados,
          ),
          const SizedBox(height: 8),
          _buildOperadorTextField(
            context,
            label: 'Apellido paterno',
            value: operador.apellidoPaterno,
            leadingIcon: Icons.person_outline,
            enabled: camposHabilitados,
          ),
          const SizedBox(height: 8),
          _buildOperadorTextField(
            context,
            label: 'Apellido materno',
            value: operador.apellidoMaterno,
            leadingIcon: Icons.person_outline,
            enabled: camposHabilitados,
          ),
          const SizedBox(height: 8),
          _buildOperadorTextField(
            context,
            label: 'Teléfono',
            value: operador.telefono,
            leadingIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            enabled: camposHabilitados,
          ),
        ],
      ),
    );
  }

  Widget _buildOperadorTextField(
    BuildContext context, {
    required String label,
    required String value,
    required IconData leadingIcon,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AfiliarRostroColors.textPrimary(context),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AfiliarRostroColors.inputBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AfiliarRostroColors.outline(context)),
          ),
          child: Row(
            children: [
              Icon(
                leadingIcon,
                size: 20,
                color: AfiliarRostroColors.textSecondary(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  initialValue: value,
                  readOnly: true,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  style: TextStyle(color: AfiliarRostroColors.textPrimary(context)),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                    filled: true,
                    fillColor: AfiliarRostroColors.inputBackground(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCapturarButton(BuildContext context, AfiliarRostroOperadorInfo operador) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _rostrosAfiliado ? null : () => _capturarRostro(operador),
            style: ElevatedButton.styleFrom(
              backgroundColor: AfiliarRostroColors.buttonPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AfiliarRostroColors.textSecondary(context),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _rostrosAfiliado ? Icons.check_circle_outline : Icons.camera_alt_outlined,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _rostrosAfiliado ? 'Rostro afiliado' : 'Capturar rostro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
