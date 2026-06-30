import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/save_bytes_to_temp_file.dart';
import '../../../../core/utils/validators.dart';
import '../../../widgets/app_alert_banner.dart';
import '../../historial_turnos/historial_turnos_colors.dart';
import '../reportes_provider.dart';

/// Abre el bottom sheet con opciones de compartir reporte.
void showCompartirReporteOpciones(
  BuildContext context, {
  required int turnoId,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _CompartirReporteOpcionesSheet(turnoId: turnoId),
  );
}

void showEnviarReporteEmailSheet(
  BuildContext context, {
  required int turnoId,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
      ),
      child: _EnviarReporteEmailSheet(turnoId: turnoId),
    ),
  );
}

class _CompartirReporteOpcionesSheet extends ConsumerStatefulWidget {
  const _CompartirReporteOpcionesSheet({required this.turnoId});

  final int turnoId;

  @override
  ConsumerState<_CompartirReporteOpcionesSheet> createState() =>
      _CompartirReporteOpcionesSheetState();
}

class _CompartirReporteOpcionesSheetState
    extends ConsumerState<_CompartirReporteOpcionesSheet> {
  bool _compartiendo = false;

  Future<void> _compartirPdf() async {
    if (_compartiendo) return;

    setState(() => _compartiendo = true);

    try {
      final pdf = await ref.read(reportesServiceProvider).descargarReporteTurnoPdf(
            turnoId: widget.turnoId,
          );

      final xFile = await saveBytesToTempFile(
        bytes: pdf.bytes,
        fileName: pdf.fileName,
        mimeType: 'application/pdf',
      );

      if (!mounted) return;

      Navigator.of(context).pop();
      await Share.shareXFiles(
        [xFile],
        subject: 'Reporte de turno',
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _compartiendo = false);
      showAppAlertError(context, message: e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _compartiendo = false);
      showAppAlertError(context, message: e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _compartiendo = false);
      showAppAlertError(
        context,
        message: 'No fue posible compartir el reporte.',
      );
    }
  }

  void _abrirEnviarCorreo() {
    if (_compartiendo) return;
    Navigator.of(context).pop();
    showEnviarReporteEmailSheet(
      context,
      turnoId: widget.turnoId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HistorialTurnosColors.cardBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: HistorialTurnosColors.textSecondary(context)
                    .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Compartir reporte',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: HistorialTurnosColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 20),
            _SheetActionButton(
              label: 'Compartir',
              icon: Icons.share_outlined,
              isLoading: _compartiendo,
              onPressed: _compartiendo ? null : _compartirPdf,
            ),
            const SizedBox(height: 12),
            _SheetActionButton(
              label: 'Enviar por correo',
              icon: Icons.email_outlined,
              onPressed: _compartiendo ? null : _abrirEnviarCorreo,
            ),
          ],
        ),
      ),
    );
  }
}

class _EnviarReporteEmailSheet extends ConsumerStatefulWidget {
  const _EnviarReporteEmailSheet({required this.turnoId});

  final int turnoId;

  @override
  ConsumerState<_EnviarReporteEmailSheet> createState() =>
      _EnviarReporteEmailSheetState();
}

class _EnviarReporteEmailSheetState
    extends ConsumerState<_EnviarReporteEmailSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _destinatarioController;
  late final TextEditingController _asuntoController;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _destinatarioController = TextEditingController();
    _asuntoController = TextEditingController();
  }

  @override
  void dispose() {
    _destinatarioController.dispose();
    _asuntoController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_enviando) return;

    final emailError = Validators.email(_destinatarioController.text.trim());
    if (emailError != null) {
      showAppAlertError(context, message: emailError);
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _enviando = true);

    try {
      final response = await ref.read(reportesServiceProvider).enviarReporteTurno(
            turnoId: widget.turnoId,
            destinatario: _destinatarioController.text.trim(),
            asunto: _asuntoController.text.trim().isEmpty
                ? null
                : _asuntoController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      showAppAlertSuccess(context, message: response.message);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      showAppAlertError(context, message: e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      showAppAlertError(context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      showAppAlertError(
        context,
        message: 'No se pudo enviar el reporte',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HistorialTurnosColors.cardBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HistorialTurnosColors.textSecondary(context)
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Enviar por correo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: HistorialTurnosColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              Text(
                'Correo destinatario *',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HistorialTurnosColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _destinatarioController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                enabled: !_enviando,
                style: TextStyle(
                  color: HistorialTurnosColors.textPrimary(context),
                ),
                decoration: _inputDecoration(context, hint: 'usuario@empresa.com'),
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              Text(
                'Asunto (opcional)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HistorialTurnosColors.textSecondary(context),
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _asuntoController,
                textInputAction: TextInputAction.done,
                enabled: !_enviando,
                style: TextStyle(
                  color: HistorialTurnosColors.textPrimary(context),
                ),
                decoration: _inputDecoration(context, hint: 'Reporte de turno'),
                onFieldSubmitted: (_) => _enviar(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _enviando
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HistorialTurnosColors.textPrimary(context),
                        side: BorderSide(
                          color: HistorialTurnosColors.textSecondary(context)
                              .withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _enviar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HistorialTurnosColors.accentWine,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            HistorialTurnosColors.textSecondary(context),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _enviando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Enviar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, {required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: HistorialTurnosColors.textSecondary(context),
      ),
      filled: true,
      fillColor: HistorialTurnosColors.background(context),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: HistorialTurnosColors.textSecondary(context).withValues(alpha: 0.25),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: HistorialTurnosColors.accentWine,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: HistorialTurnosColors.textPrimary(context),
                ),
              )
            : Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: HistorialTurnosColors.background(context),
          foregroundColor: HistorialTurnosColors.textPrimary(context),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: HistorialTurnosColors.textSecondary(context)
                  .withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }
}
