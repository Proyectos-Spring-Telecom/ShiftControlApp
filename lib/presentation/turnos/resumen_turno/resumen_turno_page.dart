import 'package:flutter/material.dart';
import 'package:gradient_slide_to_act/gradient_slide_to_act.dart';

import '../models/checklist_type.dart';
import 'resumen_turno_colors.dart';

class ResumenTurnoPage extends StatelessWidget {
  const ResumenTurnoPage({
    super.key,
    this.checklistType = ChecklistType.apertura,
  });

  final ChecklistType checklistType;

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
                  _buildInformacionGeneralCard(context),
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
          _buildIniciarTurnoButton(context),
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
    final isApertura = checklistType == ChecklistType.apertura;
    final statusText = isApertura ? 'Listo para iniciar' : 'Cierre de turno';
    final statusColor = isApertura 
        ? ResumenTurnoColors.statusTextGreen 
        : ResumenTurnoColors.iconClockBg;
    final statusLabelColor = isApertura 
        ? ResumenTurnoColors.statusLabelGreen 
        : ResumenTurnoColors.iconClockBg;
    final cardBgColor = isApertura 
        ? ResumenTurnoColors.statusCardBackground(context) 
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

  Widget _buildInformacionGeneralCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ResumenTurnoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'Vehículo', 'Nissan Versa - 2023', 'Placas: A-123-BC', Icons.directions_car_outlined),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: ResumenTurnoColors.textSecondary(context).withValues(alpha: 0.4), height: 1, thickness: 1),
          ),
          _buildInfoRow(context, 'Operador', 'Juan Pérez García', 'ID: OP-4592', Icons.person_outline),
        ],
      ),
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
                  'Viernes, 02 Feb 2024',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: ResumenTurnoColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '07:45 AM',
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

  Widget _buildIniciarTurnoButton(BuildContext context) {
    final isApertura = checklistType == ChecklistType.apertura;
    final buttonText = isApertura ? 'Iniciar Turno' : 'Cerrar Turno';
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: const Color(0xFF385C51),
              width: 2,
            ),
          ),
          child: GradientSlideToAct(
            width: MediaQuery.of(context).size.width - 42,
            dragableIcon: Icons.chevron_right,
            dragableIconBackgroundColor: const Color(0xFF4ADE80),
            text: buttonText,
            textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ResumenTurnoColors.textPrimary(context),
                  fontWeight: FontWeight.w500,
                ) ?? const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            backgroundColor: ResumenTurnoColors.cardBackground(context),
            onSubmit: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF60A5FA),
                Color(0xFF4ADE80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
