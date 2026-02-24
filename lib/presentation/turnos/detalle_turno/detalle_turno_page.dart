import 'package:flutter/material.dart';

import '../control_turnos_colors.dart';
import '../historial_turnos/historial_turnos_colors.dart';
import '../resumen_turno/resumen_turno_colors.dart';

/// Datos necesarios para mostrar el detalle de un turno.
class TurnoDetalleData {
  const TurnoDetalleData({
    required this.operador,
    required this.idEmpleado,
    required this.vehiculo,
    required this.noEconomico,
    required this.placas,
    required this.grupo,
    required this.fechaStr,
    required this.horaInicio,
    required this.horaFin,
    required this.distanciaKm,
    this.lecturaInicial,
    this.lecturaFinal,
  });

  final String operador;
  final String idEmpleado;
  final String vehiculo;
  final String noEconomico;
  final String placas;
  final String grupo;
  final String fechaStr;
  final String horaInicio;
  final String horaFin;
  final String distanciaKm;
  final String? lecturaInicial;
  final String? lecturaFinal;

  /// Duración aproximada en formato "9h 30m".
  String get duracionStr {
    final a = _parseTime(horaInicio);
    final b = _parseTime(horaFin);
    if (a == null || b == null) return '-';
    int m = (b.hour * 60 + b.minute) - (a.hour * 60 + a.minute);
    if (m < 0) m += 24 * 60;
    final h = m ~/ 60;
    final min = m % 60;
    if (min > 0) return '${h}h ${min}m';
    return '${h}h';
  }

  TimeOfDay? _parseTime(String s) {
    final parts = s.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Formato 12h con AM/PM, ej: "08:00" -> "8:00 AM", "17:30" -> "5:30 PM".
  String _formatHora12(String s) {
    final t = _parseTime(s);
    if (t == null) return s;
    final h = t.hour;
    final m = t.minute;
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$h12:${m.toString().padLeft(2, '0')} $period';
  }

  String get horaInicio12 => _formatHora12(horaInicio);
  String get horaFin12 => _formatHora12(horaFin);
}

/// Pantalla de detalle de un turno (empleado, vehículo, horario, odómetro).
class DetalleTurnoPage extends StatelessWidget {
  const DetalleTurnoPage({
    super.key,
    required this.data,
  });

  final TurnoDetalleData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HistorialTurnosColors.background(context),
      appBar: AppBar(
        backgroundColor: HistorialTurnosColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: HistorialTurnosColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Detalle de Turno',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: HistorialTurnosColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: HistorialTurnosColors.textPrimary(context)),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _buildStatusPill(context),
          const SizedBox(height: 20),
          _buildCardEmpleadoVehiculo(context),
          const SizedBox(height: 16),
          _buildCardHorario(context),
          const SizedBox(height: 16),
          _buildCardOdometro(context),
          const SizedBox(height: 16),
          _buildCardKilometrajeActual(context),
          const SizedBox(height: 16),
          _buildCardDistanciaRecorrida(context),
        ],
      ),
    );
  }

  /// Card "Distancia Recorrida" como en Cierre de Turno, con icono en el título.
  Widget _buildCardDistanciaRecorrida(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HistorialTurnosColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: HistorialTurnosColors.accentWine, size: 22),
              const SizedBox(width: 8),
              Text(
                'Distancia Recorrida',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HistorialTurnosColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              data.distanciaKm,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: HistorialTurnosColors.textPrimary(context),
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.25,
              backgroundColor: ControlTurnosColors.progressUnfilled(context),
              valueColor: AlwaysStoppedAnimation<Color>(ControlTurnosColors.statusPillForeground(context)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  /// Card "Kilometraje actual" como en Apertura de Turno (Captura Odómetro), sin icono de editar.
  Widget _buildCardKilometrajeActual(BuildContext context) {
    final value = data.lecturaFinal ?? '142.593';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HistorialTurnosColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.straighten, color: HistorialTurnosColors.accentWine, size: 22),
              const SizedBox(width: 8),
              Text(
                'Kilometraje actual',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HistorialTurnosColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: HistorialTurnosColors.background(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.straighten, color: HistorialTurnosColors.textSecondary(context), size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          value,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: HistorialTurnosColors.textPrimary(context),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'km',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: HistorialTurnosColors.textSecondary(context),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Mismo diseño que la etiqueta de Estado en Resumen de Turno (texto e icono centrados).
  Widget _buildStatusPill(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: ResumenTurnoColors.statusCardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Turno Completado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ResumenTurnoColors.statusTextGreen,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardEmpleadoVehiculo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HistorialTurnosColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: HistorialTurnosColors.iconCircleBg(context),
                child: Text(
                  data.operador.isNotEmpty ? data.operador[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: HistorialTurnosColors.textPrimary(context),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.operador,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: HistorialTurnosColors.textPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID Empleado: ${data.idEmpleado}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: HistorialTurnosColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: HistorialTurnosColors.textSecondary(context).withValues(alpha: 0.35),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context, 'Vehículo'),
                    const SizedBox(height: 4),
                    Text(
                      data.vehiculo,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: HistorialTurnosColors.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _label(context, 'No. Económico'),
                    const SizedBox(height: 4),
                    Text(
                      data.noEconomico,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: HistorialTurnosColors.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(context, 'Placas'),
                    const SizedBox(height: 4),
                    Text(
                      data.placas,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: HistorialTurnosColors.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _label(context, 'Folio'),
                    const SizedBox(height: 4),
                    Text(
                      data.grupo,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: HistorialTurnosColors.textPrimary(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: HistorialTurnosColors.sectionHeading(context),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  Widget _buildCardHorario(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HistorialTurnosColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: HistorialTurnosColors.accentWine, size: 22),
              const SizedBox(width: 8),
              Text(
                'Horario del Turno',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HistorialTurnosColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inicio',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: HistorialTurnosColors.textSecondary(context),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.horaInicio12,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: HistorialTurnosColors.textPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      data.fechaStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: HistorialTurnosColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: HistorialTurnosColors.iconCircleBg(context), size: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Fin',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: HistorialTurnosColors.textSecondary(context),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.horaFin12,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: HistorialTurnosColors.textPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      data.fechaStr,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: HistorialTurnosColors.textSecondary(context),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: HistorialTurnosColors.textSecondary(context).withValues(alpha: 0.35),
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 16),
          Center(
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge,
                children: [
                  TextSpan(
                    text: 'Duración: ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: HistorialTurnosColors.sectionHeading(context),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  TextSpan(
                    text: data.duracionStr,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: HistorialTurnosColors.textPrimary(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardOdometro(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HistorialTurnosColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.speed, color: HistorialTurnosColors.accentWine, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Odómetro',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HistorialTurnosColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: ControlTurnosColors.statusPillBackground(context),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ControlTurnosColors.statusPillForeground(context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data.distanciaKm} total',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: ControlTurnosColors.statusPillForeground(context),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lectura Inicial',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: HistorialTurnosColors.textSecondary(context),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: HistorialTurnosColors.background(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.speed_outlined,
                        color: HistorialTurnosColors.textSecondary(context),
                        size: 32,
                      ),
                    ),
                    if (data.lecturaInicial != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        data.lecturaInicial!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HistorialTurnosColors.textPrimary(context),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lectura Final',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: HistorialTurnosColors.textSecondary(context),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: HistorialTurnosColors.background(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.speed_outlined,
                        color: HistorialTurnosColors.textSecondary(context),
                        size: 32,
                      ),
                    ),
                    if (data.lecturaFinal != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        data.lecturaFinal!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: HistorialTurnosColors.textPrimary(context),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
