import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gradient_slide_to_act/gradient_slide_to_act.dart';
import 'package:quickalert/quickalert.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../data/models/cerrar_bitacora_response.dart';
import '../../../data/models/informacion_general_response.dart';
import '../indicadores_testigo/indicadores_testigo_colors.dart';
import '../checklist_apertura_navigation.dart';
import '../checklist_progress_provider.dart';
import '../mi_turno_provider.dart';
import '../models/checklist_type.dart';
import '../turno_apertura_provider.dart';
import '../turno_bitacora_helper.dart';
import '../turno_cierre_provider.dart';
import '../turno_status_provider.dart';
import 'resumen_turno_colors.dart';

class ResumenTurnoPage extends ConsumerStatefulWidget {
  const ResumenTurnoPage({
    super.key,
    this.checklistType = ChecklistType.apertura,
  });

  final ChecklistType checklistType;

  @override
  ConsumerState<ResumenTurnoPage> createState() => _ResumenTurnoPageState();
}

class _ResumenTurnoPageState extends ConsumerState<ResumenTurnoPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.checklistType == ChecklistType.apertura) {
        ref
            .read(checklistProgressServiceProvider)
            .actualizarPaso(ChecklistAperturaPasos.resumen);
      } else if (widget.checklistType == ChecklistType.cierre) {
        ref
            .read(checklistProgressServiceProvider)
            .actualizarPaso(ChecklistCierrePasos.resumen);
      }
      _cargarInformacionGeneral();
    });
  }

  void _cargarInformacionGeneral() {
    final idBitacora =
        idBitacoraVehiculoParaChecklist(ref, widget.checklistType);
    if (idBitacora != null) {
      ref.read(informacionGeneralProvider.notifier).fetch(idBitacora);
    } else {
      ref.read(informacionGeneralProvider.notifier).reportMissingBitacora();
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(informacionGeneralProvider);
    return Scaffold(
      backgroundColor: ResumenTurnoColors.background(context),
      appBar: AppBar(
        backgroundColor: ResumenTurnoColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ResumenTurnoColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Resumen de Turno',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ResumenTurnoColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
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
                  _buildEstadoCard(context),
                  const SizedBox(height: 24),
                  _buildSectionHeading(context, 'Información General'),
                  const SizedBox(height: 10),
                  _buildInformacionGeneralCard(context, infoAsync),
                  const SizedBox(height: 24),
                  _buildSectionHeading(context, 'Estado del Vehículo'),
                  const SizedBox(height: 10),
                  _buildEstadoVehiculoCard(context, infoAsync),
                  const SizedBox(height: 24),
                  _buildSectionHeading(context, 'Tiempo y Ubicación'),
                  const SizedBox(height: 10),
                  _buildFechaHoraCard(context),
                  const SizedBox(height: 12),
                  _buildUbicacionCard(context, infoAsync),
                  const SizedBox(height: 24),
                  _buildSectionHeading(context, 'Métricas Iniciales'),
                  const SizedBox(height: 10),
                  _buildMetricasSection(context, infoAsync),
                ],
              ),
            ),
          ),
          _buildIniciarTurnoButton(context, widget.checklistType),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: ResumenTurnoColors.sectionHeading(context),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildEstadoCard(BuildContext context) {
    final isApertura = widget.checklistType == ChecklistType.apertura;
    final statusText = isApertura ? 'Listo para iniciar' : 'Cierre de turno';
    final statusColor = isApertura 
        ? IndicadoresTestigoColors.indicatorActive(context) 
        : ResumenTurnoColors.iconClockBg;
    final statusLabelColor = isApertura 
        ? IndicadoresTestigoColors.indicatorActive(context) 
        : ResumenTurnoColors.iconClockBg;
    final cardBgColor = isApertura 
        ? IndicadoresTestigoColors.indicatorActiveBg(context) 
        : ResumenTurnoColors.iconClockBg.withValues(alpha: 0.15);
    final statusIcon = isApertura 
        ? Icons.check_circle_outline 
        : Icons.assignment_turned_in_outlined;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estado',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusLabelColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformacionGeneralCard(
    BuildContext context,
    AsyncValue<InformacionGeneralResponse> infoAsync,
  ) {
    final vehiculoTitle = infoAsync.when(
      data: (d) => d.informacionGeneral.vehiculo.titulo ?? 'No disponible',
      loading: () => 'Cargando...',
      error: (_, __) => 'No disponible',
    );
    final vehiculoSubtitle = infoAsync.when(
      data: (d) => d.informacionGeneral.vehiculo.subtitulo ?? '—',
      loading: () => '—',
      error: (_, __) => '—',
    );
    final operadorTitle = infoAsync.when(
      data: (d) => d.informacionGeneral.operador.nombre ?? 'No disponible',
      loading: () => 'Cargando...',
      error: (_, __) => 'No disponible',
    );
    final operadorId = infoAsync.when(
      data: (d) => d.informacionGeneral.operador.id ?? '—',
      loading: () => '—',
      error: (_, __) => '—',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ResumenTurnoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'Vehículo', vehiculoTitle, vehiculoSubtitle, Icons.directions_car_outlined),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: ResumenTurnoColors.textSecondary(context).withValues(alpha: 0.4), height: 1, thickness: 1),
          ),
          _buildInfoRow(context, 'Operador', operadorTitle, operadorId, Icons.person_outline),
        ],
      ),
    );
  }

  Widget _buildEstadoVehiculoCard(
    BuildContext context,
    AsyncValue<InformacionGeneralResponse> infoAsync,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ResumenTurnoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: infoAsync.when(
        data: (data) {
          final items = data.informacionGeneral.estadoVehiculo;
          if (items.isEmpty) {
            return Text(
              'No disponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ResumenTurnoColors.textSecondary(context),
                  ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _buildEstadoVehiculoRow(
                  context,
                  label: items[i].etiqueta ?? '—',
                  value: items[i].valor ?? '—',
                ),
                if (i < items.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Divider(
                      color: ResumenTurnoColors.textSecondary(context).withValues(alpha: 0.4),
                      height: 1,
                      thickness: 1,
                    ),
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
        error: (e, _) => Text(
          _mensajeError(e),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ResumenTurnoColors.textSecondary(context),
              ),
        ),
      ),
    );
  }

  String _mensajeError(Object error) {
    if (error is AuthException) return error.message;
    if (error is NetworkException) {
      if (error.code == '404') return 'Bitácora no encontrada.';
      return error.message;
    }
    return 'No se pudo cargar la información.';
  }

  Widget _buildEstadoVehiculoRow(BuildContext context, {required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ResumenTurnoColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ResumenTurnoColors.textPrimary(context),
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ResumenTurnoColors.textSecondary(context),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ResumenTurnoColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ResumenTurnoColors.textSecondary(context),
                    ),
              ),
            ],
          ),
        ),
        Icon(icon, color: ResumenTurnoColors.textSecondary(context), size: 32),
      ],
    );
  }

  Widget _buildFechaHoraCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ResumenTurnoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ResumenTurnoColors.iconClockBg.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.access_time, color: ResumenTurnoColors.iconClockBg, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fecha y Hora',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ResumenTurnoColors.textSecondary(context),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatearSoloFechaActual(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ResumenTurnoColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatearSoloHora12Actual(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ResumenTurnoColors.accentBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionCard(
    BuildContext context,
    AsyncValue<InformacionGeneralResponse> infoAsync,
  ) {
    final ubicacion = infoAsync.when(
      data: (d) => d.informacionGeneral.ubicacion,
      loading: () => null,
      error: (_, __) => null,
    );
    final ubicacionTexto = infoAsync.isLoading
        ? 'Cargando...'
        : (ubicacion?.isNotEmpty == true ? ubicacion! : 'No disponible');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ResumenTurnoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ResumenTurnoColors.iconLocationBg.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_outlined,
              color: ResumenTurnoColors.iconLocationBg,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ubicación GPS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ResumenTurnoColors.textSecondary(context),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  ubicacionTexto,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ResumenTurnoColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasSection(
    BuildContext context,
    AsyncValue<InformacionGeneralResponse> infoAsync,
  ) {
    return infoAsync.when(
      data: (data) {
        final items = data.informacionGeneral.metricasIniciales;
        if (items.isEmpty) {
          return Text(
            'No disponible',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ResumenTurnoColors.textSecondary(context),
                ),
          );
        }
        final rows = <Widget>[];
        for (int i = 0; i < items.length; i += 2) {
          rows.add(
            Row(
              children: [
                Expanded(
                  child: _buildMetricaCard(
                    context,
                    icon: _iconForMetrica(items[i].etiqueta),
                    label: items[i].etiqueta ?? '—',
                    value: items[i].valor ?? '—',
                  ),
                ),
                if (i + 1 < items.length) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricaCard(
                      context,
                      icon: _iconForMetrica(items[i + 1].etiqueta),
                      label: items[i + 1].etiqueta ?? '—',
                      value: items[i + 1].valor ?? '—',
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          );
          if (i + 2 < items.length) {
            rows.add(const SizedBox(height: 12));
          }
        }
        return Column(children: rows);
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
      error: (e, _) => Text(
        _mensajeError(e),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ResumenTurnoColors.textSecondary(context),
            ),
      ),
    );
  }

  IconData _iconForMetrica(String? etiqueta) {
    final e = (etiqueta ?? '').toLowerCase();
    if (e.contains('odómetro') || e.contains('odometro')) return Icons.speed;
    if (e.contains('litro') || e.contains('gasolina') || e.contains('combustible')) {
      return Icons.local_gas_station_outlined;
    }
    return Icons.analytics_outlined;
  }

  Widget _buildMetricaCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ResumenTurnoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: ResumenTurnoColors.textSecondary(context), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ResumenTurnoColors.textSecondary(context),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ResumenTurnoColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIniciarTurnoButton(BuildContext context, ChecklistType checklistType) {
    final isApertura = checklistType == ChecklistType.apertura;
    final buttonText = isApertura ? 'Iniciar Turno' : 'Cerrar Turno';
    final borderColor = isApertura
        ? IndicadoresTestigoColors.indicatorActive(context)
        : const Color(0xFF385C51);
    final thumbColor = isApertura
        ? IndicadoresTestigoColors.indicatorActive(context)
        : const Color(0xFF4ADE80);
    final gradientColors = isApertura
        ? [
            IndicadoresTestigoColors.indicatorActiveBg(context),
            IndicadoresTestigoColors.indicatorActive(context),
          ]
        : const [Color(0xFF60A5FA), Color(0xFF4ADE80)];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
          ),
          child: GradientSlideToAct(
            width: MediaQuery.of(context).size.width - 42,
            dragableIcon: Icons.chevron_right,
            dragableIconBackgroundColor: thumbColor,
            text: buttonText,
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ResumenTurnoColors.textPrimary(context),
                  fontWeight: FontWeight.w500,
                ) ?? const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            backgroundColor: ResumenTurnoColors.cardBackground(context),
            onSubmit: () async {
              if (!context.mounted) return;
              final navigator = Navigator.of(context);

              if (isApertura) {
                final idBitacora =
                    ref.read(turnoAperturaProvider).idBitacoraApertura;
                if (idBitacora == null) {
                  await QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text:
                        'No hay bitácora de apertura. Completa el flujo de apertura.',
                    confirmBtnText: 'Aceptar',
                  );
                  return;
                }

                try {
                  await ref.read(turnosServiceProvider).cerrarBitacoraApertura(
                        idBitacoraVehiculo: idBitacora,
                      );
                } on AuthException catch (e) {
                  if (!context.mounted) return;
                  await QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text: e.message,
                    confirmBtnText: 'Aceptar',
                  );
                  return;
                } on NetworkException catch (e) {
                  if (!context.mounted) return;
                  await QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text: e.message,
                    confirmBtnText: 'Aceptar',
                  );
                  return;
                } catch (e) {
                  if (!context.mounted) return;
                  await QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text: 'No fue posible cerrar la bitácora. Intenta nuevamente.',
                    confirmBtnText: 'Aceptar',
                  );
                  return;
                }

                await ref.read(checklistProgressServiceProvider).limpiar();
                ref.read(turnoAperturaProvider.notifier).state =
                    const TurnoAperturaState();
                ref.read(turnoStatusProvider.notifier).state = TurnoStatus.enTurno;

                if (!context.mounted) return;
                await QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Turno Iniciado',
                  text:
                      'El turno se ha iniciado y el registro se guardó de manera exitosa.',
                  confirmBtnText: 'Aceptar',
                );
              } else {
                final idBitacora =
                    ref.read(turnoCierreProvider).idBitacoraCierre;
                if (idBitacora == null) {
                  await QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text:
                        'No hay bitácora de cierre. Completa el cierre geográfico.',
                    confirmBtnText: 'Aceptar',
                  );
                  return;
                }

                CerrarBitacoraResponse? cierreResponse;
                try {
                  cierreResponse = await ref
                      .read(turnosServiceProvider)
                      .cerrarBitacoraApertura(
                        idBitacoraVehiculo: idBitacora,
                      );
                } on AuthException catch (e) {
                  if (!context.mounted) return;
                  await QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text: e.message,
                    confirmBtnText: 'Aceptar',
                  );
                  return;
                } on NetworkException catch (e) {
                  if (!context.mounted) return;
                  await QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text: e.message,
                    confirmBtnText: 'Aceptar',
                  );
                  return;
                } catch (e) {
                  if (!context.mounted) return;
                  await QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text:
                        'No fue posible cerrar la bitácora. Intenta nuevamente.',
                    confirmBtnText: 'Aceptar',
                  );
                  return;
                }

                if (cierreResponse.flujo != 'cierre') {
                  if (!context.mounted) return;
                  await QuickAlert.show(
                    context: context,
                    type: QuickAlertType.error,
                    title: 'Error',
                    text:
                        'No fue posible finalizar el cierre del turno. Intenta nuevamente.',
                    confirmBtnText: 'Aceptar',
                  );
                  return;
                }

                await ref.read(checklistProgressServiceProvider).limpiar();
                ref.read(turnoAperturaProvider.notifier).state =
                    const TurnoAperturaState();
                ref.read(turnoCierreProvider.notifier).state =
                    const TurnoCierreState();
                ref.read(turnoStatusProvider.notifier).state =
                    TurnoStatus.turnoCerrado;

                if (!context.mounted) return;
                await QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Turno Cerrado',
                  text:
                      'El turno se ha cerrado y el registro se guardó de manera exitosa.',
                  confirmBtnText: 'Aceptar',
                );
              }

              if (context.mounted) {
                ref.invalidate(miTurnoActivoProvider);
                await ref.read(miTurnoActivoProvider.notifier).fetch();
                if (context.mounted) {
                  navigator.popUntil((route) => route.isFirst);
                }
              }
            },
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
        ),
      ),
    );
  }
}
