import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../data/models/mi_turno_activo_response.dart';
import '../controllers/auth_controller.dart';
import '../../features/turnos/services/checklist_progress_service.dart';
import 'checklist_apertura_navigation.dart';
import 'checklist_progress_provider.dart';
import 'control_turnos_colors.dart';
import 'inicio_turno/inicio_turno_page.dart';
import 'mi_turno_provider.dart';
import 'models/checklist_type.dart';
import 'reporte_incidente/reporte_incidente_page.dart';
import 'registro_combustible/registro_combustible_page.dart';
import 'turno_apertura_provider.dart';
import 'turno_cierre_provider.dart';
import 'turno_status_provider.dart';

class ControlTurnosPage extends ConsumerStatefulWidget {
  const ControlTurnosPage({
    super.key,
    required this.onBack,
    this.onOpenDrawer,
    this.onAperturaTap,
    this.onAperturaResumeTap,
    this.onCierreTap,
    this.onCierreResumeTap,
    this.onReportarIncidenteTap,
    this.onRegistroCombustibleTap,
  });

  final VoidCallback onBack;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onAperturaTap;
  final void Function(int paso)? onAperturaResumeTap;
  final VoidCallback? onCierreTap;
  final void Function(int paso)? onCierreResumeTap;
  final VoidCallback? onReportarIncidenteTap;
  final VoidCallback? onRegistroCombustibleTap;

  @override
  ConsumerState<ControlTurnosPage> createState() => _ControlTurnosPageState();
}

class _ControlTurnosPageState extends ConsumerState<ControlTurnosPage> {
  bool get _isEnTurno {
    final miTurno = ref.watch(miTurnoActivoProvider);
    return miTurno.whenOrNull(data: (data) => data.turnoActivo) ?? false;
  }

  bool get _hayProgresoIncompleto {
    final progreso = ref.read(checklistProgressServiceProvider).leerProgreso();
    return progreso != null && progreso.tieneProgresoIncompleto;
  }

  bool get _progresoAperturaIncompleto {
    final progreso = ref.read(checklistProgressServiceProvider).leerProgreso();
    return progreso != null &&
        !progreso.esCierre &&
        progreso.tieneProgresoIncompleto;
  }

  bool get _progresoCierreIncompleto {
    final progreso = ref.read(checklistProgressServiceProvider).leerProgreso();
    return progreso != null &&
        progreso.esCierre &&
        progreso.tieneProgresoIncompleto;
  }

  void _restaurarProgresoEnProvider(ChecklistProgress progreso) {
    if (progreso.esCierre) {
      ref.read(turnoCierreProvider.notifier).state = TurnoCierreState(
        idTurno: progreso.idTurno,
        idBitacoraCierre: progreso.idBitacoraCierre,
        duracion: progreso.duracion,
      );
      return;
    }

    ref.read(turnoAperturaProvider.notifier).state = TurnoAperturaState(
      idTurno: progreso.idTurno,
      idBitacoraApertura: progreso.idBitacoraApertura,
      placa: progreso.placa,
      numeroEconomico: progreso.numeroEconomico,
      modeloNombre: progreso.modeloNombre,
      marcaNombre: progreso.marcaNombre,
      anio: progreso.anio,
    );
  }

  void _navegarAPasoCierre(BuildContext context, int paso) {
    if (widget.onCierreResumeTap != null) {
      widget.onCierreResumeTap!(paso);
      return;
    }
    final route = ChecklistCierrePasos.routeForPaso(paso);
    if (route != null) {
      Navigator.of(context).pushNamed(route);
    }
  }

  void _navegarAPaso(BuildContext context, int paso, ChecklistProgress progreso) {
    if (widget.onAperturaResumeTap != null) {
      widget.onAperturaResumeTap!(paso);
      return;
    }
    navegarChecklistAperturaStandalone(context, paso, progreso);
  }

  Future<void> _limpiarProgresoSiTurnoInactivo(MiTurnoActivoResponse miTurno) async {
    if (miTurno.turnoActivo) return;

    final progreso = ref.read(checklistProgressServiceProvider).leerProgreso();
    if (progreso != null && progreso.tieneProgresoIncompleto) {
      return;
    }

    await ref.read(checklistProgressServiceProvider).limpiar();
    ref.read(turnoAperturaProvider.notifier).state = const TurnoAperturaState();
    ref.read(turnoCierreProvider.notifier).state = const TurnoCierreState();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(miTurnoActivoProvider.notifier).fetch();
      _retomarCierreSiAplica();
    });
  }

  void _retomarCierreSiAplica() {
    if (!mounted) return;
    final progreso = ref.read(checklistProgressServiceProvider).leerProgreso();
    if (progreso == null ||
        !progreso.esCierre ||
        !progreso.tieneProgresoIncompleto) {
      return;
    }
    _restaurarProgresoEnProvider(progreso);
    _navegarAPasoCierre(context, progreso.pasoActual);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<MiTurnoActivoResponse>>(miTurnoActivoProvider, (
      _,
      next,
    ) {
      next.whenData((miTurno) => _limpiarProgresoSiTurnoInactivo(miTurno));
    });

    final user = ref.watch(authControllerProvider).user;
    final welcomeLabel = user?.roleName ?? user?.name ?? user?.email ?? 'Operador';

    return Scaffold(
      backgroundColor: ControlTurnosColors.background(context),
      appBar: AppBar(
        backgroundColor: ControlTurnosColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ControlTurnosColors.textPrimary(context)),
          onPressed: widget.onBack,
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Control de Turnos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ControlTurnosColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: ControlTurnosColors.textPrimary(context)),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.menu, color: ControlTurnosColors.textPrimary(context)),
            onPressed: widget.onOpenDrawer ?? widget.onBack,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, $welcomeLabel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ControlTurnosColors.textSecondary(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 16),
            _buildActionCards(context),
            const SizedBox(height: 28),
            _buildEstadoActual(context),
            const SizedBox(height: 28),
            _buildHistorialReciente(context),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'fab_combustible',
            onPressed: _isEnTurno
                ? () {
                    if (widget.onRegistroCombustibleTap != null) {
                      widget.onRegistroCombustibleTap!();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegistroCombustiblePage(),
                        ),
                      );
                    }
                  }
                : null,
            backgroundColor: _isEnTurno
                ? ControlTurnosColors.statusPillForeground(context)
                : ControlTurnosColors.disabled(context),
            child: Icon(
              Icons.local_gas_station,
              color: _isEnTurno ? Colors.white : ControlTurnosColors.textSecondary(context),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'fab_incidente',
            onPressed: _isEnTurno
                ? () {
                    if (widget.onReportarIncidenteTap != null) {
                      widget.onReportarIncidenteTap!();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ReporteIncidentePage(),
                        ),
                      );
                    }
                  }
                : null,
            backgroundColor: _isEnTurno
                ? const Color(0xFFFF9800)
                : ControlTurnosColors.disabled(context),
            child: Icon(
              Icons.warning_amber_rounded,
              color: _isEnTurno ? Colors.white : ControlTurnosColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    final aperturaEnabled = _progresoAperturaIncompleto || (!_isEnTurno && !_progresoCierreIncompleto);
    final cierreEnabled = _isEnTurno && (_progresoCierreIncompleto || !_hayProgresoIncompleto);
    
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.login_rounded,
            title: 'Apertura',
            subtitle: 'Iniciar jornada laboral',
            enabled: aperturaEnabled,
            onTap: aperturaEnabled
                ? () {
                    final progreso =
                        ref.read(checklistProgressServiceProvider).leerProgreso();
                    if (progreso != null &&
                        progreso.tieneProgresoIncompleto &&
                        !progreso.esCierre) {
                      _restaurarProgresoEnProvider(progreso);
                      _navegarAPaso(context, progreso.pasoActual, progreso);
                    } else if (widget.onAperturaTap != null) {
                      widget.onAperturaTap!();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const InicioTurnoPage(),
                        ),
                      );
                    }
                  }
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.logout_rounded,
            title: 'Cierre',
            subtitle: 'Finalizar jornada actual',
            enabled: cierreEnabled,
            iconColorOverride: const Color(0xFF7eb8e8),
            onTap: cierreEnabled
                ? () {
                    final progreso =
                        ref.read(checklistProgressServiceProvider).leerProgreso();
                    if (progreso != null &&
                        progreso.tieneProgresoIncompleto &&
                        progreso.esCierre) {
                      _restaurarProgresoEnProvider(progreso);
                      _navegarAPasoCierre(context, progreso.pasoActual);
                    } else if (widget.onCierreTap != null) {
                      widget.onCierreTap!();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const InicioTurnoPage(
                            checklistType: ChecklistType.cierre,
                          ),
                        ),
                      );
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoActual(BuildContext context) {
    final miTurnoAsync = ref.watch(miTurnoActivoProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado Actual',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: ControlTurnosColors.textPrimary(context),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
        ),
        const SizedBox(height: 12),
        miTurnoAsync.when(
          loading: () => _buildEstadoActualLoading(context),
          error: (error, _) => _buildEstadoActualError(context, error),
          data: (miTurno) => _buildEstadoActualData(context, miTurno),
        ),
      ],
    );
  }

  Widget _buildEstadoActualCard(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ControlTurnosColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildEstadoActualLoading(BuildContext context) {
    return _buildEstadoActualCard(
      context,
      child: const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildEstadoActualError(BuildContext context, Object error) {
    final message = error is AppException
        ? error.message
        : 'No se pudo cargar el estado del turno.';

    return _buildEstadoActualCard(
      context,
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: ControlTurnosColors.textSecondary(context),
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ControlTurnosColors.textSecondary(context),
                ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => ref.read(miTurnoActivoProvider.notifier).fetch(),
            style: TextButton.styleFrom(
              foregroundColor: ControlTurnosColors.accent,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoActualData(BuildContext context, MiTurnoActivoResponse miTurno) {
    final turnoActivo = miTurno.turnoActivo;
    final status = turnoActivo ? TurnoStatus.enTurno : TurnoStatus.turnoCerrado;
    final vehiculoTitle = turnoActivo
        ? (miTurno.vehiculo?.placas ?? 'Sin vehículo')
        : 'Sin turno activo';
    final vehiculoPlaca = turnoActivo ? (miTurno.vehiculo?.placas ?? '—') : '—';
    final inicio = turnoActivo ? _formatearHoraInicio(miTurno.fechaInicio) : '—';
    final duracion =
        turnoActivo ? _formatearDuracion(miTurno.duracionSegundos) : '—';
    final folio = turnoActivo && miTurno.idTurno != null
        ? 'Folio: #${miTurno.idTurno}'
        : 'Folio: —';

    return _buildEstadoActualCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusPill(status: status),
              const Spacer(),
              Text(
                folio,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ControlTurnosColors.textSecondary(context),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ControlTurnosColors.background(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car_outlined,
                  color: ControlTurnosColors.textPrimary(context),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehiculoTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ControlTurnosColors.textPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Placa: $vehiculoPlaca',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ControlTurnosColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InfoChip(
                  label: 'Inicio',
                  value: inicio,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoChip(
                  label: 'Duración',
                  value: duracion,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatearHoraInicio(DateTime? fecha) {
    if (fecha == null) return '—';
    final hour = fecha.hour;
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = fecha.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  static String _formatearDuracion(int? segundos) {
    if (segundos == null || segundos <= 0) return '—';
    final d = Duration(seconds: segundos);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m ${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }

  Widget _buildHistorialReciente(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Historial Reciente',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ControlTurnosColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: ControlTurnosColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Ver todo'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _HistorialItem(
          icon: Icons.history_rounded,
          iconBgColor: ControlTurnosColors.iconCyan,
          title: 'Cierre de Turno',
          subtitle: 'Ayer, 18:45 PM • Nissan Versa',
          showArrow: true,
        ),
        const SizedBox(height: 10),
        const _HistorialItem(
          icon: Icons.warning_amber_rounded,
          iconBgColor: ControlTurnosColors.iconOrange,
          title: 'Incidente Reportado',
          subtitle: 'Lun 12 Ene • Rayón puerta izq.',
          showArrow: true,
        ),
        const SizedBox(height: 10),
        const _HistorialItem(
          icon: Icons.check_circle_outline,
          iconBgColor: ControlTurnosColors.iconGreen,
          title: 'Turno Completado',
          subtitle: 'Lun 12 Ene • 8hrs 05m',
          showArrow: false,
        ),
        const SizedBox(height: 10),
        const _HistorialItem(
          icon: Icons.local_gas_station,
          iconBgColor: ControlTurnosColors.iconGreen,
          title: 'Registro de Combustible',
          subtitle: 'Lun 12 Ene • 45.50 LTS',
          showArrow: false,
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final TurnoStatus status;

  @override
  Widget build(BuildContext context) {
    final isEnTurno = status == TurnoStatus.enTurno;
    final bgColor = isEnTurno
        ? ControlTurnosColors.statusPillBackground(context)
        : ControlTurnosColors.statusClosedPillBackground(context);
    final fgColor = isEnTurno
        ? ControlTurnosColors.statusPillForeground(context)
        : ControlTurnosColors.statusClosedPillForeground(context);
    final text = isEnTurno ? 'En Turno' : 'Turno Cerrado';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: fgColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
    this.iconColorOverride,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? iconColorOverride;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled 
        ? (iconColorOverride ?? ControlTurnosColors.accent)
        : ControlTurnosColors.disabled(context);
    final titleColor = enabled 
        ? ControlTurnosColors.textPrimary(context) 
        : ControlTurnosColors.textSecondary(context);
    final subtitleColor = enabled 
        ? ControlTurnosColors.textSecondary(context) 
        : ControlTurnosColors.disabled(context);
    
    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                ),
          ),
        ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.6,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ControlTurnosColors.cardBackground(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ControlTurnosColors.background(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ControlTurnosColors.textSecondary(context),
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ControlTurnosColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistorialItem extends StatelessWidget {
  const _HistorialItem({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.showArrow,
  });

  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ControlTurnosColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconBgColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ControlTurnosColors.textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ControlTurnosColors.textSecondary(context),
                      ),
                ),
              ],
            ),
          ),
          if (showArrow)
            Icon(
              Icons.chevron_right,
              color: ControlTurnosColors.textSecondary(context),
              size: 24,
            ),
        ],
      ),
    );
  }
}
