import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gradient_slide_to_act/gradient_slide_to_act.dart';
import 'package:quickalert/quickalert.dart';

import '../../../domain/entities/user_entity.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../data/datasources/remote/placas_validar_remote_datasource.dart';
import '../indicadores_testigo/indicadores_testigo_colors.dart';
import '../models/checklist_type.dart';
import '../placa_validada_provider.dart';
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
  Widget build(BuildContext context) {
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
                  _buildInformacionGeneralCard(context, ref),
                  const SizedBox(height: 24),
                  _buildSectionHeading(context, 'Estado del Vehículo'),
                  const SizedBox(height: 10),
                  _buildEstadoVehiculoCard(context),
                  const SizedBox(height: 24),
                  _buildSectionHeading(context, 'Tiempo y Ubicación'),
                  const SizedBox(height: 10),
                  _buildFechaHoraCard(context),
                  const SizedBox(height: 12),
                  _buildUbicacionCard(context),
                  const SizedBox(height: 24),
                  _buildSectionHeading(context, 'Métricas Iniciales'),
                  const SizedBox(height: 10),
                  _buildMetricasRow(context),
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

  Widget _buildInformacionGeneralCard(BuildContext context, WidgetRef ref) {
    final placaResult = ref.watch(placaValidadaProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user;

    final bool hasVehiculo = placaResult != null && placaResult.registered;
    final String vehiculoTitle = hasVehiculo
        ? _vehiculoTitle(placaResult!)
        : 'Nissan Versa - 2023';
    final String vehiculoSubtitle = hasVehiculo
        ? 'Placa: ${placaResult!.placa ?? '—'}'
        : 'Placas: A-123-BC';

    final String operadorTitle = _operadorTitle(user);
    const String operadorId = 'ID: OP-4592';

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

  static String _vehiculoTitle(PlacasValidarResult r) {
    final marca = r.marca ?? '';
    final modelo = r.modelo ?? '';
    final anio = r.anio?.toString() ?? '';
    final parts = [marca, modelo].where((s) => s.isNotEmpty);
    if (parts.isEmpty) return anio.isNotEmpty ? '— $anio' : '—';
    final base = parts.join(' ');
    return anio.isNotEmpty ? '$base - $anio' : base;
  }

  static String _operadorTitle(UserEntity? user) {
    if (user == null) return 'Juan Pérez García';
    final name = user.name;
    final p = user.apellidoPaterno ?? '';
    final m = user.apellidoMaterno ?? '';
    final apellidos = [p, m].where((s) => s.isNotEmpty).join(' ');
    return apellidos.isEmpty ? name : '$name $apellidos';
  }

  Widget _buildEstadoVehiculoCard(BuildContext context) {
    const items = [
      ('Estado de la carrocería', 'Bueno'),
      ('Estado de indicadores', 'Bueno'),
      ('Nivel de Gasolina', '95 %'),
      ('Estado de las Luces', 'Bueno'),
      ('Estado de accesorios', 'Bueno'),
      ('Documentación', 'En regla'),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ResumenTurnoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildEstadoVehiculoRow(
              context,
              label: items[i].$1,
              value: items[i].$2,
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
      ),
    );
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

  Widget _buildUbicacionCard(BuildContext context) {
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
                  'Av. Revolución 123, Col. Centro, Tlaxcala, México',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ResumenTurnoColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Precisión: 5m',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ResumenTurnoColors.accentGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricaCard(
            context,
            icon: Icons.speed,
            label: 'Odómetro',
            value: '142.593 km',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricaCard(
            context,
            icon: Icons.local_gas_station_outlined,
            label: 'Litros Cargados',
            value: '45.50 LTS',
          ),
        ),
      ],
    );
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
              ref.read(turnoStatusProvider.notifier).state =
                  isApertura ? TurnoStatus.enTurno : TurnoStatus.turnoCerrado;
              if (!context.mounted) return;
              final navigator = Navigator.of(context);
              if (isApertura) {
                await QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Turno Iniciado',
                  text: 'El turno se ha iniciado y el registro se guardó de manera exitosa.',
                  confirmBtnText: 'Aceptar',
                );
              } else {
                await QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Turno Cerrado',
                  text: 'El turno se ha cerrado y el registro se guardó de manera exitosa.',
                  confirmBtnText: 'Aceptar',
                );
              }
              if (context.mounted) {
                navigator.popUntil((route) => route.isFirst);
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
