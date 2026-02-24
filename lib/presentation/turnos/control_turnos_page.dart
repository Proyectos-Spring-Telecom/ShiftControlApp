import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/auth_controller.dart';
import 'control_turnos_colors.dart';
import 'inicio_turno/inicio_turno_page.dart';
import 'models/checklist_type.dart';
import 'reporte_incidente/reporte_incidente_page.dart';
import 'registro_combustible/registro_combustible_page.dart';

/// Estado del turno actual.
enum TurnoStatus { enTurno, turnoCerrado }

class ControlTurnosPage extends ConsumerStatefulWidget {
  const ControlTurnosPage({
    super.key,
    required this.onBack,
    this.onOpenDrawer,
    this.onAperturaTap,
    this.onCierreTap,
    this.onReportarIncidenteTap,
    this.onRegistroCombustibleTap,
  });

  final VoidCallback onBack;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onAperturaTap;
  final VoidCallback? onCierreTap;
  final VoidCallback? onReportarIncidenteTap;
  final VoidCallback? onRegistroCombustibleTap;

  @override
  ConsumerState<ControlTurnosPage> createState() => _ControlTurnosPageState();
}

class _ControlTurnosPageState extends ConsumerState<ControlTurnosPage> {
  // ============================================================
  // CAMBIAR ESTA VARIABLE PARA PROBAR LAS VALIDACIONES:
  // - TurnoStatus.enTurno: El operador está en turno activo
  // - TurnoStatus.turnoCerrado: El turno está cerrado
  // ============================================================
  TurnoStatus _turnoStatus = TurnoStatus.enTurno;

  bool get _isEnTurno => _turnoStatus == TurnoStatus.enTurno;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final welcomeEmail = user?.email ?? 'Operador';

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
              'Bienvenido, $welcomeEmail',
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
                ? ControlTurnosColors.accent
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
    final aperturaEnabled = !_isEnTurno;
    final cierreEnabled = _isEnTurno;
    
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
                    if (widget.onAperturaTap != null) {
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
            onTap: cierreEnabled
                ? () {
                    if (widget.onCierreTap != null) {
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
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ControlTurnosColors.cardBackground(context),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                _StatusPill(status: _turnoStatus),
                const Spacer(),
                Text(
                  'Folio: #8821',
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
                        'Nissan Versa 2023',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: ControlTurnosColors.textPrimary(context),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Placas: XJA-99-23',
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
                const Expanded(
                  child: _InfoChip(
                    label: 'Inicio',
                    value: '08:30 AM',
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _InfoChip(
                    label: 'Duración',
                    value: '04h 12m',
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ],
    );
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled 
        ? ControlTurnosColors.accent 
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
