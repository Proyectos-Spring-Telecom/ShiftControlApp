import 'package:flutter/material.dart';

import '../detalle_turno/detalle_turno_page.dart';
import 'historial_turnos_colors.dart';

class HistorialTurnosPage extends StatefulWidget {
  const HistorialTurnosPage({
    super.key,
    this.onOpenDrawer,
  });

  final VoidCallback? onOpenDrawer;

  @override
  State<HistorialTurnosPage> createState() => _HistorialTurnosPageState();
}

class _HistorialTurnosPageState extends State<HistorialTurnosPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static const List<_HistorialGroup> _grupos = [
    _HistorialGroup(
      titulo: 'Hoy',
      fechaStr: '12 Oct, 2023',
      items: [
        _HistorialItem(
          vehiculo: 'Ford Transit',
          id: 'XP-902',
          operador: 'Carlos Mendez',
          idEmpleado: 'OP-8821',
          noEconomico: 'ECO-204',
          placas: 'XP-902-A',
          grupo: 'Norte - Ruta 5',
          horaInicio: '08:00',
          horaFin: '17:30',
          distancia: '145 km',
          iconData: Icons.local_shipping_outlined,
        ),
        _HistorialItem(
          vehiculo: 'Mercedes Sprinter',
          id: 'BZ-114',
          operador: 'Carlos Mendez',
          idEmpleado: 'OP-8821',
          noEconomico: 'ECO-114',
          placas: 'BZ-114-A',
          grupo: 'Norte - Ruta 5',
          horaInicio: '06:00',
          horaFin: '14:00',
          distancia: '89 km',
          iconData: Icons.directions_bus_outlined,
        ),
      ],
    ),
    _HistorialGroup(
      titulo: 'Ayer',
      fechaStr: '11 Oct, 2023',
      items: [
        _HistorialItem(
          vehiculo: 'Ford Transit',
          id: 'XP-902',
          operador: 'Carlos Mendez',
          idEmpleado: 'OP-8821',
          noEconomico: 'ECO-204',
          placas: 'XP-902-A',
          grupo: 'Norte - Ruta 5',
          horaInicio: '10:30',
          horaFin: '19:45',
          distancia: '210 km',
          iconData: Icons.local_shipping_outlined,
        ),
        _HistorialItem(
          vehiculo: 'Tractor Unit',
          id: 'TR-44',
          operador: 'Carlos Mendez',
          idEmpleado: 'OP-8821',
          noEconomico: 'ECO-44',
          placas: 'TR-44-A',
          grupo: 'Norte - Ruta 5',
          horaInicio: '07:00',
          horaFin: '15:00',
          distancia: '42 km',
          iconData: Icons.agriculture_outlined,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              itemCount: _grupos.length,
              itemBuilder: (context, groupIndex) {
                final group = _grupos[groupIndex];
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
                            borderColor: group.titulo == 'Ayer'
                                ? HistorialTurnosColors.cardBorderAyer
                                : HistorialTurnosColors.accentWine,
                            onTap: () => _openDetalle(context, group.fechaStr, item),
                          ),
                        )),
                    if (groupIndex < _grupos.length - 1) const SizedBox(height: 20),
                  ],
                );
              },
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
          ],
        ),
      ),
    );
  }
}

class _HistorialGroup {
  const _HistorialGroup({
    required this.titulo,
    required this.fechaStr,
    required this.items,
  });
  final String titulo;
  final String fechaStr;
  final List<_HistorialItem> items;
}

class _HistorialItem {
  const _HistorialItem({
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
