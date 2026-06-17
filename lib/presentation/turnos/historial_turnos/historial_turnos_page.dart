import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_format_utils.dart';
import '../../../data/models/turno_list_response.dart';
import '../detalle_turno/detalle_turno_page.dart';
import '../mi_turno_provider.dart';
import 'historial_turnos_colors.dart';

class HistorialTurnosPage extends ConsumerStatefulWidget {
  const HistorialTurnosPage({
    super.key,
    this.onOpenDrawer,
  });

  final VoidCallback? onOpenDrawer;

  @override
  ConsumerState<HistorialTurnosPage> createState() => _HistorialTurnosPageState();
}

class _HistorialTurnosPageState extends ConsumerState<HistorialTurnosPage> {
  static const int _maxDiasRetroceso = 30;

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

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<DateTime?> _selectedDates = [];
  final List<_HistorialGroup> _grupos = [];
  final Set<String> _fechasConsultadas = {};

  DateTime _fechaActualConsulta = DateTime.now();
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  bool _modoRango = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarInicial());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static const double _scrollPrefetchThreshold = 200;

  bool _onScrollNotification(ScrollNotification notification) {
    if (_modoRango || _isLoadingInitial || _isLoadingMore || !_hasMoreData) {
      return false;
    }

    debugPrint('[Historial] scroll: ${notification.runtimeType}');

    if (notification is OverscrollNotification) {
      final metrics = notification.metrics;
      final enElFinal = metrics.pixels >= metrics.maxScrollExtent;
      debugPrint(
        '[Historial] overscroll=${notification.overscroll} '
        'pixels=${metrics.pixels} max=${metrics.maxScrollExtent}',
      );
      if (enElFinal && notification.overscroll < 0) {
        debugPrint('[Historial] overscroll al final → cargar más');
        _cargarMasSiCorresponde();
      }
      return false;
    }

    if (notification is ScrollUpdateNotification ||
        notification is ScrollEndNotification) {
      if (!_scrollController.hasClients) return false;

      final position = _scrollController.position;
      final cercaDelFinal = position.pixels >=
          position.maxScrollExtent - _scrollPrefetchThreshold;
      final contenidoCorto =
          position.maxScrollExtent <= _scrollPrefetchThreshold;

      debugPrint(
        '[Historial] pixels=${position.pixels} '
        'max=${position.maxScrollExtent} '
        'cercaDelFinal=$cercaDelFinal contenidoCorto=$contenidoCorto',
      );

      if (cercaDelFinal || contenidoCorto) {
        debugPrint('[Historial] cerca del final → cargar más');
        _cargarMasSiCorresponde();
      }
    }

    return false;
  }

  String _formatoApi(DateTime fecha) {
    final local = DateTime(fecha.year, fecha.month, fecha.day);
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}-$m-$d';
  }

  String _claveFecha(DateTime fecha) => _formatoApi(fecha);

  String _fechaStrGrupo(DateTime fecha) {
    final mes = _mesesCortos[fecha.month - 1];
    return '${fecha.day} $mes, ${fecha.year}';
  }

  String _tituloGrupo(DateTime fecha) {
    final hoy = DateTime.now();
    final ayer = hoy.subtract(const Duration(days: 1));
    if (esMismoDia(fecha, hoy)) return 'Hoy';
    if (esMismoDia(fecha, ayer)) return 'Ayer';
    return _fechaStrGrupo(fecha);
  }

  String _formatearHora(DateTime? fecha) {
    if (fecha == null) return '—';
    final local = fecha.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatearDuracion(int? segundos) {
    if (segundos == null || segundos <= 0) return '—';
    final d = Duration(seconds: segundos);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m';
    return '${d.inSeconds}s';
  }

  DateTime _soloDia(DateTime fecha) =>
      DateTime(fecha.year, fecha.month, fecha.day);

  Future<List<TurnoListItem>> _fetchTurnos({
    required String fechaDesde,
    required String fechaHasta,
  }) async {
    return ref.read(turnosServiceProvider).listarTurnos(
          fechaDesde: fechaDesde,
          fechaHasta: fechaHasta,
        );
  }

  void _agregarTurnosDelDia(DateTime fecha, List<TurnoListItem> turnos) {
    if (turnos.isEmpty) return;
    final dia = _soloDia(fecha);
    final items = turnos.map(_toHistorialItem).toList();
    final indice = _grupos.indexWhere((g) => esMismoDia(g.fecha, dia));
    if (indice >= 0) {
      _grupos[indice].items.addAll(items);
    } else {
      _grupos.add(
        _HistorialGroup(
          titulo: _tituloGrupo(dia),
          fechaStr: _fechaStrGrupo(dia),
          fecha: dia,
          items: items,
        ),
      );
    }
  }

  _HistorialItem _toHistorialItem(TurnoListItem turno) {
    return _HistorialItem(
      turno: turno,
      vehiculo: turno.vehiculoDisplay,
      id: turno.placas,
      operador: '—',
      idEmpleado: '—',
      noEconomico: turno.id.toString(),
      placas: turno.placas,
      grupo: turno.estatusTurnoNombre ?? '—',
      horaInicio: _formatearHora(turno.fechaApertura),
      horaFin: _formatearHora(turno.fechaCierre),
      distancia: _formatearDuracion(turno.duracionSegundos),
      iconData: Icons.local_shipping_outlined,
    );
  }

  Future<void> _cargarInicial() async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
      _grupos.clear();
      _fechasConsultadas.clear();
      _hasMoreData = true;
      _modoRango = false;
      _fechaActualConsulta = _soloDia(DateTime.now());
    });

    try {
      final items = await _consultarDia(_fechaActualConsulta);
      if (!mounted) return;
      if (items.isNotEmpty) {
        _agregarTurnosDelDia(_fechaActualConsulta, items);
      }
      _fechaActualConsulta =
          _fechaActualConsulta.subtract(const Duration(days: 1));
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No se pudo cargar el historial: $e');
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _cargarHastaPrimerDiaConDatos() async {
    var diasRetrocedidos = 0;
    while (diasRetrocedidos < _maxDiasRetroceso && _hasMoreData) {
      final clave = _claveFecha(_fechaActualConsulta);
      if (_fechasConsultadas.contains(clave)) {
        _fechaActualConsulta =
            _fechaActualConsulta.subtract(const Duration(days: 1));
        diasRetrocedidos++;
        continue;
      }

      final items = await _consultarDia(_fechaActualConsulta);
      if (items.isNotEmpty) {
        _agregarTurnosDelDia(_fechaActualConsulta, items);
        _fechaActualConsulta =
            _fechaActualConsulta.subtract(const Duration(days: 1));
        return;
      }

      _fechaActualConsulta =
          _fechaActualConsulta.subtract(const Duration(days: 1));
      diasRetrocedidos++;
    }

    if (_grupos.isEmpty) {
      _hasMoreData = false;
    }
  }

  Future<List<TurnoListItem>> _consultarDia(DateTime fecha) async {
    final clave = _claveFecha(fecha);
    if (_fechasConsultadas.contains(clave)) return const [];
    _fechasConsultadas.add(clave);

    final api = _formatoApi(fecha);
    return _fetchTurnos(fechaDesde: api, fechaHasta: api);
  }

  Future<void> _cargarMasSiCorresponde() async {
    if (_modoRango || _isLoadingInitial || _isLoadingMore || !_hasMoreData) {
      debugPrint(
        '[Historial] _cargarMasSiCorresponde omitido: '
        'modoRango=$_modoRango loading=$_isLoadingInitial '
        'loadingMore=$_isLoadingMore hasMore=$_hasMoreData',
      );
      return;
    }

    debugPrint('[Historial] _cargarMasSiCorresponde iniciado');

    setState(() {
      _isLoadingMore = true;
      _errorMessage = null;
    });

    try {
      var diasBuscados = 0;
      var encontroDatos = false;

      while (diasBuscados < _maxDiasRetroceso && !encontroDatos) {
        final clave = _claveFecha(_fechaActualConsulta);

        if (_fechasConsultadas.contains(clave)) {
          _fechaActualConsulta =
              _fechaActualConsulta.subtract(const Duration(days: 1));
          diasBuscados++;
          continue;
        }

        final items = await _consultarDia(_fechaActualConsulta);

        if (!mounted) return;

        if (items.isNotEmpty) {
          debugPrint(
            '[Historial] datos encontrados: ${_claveFecha(_fechaActualConsulta)} '
            '(${items.length} turnos)',
          );
          _agregarTurnosDelDia(_fechaActualConsulta, items);
          _fechaActualConsulta =
              _fechaActualConsulta.subtract(const Duration(days: 1));
          encontroDatos = true;
        } else {
          _fechaActualConsulta =
              _fechaActualConsulta.subtract(const Duration(days: 1));
          diasBuscados++;
        }
      }

      if (!mounted) return;

      if (!encontroDatos) {
        debugPrint('[Historial] sin más datos en $_maxDiasRetroceso días');
        _hasMoreData = false;
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'No se pudo cargar más turnos: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _aplicarFiltroFechaUnica(DateTime fecha) async {
    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
      _grupos.clear();
      _fechasConsultadas.clear();
      _hasMoreData = true;
      _modoRango = false;
      _fechaActualConsulta = _soloDia(fecha);
      _selectedDates = [fecha];
    });

    try {
      final items = await _consultarDia(_fechaActualConsulta);
      if (!mounted) return;
      if (items.isNotEmpty) {
        _agregarTurnosDelDia(_fechaActualConsulta, items);
      }
      _fechaActualConsulta =
          _fechaActualConsulta.subtract(const Duration(days: 1));
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'No se pudo filtrar por fecha: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _aplicarFiltroRango(DateTime inicio, DateTime fin) async {
    final desde = inicio.isBefore(fin) ? inicio : fin;
    final hasta = inicio.isBefore(fin) ? fin : inicio;

    setState(() {
      _isLoadingInitial = true;
      _errorMessage = null;
      _grupos.clear();
      _fechasConsultadas.clear();
      _hasMoreData = false;
      _modoRango = true;
      _selectedDates = [desde, hasta];
    });

    try {
      final items = await _fetchTurnos(
        fechaDesde: _formatoApi(desde),
        fechaHasta: _formatoApi(hasta),
      );
      final porDia = <DateTime, List<TurnoListItem>>{};
      for (final turno in items) {
        final fecha = _soloDia(turno.fechaCierre ?? turno.fechaApertura ?? desde);
        porDia.putIfAbsent(fecha, () => []).add(turno);
      }
      final diasOrdenados = porDia.keys.toList()..sort((a, b) => b.compareTo(a));
      for (final dia in diasOrdenados) {
        _agregarTurnosDelDia(dia, porDia[dia]!);
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'No se pudo filtrar por rango: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoadingInitial = false);
    }
  }

  Future<void> _abrirCalendario() async {
    final values = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.range,
      ),
      dialogSize: const Size(325, 400),
      value: _selectedDates,
      dialogBackgroundColor: HistorialTurnosColors.cardBackground(context),
      borderRadius: BorderRadius.circular(12),
    );
    if (!mounted || values == null) return;

    final fechas = values.whereType<DateTime>().toList();
    if (fechas.isEmpty) {
      _selectedDates = [];
      await _cargarInicial();
      return;
    }

    if (fechas.length == 1) {
      await _aplicarFiltroFechaUnica(_soloDia(fechas.first));
      return;
    }

    await _aplicarFiltroRango(
      _soloDia(fechas[0]),
      _soloDia(fechas[1]),
    );
  }

  List<_HistorialGroup> get _gruposVisibles {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _grupos;

    return _grupos
        .map((group) {
          final items = group.items.where((item) {
            return item.vehiculo.toLowerCase().contains(query) ||
                item.operador.toLowerCase().contains(query) ||
                item.placas.toLowerCase().contains(query) ||
                item.id.toLowerCase().contains(query);
          }).toList();
          if (items.isEmpty) return null;
          return _HistorialGroup(
            titulo: group.titulo,
            fechaStr: group.fechaStr,
            fecha: group.fecha,
            items: items,
          );
        })
        .whereType<_HistorialGroup>()
        .toList();
  }

  bool get _tieneFiltroFecha =>
      _selectedDates.whereType<DateTime>().isNotEmpty;

  String? get _textoFiltroActivo {
    final fechas = _selectedDates.whereType<DateTime>().toList();
    if (fechas.isEmpty) return null;

    if (_modoRango && fechas.length >= 2) {
      final inicio = fechas[0].isBefore(fechas[1]) ? fechas[0] : fechas[1];
      final fin = fechas[0].isBefore(fechas[1]) ? fechas[1] : fechas[0];
      if (esMismoDia(inicio, fin)) {
        return 'Turnos del ${_formatoApi(inicio)}';
      }
      return 'Turnos del ${_formatoApi(inicio)} al ${_formatoApi(fin)}';
    }

    return 'Turnos del ${_formatoApi(_soloDia(fechas.first))}';
  }

  Future<void> _limpiarFiltro() async {
    if (_isLoadingInitial) return;
    setState(() => _selectedDates = []);
    await _cargarInicial();
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _gruposVisibles;

    return Scaffold(
      backgroundColor: HistorialTurnosColors.background(context),
      appBar: AppBar(
        backgroundColor: HistorialTurnosColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: HistorialTurnosColors.textPrimary(context),
          ),
          onPressed: () {
            if (widget.onOpenDrawer != null) {
              widget.onOpenDrawer!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        titleSpacing: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Historial de Turnos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: HistorialTurnosColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(context),
          _buildFiltroActivoIndicator(context),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HistorialTurnosColors.accentWine,
                    ),
              ),
            ),
          Expanded(
            child: _isLoadingInitial
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: _onScrollNotification,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: grupos.isEmpty
                          ? 1
                          : grupos.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, groupIndex) {
                        if (grupos.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Sin turnos para hoy',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: HistorialTurnosColors
                                              .textSecondary(context),
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Desliza hacia abajo para buscar días anteriores',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: HistorialTurnosColors
                                              .textSecondary(context),
                                        ),
                                  ),
                                  if (_hasMoreData && !_modoRango)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: TextButton.icon(
                                        onPressed: _isLoadingMore
                                            ? null
                                            : _cargarMasSiCorresponde,
                                        icon: const Icon(
                                          Icons.keyboard_arrow_down,
                                        ),
                                        label: Text(
                                          _isLoadingMore
                                              ? 'Buscando...'
                                              : 'Buscar días anteriores',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }

                        if (groupIndex >= grupos.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }

                          final group = grupos[groupIndex];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.titulo,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: HistorialTurnosColors.textPrimary(context),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              ...group.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _HistorialCard(
                                      item: item,
                                      fechaStr: group.fechaStr,
                                      borderColor: group.titulo == 'Hoy'
                                          ? HistorialTurnosColors.accentWine
                                          : HistorialTurnosColors.cardBorderAyer,
                                      onTap: () =>
                                          _openDetalle(context, group.fechaStr, item),
                                    ),
                                  )),
                              if (groupIndex < grupos.length - 1) const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  void _openDetalle(BuildContext context, String fechaStr, _HistorialItem item) {
    final data = TurnoDetalleData(
      operador: item.operador,
      idEmpleado: item.idEmpleado,
      vehiculo: item.vehiculo,
      noEconomico: item.noEconomico,
      placas: item.placas,
      grupo: item.grupo,
      fechaStr: fechaStr,
      horaInicio: item.horaInicio,
      horaFin: item.horaFin,
      distanciaKm: item.distancia,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetalleTurnoPage(data: data),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: HistorialTurnosColors.cardBackground(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: HistorialTurnosColors.searchPlaceholder(context),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: HistorialTurnosColors.textPrimary(context)),
                decoration: InputDecoration(
                  hintText: 'Buscar vehículo o conductor...',
                  hintStyle: TextStyle(
                    color: HistorialTurnosColors.searchPlaceholder(context),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  isDense: true,
                  filled: true,
                  fillColor: HistorialTurnosColors.cardBackground(context),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.calendar_today_outlined,
                color: _selectedDates.whereType<DateTime>().isNotEmpty
                    ? HistorialTurnosColors.accentWine
                    : HistorialTurnosColors.searchPlaceholder(context),
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: _abrirCalendario,
              tooltip: 'Filtrar por fecha',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroActivoIndicator(BuildContext context) {
    if (!_tieneFiltroFecha) return const SizedBox.shrink();

    final texto = _textoFiltroActivo;
    if (texto == null) return const SizedBox.shrink();

    final baseSmall = Theme.of(context).textTheme.bodySmall;
    final indicadorFontSize = (baseSmall?.fontSize ?? 12) * 1.2;
    final indicadorStyle = baseSmall?.copyWith(
      color: HistorialTurnosColors.textPrimary(context),
      fontSize: indicadorFontSize,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              texto,
              style: indicadorStyle,
            ),
          ),
          TextButton(
            onPressed: _isLoadingInitial ? null : _limpiarFiltro,
            style: TextButton.styleFrom(
              foregroundColor: HistorialTurnosColors.accentWine,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Limpiar',
              style: indicadorStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorialGroup {
  _HistorialGroup({
    required this.titulo,
    required this.fechaStr,
    required this.fecha,
    required this.items,
  });

  final String titulo;
  final String fechaStr;
  final DateTime fecha;
  final List<_HistorialItem> items;
}

class _HistorialItem {
  const _HistorialItem({
    required this.turno,
    required this.vehiculo,
    required this.id,
    required this.operador,
    required this.idEmpleado,
    required this.noEconomico,
    required this.placas,
    required this.grupo,
    required this.horaInicio,
    required this.horaFin,
    required this.distancia,
    required this.iconData,
  });

  final TurnoListItem turno;
  final String vehiculo;
  final String id;
  final String operador;
  final String idEmpleado;
  final String noEconomico;
  final String placas;
  final String grupo;
  final String horaInicio;
  final String horaFin;
  final String distancia;
  final IconData iconData;
}

class _HistorialCard extends StatelessWidget {
  const _HistorialCard({
    required this.item,
    required this.fechaStr,
    required this.borderColor,
    required this.onTap,
  });

  final _HistorialItem item;
  final String fechaStr;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: HistorialTurnosColors.cardBackground(context),
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(
                color: borderColor,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: borderColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.iconData, color: borderColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: HistorialTurnosColors.textPrimary(context),
                              fontWeight: FontWeight.w600,
                            ),
                        children: [
                          TextSpan(text: '${item.vehiculo} • '),
                          TextSpan(
                            text: item.id,
                            style: const TextStyle(color: HistorialTurnosColors.accentWine),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Operador: ${item.operador}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: HistorialTurnosColors.textPrimary(context),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: HistorialTurnosColors.textSecondary(context)),
                        const SizedBox(width: 4),
                        Text(
                          '${item.horaInicio} - ${item.horaFin}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: HistorialTurnosColors.textSecondary(context),
                              ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.location_on_outlined, size: 14, color: HistorialTurnosColors.textSecondary(context)),
                        const SizedBox(width: 4),
                        Text(
                          item.distancia,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: HistorialTurnosColors.textSecondary(context),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: HistorialTurnosColors.textSecondary(context),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
