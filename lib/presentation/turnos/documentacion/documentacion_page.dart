import 'package:flutter/material.dart';
import '../../widgets/app_alert_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/models/registrar_documentacion_vehiculo_request.dart';
import '../checklist_apertura_navigation.dart';
import '../checklist_progress_provider.dart';
import '../mi_turno_provider.dart';
import '../models/checklist_type.dart';
import '../turno_bitacora_helper.dart';
import 'documentacion_colors.dart';

class DocumentacionPage extends ConsumerStatefulWidget {
  const DocumentacionPage({
    super.key,
    this.onContinuar,
    this.checklistType = ChecklistType.apertura,
  });

  final VoidCallback? onContinuar;
  final ChecklistType checklistType;

  @override
  ConsumerState<DocumentacionPage> createState() => _DocumentacionPageState();
}

class _DocumentacionPageState extends ConsumerState<DocumentacionPage> {
  bool _guardandoDocumentacion = false;

  @override
  void initState() {
    super.initState();
    if (widget.checklistType == ChecklistType.apertura ||
        widget.checklistType == ChecklistType.cierre) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(checklistProgressServiceProvider)
            .actualizarPaso(ChecklistAperturaPasos.documentacion);
      });
    }
  }

  final Map<String, bool> _documentosEstado = {
    'bitacora': true,
    'certificado_ecologico': true,
    'poliza_seguro': true,
    'tarjeta_circulacion': true,
    'verificacion': true,
  };

  void _toggleDocumento(String key) {
    setState(() {
      _documentosEstado[key] = !_documentosEstado[key]!;
    });
  }

  Future<void> _continuar() async {
    final idBitacora =
        idBitacoraVehiculoParaChecklist(ref, widget.checklistType);
    if (idBitacora == null) {
      showAppAlertError(context, message: mensajeBitacoraFaltante(widget.checklistType));
      return;
    }

    setState(() => _guardandoDocumentacion = true);

    try {
      final request = RegistrarDocumentacionVehiculoRequest.fromEstadoUi(
        idBitacoraVehiculo: idBitacora,
        documentosUi: _documentosEstado,
      );

      await ref.read(turnosServiceProvider).registrarDocumentacionVehiculo(request);

      if (!mounted) return;
      setState(() => _guardandoDocumentacion = false);
      _navegarSiguiente();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _guardandoDocumentacion = false);
      showAppAlertError(context, message: e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _guardandoDocumentacion = false);
      showAppAlertError(context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardandoDocumentacion = false);
      showAppAlertError(context, message: 'Error al registrar documentación: $e');
    }
  }

  void _navegarSiguiente() {
    if (widget.onContinuar != null) {
      widget.onContinuar!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DocumentacionColors.background(context),
      appBar: AppBar(
        backgroundColor: DocumentacionColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: DocumentacionColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Documentación',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: DocumentacionColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgress(context),
                  const SizedBox(height: 20),
                  _buildDocumentacionCard(context),
                ],
              ),
            ),
          ),
          _buildContinuarButton(context),
        ],
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Paso 8 de 8',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DocumentacionColors.textSecondary(context),
                  ),
            ),
            Text(
              'Documentación',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DocumentacionColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 1.0,
            backgroundColor: DocumentacionColors.switchTrackInactive(context),
            valueColor: const AlwaysStoppedAnimation<Color>(DocumentacionColors.switchActive),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentacionCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DocumentacionColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DocumentacionColors.headerIconBg.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: DocumentacionColors.headerIconBg,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Documentación del vehículo:',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: DocumentacionColors.textPrimary(context),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Confirme que cuenta con los siguientes documentos físicos.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DocumentacionColors.textSecondary(context),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: DocumentacionColors.divider(context), height: 1),
          _DocumentoItem(
            icon: Icons.menu_book_outlined,
            label: 'Bitácora Vehicular',
            isActive: _documentosEstado['bitacora']!,
            onToggle: () => _toggleDocumento('bitacora'),
            showDivider: true,
          ),
          _DocumentoItem(
            icon: Icons.eco_outlined,
            label: 'Certificado Ecológico',
            isActive: _documentosEstado['certificado_ecologico']!,
            onToggle: () => _toggleDocumento('certificado_ecologico'),
            showDivider: true,
          ),
          _DocumentoItem(
            icon: Icons.security_outlined,
            label: 'Póliza de Seguro',
            isActive: _documentosEstado['poliza_seguro']!,
            onToggle: () => _toggleDocumento('poliza_seguro'),
            showDivider: true,
          ),
          _DocumentoItem(
            icon: Icons.credit_card_outlined,
            label: 'Tarjeta de Circulación',
            isActive: _documentosEstado['tarjeta_circulacion']!,
            onToggle: () => _toggleDocumento('tarjeta_circulacion'),
            showDivider: true,
          ),
          _DocumentoItem(
            icon: Icons.verified_outlined,
            label: 'Verificación',
            isActive: _documentosEstado['verificacion']!,
            onToggle: () => _toggleDocumento('verificacion'),
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildContinuarButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _guardandoDocumentacion ? null : _continuar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF001C6A),
            foregroundColor: Colors.white,
            disabledBackgroundColor: DocumentacionColors.textSecondary(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _guardandoDocumentacion
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continuar',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}

class _DocumentoItem extends StatelessWidget {
  const _DocumentoItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onToggle,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onToggle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: DocumentacionColors.iconColor(context),
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: DocumentacionColors.textPrimary(context),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (_) => onToggle(),
                activeColor: Colors.white,
                activeTrackColor: DocumentacionColors.switchActive,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: DocumentacionColors.switchTrackInactive(context),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: DocumentacionColors.divider(context),
            height: 1,
            indent: 58,
            endIndent: 20,
          ),
      ],
    );
  }
}
