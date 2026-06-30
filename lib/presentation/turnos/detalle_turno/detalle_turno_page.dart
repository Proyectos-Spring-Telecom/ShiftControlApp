import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/models/informacion_general_response.dart';
import '../../../data/models/turno_detalle_response.dart';
import '../control_turnos_colors.dart';
import '../historial_turnos/historial_turnos_colors.dart';
import '../mi_turno_provider.dart';
import '../resumen_turno/resumen_turno_colors.dart';
import '../../widgets/expandable_network_image.dart';
import 'widgets/compartir_reporte_sheets.dart';

/// Datos necesarios para mostrar el detalle de un turno.
class TurnoDetalleData {
  const TurnoDetalleData({
    required this.operador,
    required this.idEmpleado,
    required this.vehiculo,
    required this.noEconomico,
    required this.placas,
    required this.grupo,
    required this.estatusNombre,
    required this.fechaStr,
    required this.fechaFinStr,
    required this.horaInicio,
    this.horaFin,
    this.duracion,
    required this.distanciaKm,
    this.lecturaInicial,
    this.lecturaFinal,
    this.fotoLecturaInicial,
    this.fotoLecturaFinal,
    this.estadoVehiculo = const [],
    this.estadoVehiculoCierre = const [],
    this.mostrarEstadoVehiculoCierre = false,
    this.incidenciasGasolina = const [],
    this.incidenciasAccidente = const [],
  });

  final String operador;
  final String idEmpleado;
  final String vehiculo;
  final String noEconomico;
  final String placas;
  final String grupo;
  final String estatusNombre;
  final String fechaStr;
  final String fechaFinStr;
  final String horaInicio;
  final String? horaFin;
  final String? duracion;
  final String distanciaKm;
  final String? lecturaInicial;
  final String? lecturaFinal;
  final String? fotoLecturaInicial;
  final String? fotoLecturaFinal;
  final List<EstadoVehiculoItem> estadoVehiculo;
  final List<EstadoVehiculoItem> estadoVehiculoCierre;
  final bool mostrarEstadoVehiculoCierre;
  final List<IncidenciaGasolinaItem> incidenciasGasolina;
  final List<IncidenciaAccidenteItem> incidenciasAccidente;

  factory TurnoDetalleData.fromTurnoDetalle(TurnoDetalle turno) {
    final inicio = turno.bitacoraResumen?.inicio;
    final fin = turno.bitacoraResumen?.fin;
    final kmInicial = inicio?.tablero?.kmActual;
    final kmFinal = fin?.tablero?.kmActual;

    return TurnoDetalleData(
      operador: _nombreOperador(turno.usuarioDetalle),
      idEmpleado: _idOperador(turno.usuarioDetalle),
      vehiculo: _tituloVehiculo(turno),
      noEconomico: turno.vehiculoPlaca?.numeroEconomico ?? '—',
      placas: _placas(turno),
      grupo: turno.id.toString(),
      estatusNombre: turno.estatusTurno?.nombre ?? '—',
      fechaStr: _formatearFecha(turno.fechaApertura),
      fechaFinStr: turno.fechaCierre != null
          ? _formatearFecha(turno.fechaCierre)
          : _formatearFecha(turno.fechaApertura),
      horaInicio: _formatearHora(turno.fechaApertura),
      horaFin:
          turno.fechaCierre != null ? _formatearHora(turno.fechaCierre) : null,
      duracion: turno.duracion,
      distanciaKm: _distanciaRecorrida(kmInicial, kmFinal),
      lecturaInicial: formatearKm(kmInicial),
      lecturaFinal: formatearKm(kmFinal),
      fotoLecturaInicial: _fotoInicio(turno),
      fotoLecturaFinal: _fotoFin(turno),
      estadoVehiculo: inicio?.informacionGeneral?.estadoVehiculo ?? const [],
      estadoVehiculoCierre: fin?.informacionGeneral?.estadoVehiculo ?? const [],
      mostrarEstadoVehiculoCierre:
          fin != null && fin.informacionGeneral != null,
      incidenciasGasolina: turno.incidenciasGasolina,
      incidenciasAccidente: turno.incidenciasAccidente,
    );
  }

  /// Duración del API (ej. 09:30:00) o cálculo aproximado como fallback.
  String get duracionStr {
    if (duracion != null && duracion!.trim().isNotEmpty) {
      return duracion!.trim();
    }
    final a = _parseTime(horaInicio);
    final b = horaFin != null ? _parseTime(horaFin!) : null;
    if (a == null || b == null) return '—';
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

  String get horaFin12 =>
      horaFin == null ? 'Turno en curso' : _formatHora12(horaFin!);

  static String _nombreOperador(UsuarioDetalle? usuario) {
    if (usuario == null) return '—';
    final partes = [
      usuario.nombre,
      usuario.apellidoPaterno,
      usuario.apellidoMaterno,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
    if (partes.isNotEmpty) return partes.join(' ');
    return '—';
  }

  static String _idOperador(UsuarioDetalle? usuario) {
    final id = usuario?.id;
    if (id == null) return '—';
    return id.toString();
  }

  static String _tituloVehiculo(TurnoDetalle turno) {
    final placa = turno.vehiculoPlaca;
    if (placa != null) {
      final marcaModelo = [placa.marcaNombre, placa.modeloNombre]
          .whereType<String>()
          .where((s) => s.trim().isNotEmpty)
          .join(' ');
      if (marcaModelo.isNotEmpty) {
        if (placa.anio != null) return '$marcaModelo - ${placa.anio}';
        return marcaModelo;
      }
    }
    if (turno.vehiculo?.trim().isNotEmpty == true) return turno.vehiculo!.trim();
    if (placa?.placa?.trim().isNotEmpty == true) return placa!.placa!.trim();
    return '—';
  }

  static String _placas(TurnoDetalle turno) {
    final placa = turno.vehiculoPlaca?.placa?.trim();
    if (placa != null && placa.isNotEmpty) return placa;
    return '—';
  }

  static String? _fotoInicio(TurnoDetalle turno) {
    final tablero = turno.bitacoraResumen?.inicio?.tablero?.fotoTablero;
    if (tablero != null && tablero.trim().isNotEmpty) return tablero;
    final evidencia = turno.evidenciaApertura;
    if (evidencia != null && evidencia.trim().isNotEmpty) return evidencia;
    return null;
  }

  static String? _fotoFin(TurnoDetalle turno) {
    final tablero = turno.bitacoraResumen?.fin?.tablero?.fotoTablero;
    if (tablero != null && tablero.trim().isNotEmpty) return tablero;
    final evidencia = turno.evidenciaCierre;
    if (evidencia != null && evidencia.trim().isNotEmpty) return evidencia;
    return null;
  }

  static String _distanciaRecorrida(num? inicial, num? finalKm) {
    if (inicial == null || finalKm == null) return '—';
    final diff = finalKm - inicial;
    if (diff < 0) return '—';
    return formatearKm(diff) ?? '—';
  }

  static String? formatearKm(num? km) {
    if (km == null) return null;
    if (km == km.roundToDouble()) {
      return km.round().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return km.toString();
  }

  static const List<String> _mesesCortos = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    final local = DateTime(fecha.year, fecha.month, fecha.day);
    final mes = _mesesCortos[local.month - 1];
    return '${local.day} $mes, ${local.year}';
  }

  static String _formatearHora(DateTime? fecha) {
    if (fecha == null) return '—';
    final local = fecha.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatearFechaHoraRegistro(DateTime? fecha) {
    if (fecha == null) return '—';
    final local = fecha.toLocal();
    final mes = _mesesCortos[local.month - 1];
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '${local.day} $mes ${local.year} $h:$m';
  }

  static String formatearMonedaMxn(double? valor) {
    if (valor == null) return '—';
    return '\$${valor.toStringAsFixed(2)} MXN';
  }
}

/// Pantalla de detalle de un turno (empleado, vehículo, horario, odómetro).
class DetalleTurnoPage extends ConsumerStatefulWidget {
  const DetalleTurnoPage({
    super.key,
    required this.idTurno,
  });

  final int idTurno;

  @override
  ConsumerState<DetalleTurnoPage> createState() => _DetalleTurnoPageState();
}

class _DetalleTurnoPageState extends ConsumerState<DetalleTurnoPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(turnoDetalleProvider.notifier).fetch(widget.idTurno),
    );
  }

  void _mostrarOpcionesCompartir(BuildContext context) {
    showCompartirReporteOpciones(
      context,
      turnoId: widget.idTurno,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detalleAsync = ref.watch(turnoDetalleProvider);

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
            onPressed: () => _mostrarOpcionesCompartir(context),
          ),
        ],
      ),
      body: detalleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _mensajeError(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HistorialTurnosColors.accentWine,
                  ),
            ),
          ),
        ),
        data: (data) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            _buildStatusPill(context, data),
            const SizedBox(height: 20),
            _buildCardEmpleadoVehiculo(context, data),
            const SizedBox(height: 16),
            _buildCardEstadoVehiculo(
              context,
              titulo: 'Estado del Vehículo — Apertura',
              items: data.estadoVehiculo,
            ),
            if (data.mostrarEstadoVehiculoCierre) ...[
              const SizedBox(height: 16),
              _buildCardEstadoVehiculo(
                context,
                titulo: 'Estado del Vehículo — Cierre',
                items: data.estadoVehiculoCierre,
              ),
            ],
            const SizedBox(height: 16),
            _buildCardHorario(context, data),
            const SizedBox(height: 16),
            _buildCardOdometro(context, data),
            const SizedBox(height: 16),
            _buildCardKilometrajeActual(context, data),
            if (data.incidenciasGasolina.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCardIncidenciasGasolina(context, data),
            ],
            if (data.incidenciasAccidente.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCardIncidenciasAccidente(context, data),
            ],
            // TODO: Se oculta temporalmente hasta contar con
            // información oficial de distancia recorrida.
            // const SizedBox(height: 16),
            // _buildCardDistanciaRecorrida(context, data),
            const SizedBox(height: 24),
            _buildFinDetalleTurno(context),
          ],
        ),
      ),
    );
  }

  String _mensajeError(Object error) {
    if (error is AuthException) return error.message;
    if (error is NetworkException) {
      if (error.code == '404') return 'Turno no encontrado.';
      return error.message;
    }
    return 'No se pudo cargar el detalle del turno.';
  }

  Widget _buildFinDetalleTurno(BuildContext context) {
    final secondary = HistorialTurnosColors.textSecondary(context);
    final dividerColor = secondary.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: dividerColor, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline, size: 15, color: secondary),
                const SizedBox(width: 6),
                Text(
                  'Fin del detalle del turno',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: secondary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          Expanded(child: Divider(color: dividerColor, height: 1)),
        ],
      ),
    );
  }

  // ignore: unused_element — se reactivará cuando exista distancia oficial del API.
  Widget _buildCardDistanciaRecorrida(BuildContext context, TurnoDetalleData data) {
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

  Widget _buildCardKilometrajeActual(BuildContext context, TurnoDetalleData data) {
    final value = data.lecturaFinal ?? '—';
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

  Widget _buildStatusPill(BuildContext context, TurnoDetalleData data) {
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
            data.estatusNombre,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ResumenTurnoColors.statusTextGreen,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardEmpleadoVehiculo(BuildContext context, TurnoDetalleData data) {
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
                  data.operador.isNotEmpty && data.operador != '—'
                      ? data.operador[0].toUpperCase()
                      : '?',
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

  Widget _buildCardEstadoVehiculo(
    BuildContext context, {
    required String titulo,
    required List<EstadoVehiculoItem> items,
  }) {
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
              Icon(Icons.checklist_rtl, color: HistorialTurnosColors.accentWine, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HistorialTurnosColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'No disponible',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HistorialTurnosColors.textSecondary(context),
                  ),
            )
          else
            for (int i = 0; i < items.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      '${items[i].etiqueta ?? '—'}:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: HistorialTurnosColors.textSecondary(context),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Text(
                    items[i].valor ?? '—',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: HistorialTurnosColors.textPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              if (i < items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    color: HistorialTurnosColors.textSecondary(context).withValues(alpha: 0.35),
                    height: 1,
                    thickness: 1,
                  ),
                ),
            ],
        ],
      ),
    );
  }

  Widget _buildCardHorario(BuildContext context, TurnoDetalleData data) {
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
                      data.fechaFinStr,
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

  Widget _buildCardOdometro(BuildContext context, TurnoDetalleData data) {
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
                      data.distanciaKm == '—'
                          ? '${data.distanciaKm} total'
                          : '${data.distanciaKm} km total',
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
                    _buildFotoOdometro(
                      context,
                      data.fotoLecturaInicial,
                      heroTag: 'odometro-apertura-${widget.idTurno}',
                    ),
                    if (data.lecturaInicial != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${data.lecturaInicial!} km',
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
                    _buildFotoOdometro(
                      context,
                      data.fotoLecturaFinal,
                      heroTag: 'odometro-cierre-${widget.idTurno}',
                    ),
                    if (data.lecturaFinal != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${data.lecturaFinal!} km',
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

  Widget _buildFotoOdometro(
    BuildContext context,
    String? url, {
    required String heroTag,
  }) {
    return ExpandableNetworkImage(
      imageUrl: url,
      heroTag: heroTag,
      backgroundColor: HistorialTurnosColors.background(context),
      placeholder: _placeholderOdometro(context),
    );
  }

  Widget _buildCardIncidenciasGasolina(
    BuildContext context,
    TurnoDetalleData data,
  ) {
    return _buildIncidenciasCard(
      context,
      titulo: 'Registro de Combustible',
      icon: Icons.local_gas_station_outlined,
      children: [
        for (int i = 0; i < data.incidenciasGasolina.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: HistorialTurnosColors.textSecondary(context)
                    .withValues(alpha: 0.35),
                height: 1,
                thickness: 1,
              ),
            ),
          _buildIncidenciaGasolinaItem(
            context,
            data.incidenciasGasolina[i],
            turnoId: widget.idTurno,
          ),
        ],
      ],
    );
  }

  Widget _buildOdometroStyleFotoColumn(
    BuildContext context, {
    required String label,
    required String? url,
    required String heroTag,
  }) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HistorialTurnosColors.textSecondary(context),
              ),
        ),
        const SizedBox(height: 8),
        _buildFotoOdometro(context, url, heroTag: heroTag),
      ],
    );
  }

  Widget _buildIncidenciaGasolinaItem(
    BuildContext context,
    IncidenciaGasolinaItem item, {
    required int turnoId,
  }) {
    final tieneFotoTablero = item.fotoTableroAntes?.isNotEmpty == true;
    final tieneFotoBomba = item.fotoBomba?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIncidenciaCampo(
          context,
          'Fecha',
          TurnoDetalleData.formatearFechaHoraRegistro(item.fechaRegistro),
        ),
        const SizedBox(height: 10),
        _buildIncidenciaCampo(
          context,
          'Litros cargados',
          item.litrosCargados != null
              ? '${item.litrosCargados!.toStringAsFixed(1)} L'
              : '—',
        ),
        const SizedBox(height: 10),
        _buildIncidenciaCampo(
          context,
          'Total pagado',
          TurnoDetalleData.formatearMonedaMxn(item.totalPagado),
        ),
        const SizedBox(height: 10),
        _buildIncidenciaCampo(
          context,
          'Kilometraje',
          item.kilometraje != null
              ? '${TurnoDetalleData.formatearKm(item.kilometraje) ?? item.kilometraje} km'
              : '—',
        ),
        if (tieneFotoTablero || tieneFotoBomba) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tieneFotoTablero)
                Expanded(
                  child: _buildOdometroStyleFotoColumn(
                    context,
                    label: 'Foto tablero',
                    url: item.fotoTableroAntes,
                    heroTag: 'combustible-$turnoId-${item.id}-tablero',
                  ),
                ),
              if (tieneFotoTablero && tieneFotoBomba) const SizedBox(width: 16),
              if (tieneFotoBomba)
                Expanded(
                  child: _buildOdometroStyleFotoColumn(
                    context,
                    label: 'Foto bomba',
                    url: item.fotoBomba,
                    heroTag: 'combustible-$turnoId-${item.id}-bomba',
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCardIncidenciasAccidente(
    BuildContext context,
    TurnoDetalleData data,
  ) {
    return _buildIncidenciasCard(
      context,
      titulo: 'Incidencias de Accidente',
      icon: Icons.car_crash_outlined,
      children: [
        for (int i = 0; i < data.incidenciasAccidente.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(
                color: HistorialTurnosColors.textSecondary(context)
                    .withValues(alpha: 0.35),
                height: 1,
                thickness: 1,
              ),
            ),
          _buildIncidenciaAccidenteItem(
            context,
            data.incidenciasAccidente[i],
            turnoId: widget.idTurno,
          ),
        ],
      ],
    );
  }

  Widget _buildIncidenciaAccidenteItem(
    BuildContext context,
    IncidenciaAccidenteItem item, {
    required int turnoId,
  }) {
    final tipo = item.catTipoIncidente?.nombre?.trim();
    final evidencias = <({String label, String url})>[
      if (item.fotoEvidencia1 != null)
        (label: 'Evidencia 1', url: item.fotoEvidencia1!),
      if (item.fotoEvidencia2 != null)
        (label: 'Evidencia 2', url: item.fotoEvidencia2!),
      if (item.fotoEvidencia3 != null)
        (label: 'Evidencia 3', url: item.fotoEvidencia3!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIncidenciaCampo(
          context,
          'Fecha',
          TurnoDetalleData.formatearFechaHoraRegistro(item.fechaRegistro),
        ),
        const SizedBox(height: 10),
        _buildIncidenciaCampo(
          context,
          'Tipo de incidente',
          (tipo != null && tipo.isNotEmpty) ? tipo : 'Sin categoría',
        ),
        const SizedBox(height: 10),
        _buildIncidenciaCampo(
          context,
          'Descripción',
          (item.descripcion?.trim().isNotEmpty == true)
              ? item.descripcion!.trim()
              : '—',
        ),
        if (evidencias.isNotEmpty) ...[
          const SizedBox(height: 14),
          ...evidencias.map(
            (evidencia) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    evidencia.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HistorialTurnosColors.textSecondary(context),
                        ),
                  ),
                  const SizedBox(height: 6),
                  ExpandableNetworkImage(
                    imageUrl: evidencia.url,
                    heroTag:
                        'incidencia-accidente-$turnoId-${item.id}-${evidencia.label}',
                    hideWhenEmpty: true,
                    backgroundColor:
                        HistorialTurnosColors.background(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildIncidenciasCard(
    BuildContext context, {
    required String titulo,
    required IconData icon,
    required List<Widget> children,
  }) {
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
              Icon(icon, color: HistorialTurnosColors.accentWine, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HistorialTurnosColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildIncidenciaCampo(
    BuildContext context,
    String etiqueta,
    String valor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            '$etiqueta:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HistorialTurnosColors.textSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HistorialTurnosColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _placeholderOdometro(BuildContext context) {
    return Center(
      child: Icon(
        Icons.speed_outlined,
        color: HistorialTurnosColors.textSecondary(context),
        size: 32,
      ),
    );
  }
}
