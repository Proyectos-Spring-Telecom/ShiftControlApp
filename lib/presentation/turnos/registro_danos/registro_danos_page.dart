import 'package:flutter/material.dart';

import '../models/checklist_type.dart';
import 'models/damage_point_model.dart';
import 'registro_danos_colors.dart';
import 'widgets/damage_detail_sheet.dart';
import 'widgets/vehicle_view_widget.dart';

class RegistroDanosPage extends StatefulWidget {
  const RegistroDanosPage({
    super.key,
    this.checklistType = ChecklistType.apertura,
    this.onContinuar,
  });

  final ChecklistType checklistType;
  final VoidCallback? onContinuar;

  @override
  State<RegistroDanosPage> createState() => _RegistroDanosPageState();
}

class _RegistroDanosPageState extends State<RegistroDanosPage> {
  late DamageRegistrationState _state;

  @override
  void initState() {
    super.initState();
    _state = DamageRegistrationState(
      checklistType: widget.checklistType,
      points: _generateInitialPoints(),
      currentView: VehicleView.frontal,
    );
  }

  List<DamagePoint> _generateInitialPoints() {
    return [
      DamagePoint(id: 'li_cofre', view: VehicleView.lateralIzquierdo, relativeX: 0.2, relativeY: 0.42, zoneName: 'Cofre'),
      DamagePoint(id: 'li_parabrisas', view: VehicleView.lateralIzquierdo, relativeX: 0.35, relativeY: 0.3, zoneName: 'Parabrisas'),
      DamagePoint(id: 'li_techo', view: VehicleView.lateralIzquierdo, relativeX: 0.58, relativeY: 0.22, zoneName: 'Techo'),
      DamagePoint(id: 'li_puerta_del', view: VehicleView.lateralIzquierdo, relativeX: 0.38, relativeY: 0.48, zoneName: 'Puerta Delantera'),
      DamagePoint(id: 'li_puerta_tra', view: VehicleView.lateralIzquierdo, relativeX: 0.55, relativeY: 0.48, zoneName: 'Puerta Trasera'),
      DamagePoint(id: 'li_cajuela', view: VehicleView.lateralIzquierdo, relativeX: 0.8, relativeY: 0.42, zoneName: 'Cajuela'),
      DamagePoint(id: 'li_salpicadera_del', view: VehicleView.lateralIzquierdo, relativeX: 0.18, relativeY: 0.55, zoneName: 'Salpicadera Delantera'),
      DamagePoint(id: 'li_salpicadera_tra', view: VehicleView.lateralIzquierdo, relativeX: 0.75, relativeY: 0.55, zoneName: 'Salpicadera Trasera'),
      DamagePoint(id: 'li_espejo', view: VehicleView.lateralIzquierdo, relativeX: 0.32, relativeY: 0.4, zoneName: 'Espejo Lateral'),
      
      DamagePoint(id: 'ld_cofre', view: VehicleView.lateralDerecho, relativeX: 0.8, relativeY: 0.42, zoneName: 'Cofre'),
      DamagePoint(id: 'ld_parabrisas', view: VehicleView.lateralDerecho, relativeX: 0.65, relativeY: 0.3, zoneName: 'Parabrisas'),
      DamagePoint(id: 'ld_techo', view: VehicleView.lateralDerecho, relativeX: 0.42, relativeY: 0.22, zoneName: 'Techo'),
      DamagePoint(id: 'ld_puerta_del', view: VehicleView.lateralDerecho, relativeX: 0.62, relativeY: 0.48, zoneName: 'Puerta Delantera'),
      DamagePoint(id: 'ld_puerta_tra', view: VehicleView.lateralDerecho, relativeX: 0.45, relativeY: 0.48, zoneName: 'Puerta Trasera'),
      DamagePoint(id: 'ld_cajuela', view: VehicleView.lateralDerecho, relativeX: 0.2, relativeY: 0.42, zoneName: 'Cajuela'),
      DamagePoint(id: 'ld_salpicadera_del', view: VehicleView.lateralDerecho, relativeX: 0.82, relativeY: 0.55, zoneName: 'Salpicadera Delantera'),
      DamagePoint(id: 'ld_salpicadera_tra', view: VehicleView.lateralDerecho, relativeX: 0.25, relativeY: 0.55, zoneName: 'Salpicadera Trasera'),
      DamagePoint(id: 'ld_espejo', view: VehicleView.lateralDerecho, relativeX: 0.68, relativeY: 0.4, zoneName: 'Espejo Lateral'),
      
      DamagePoint(id: 'f_cofre', view: VehicleView.frontal, relativeX: 0.5, relativeY: 0.35, zoneName: 'Cofre'),
      DamagePoint(id: 'f_parabrisas', view: VehicleView.frontal, relativeX: 0.5, relativeY: 0.25, zoneName: 'Parabrisas'),
      DamagePoint(id: 'f_faro_izq', view: VehicleView.frontal, relativeX: 0.32, relativeY: 0.48, zoneName: 'Faro Izquierdo'),
      DamagePoint(id: 'f_faro_der', view: VehicleView.frontal, relativeX: 0.68, relativeY: 0.48, zoneName: 'Faro Derecho'),
      DamagePoint(id: 'f_parrilla', view: VehicleView.frontal, relativeX: 0.5, relativeY: 0.52, zoneName: 'Parrilla'),
      DamagePoint(id: 'f_defensa', view: VehicleView.frontal, relativeX: 0.5, relativeY: 0.62, zoneName: 'Defensa Frontal'),
      DamagePoint(id: 'f_salpicadera_izq', view: VehicleView.frontal, relativeX: 0.25, relativeY: 0.55, zoneName: 'Salpicadera Izquierda'),
      DamagePoint(id: 'f_salpicadera_der', view: VehicleView.frontal, relativeX: 0.75, relativeY: 0.55, zoneName: 'Salpicadera Derecha'),
      
      DamagePoint(id: 't_cajuela', view: VehicleView.trasera, relativeX: 0.5, relativeY: 0.35, zoneName: 'Cajuela'),
      DamagePoint(id: 't_ventana', view: VehicleView.trasera, relativeX: 0.5, relativeY: 0.25, zoneName: 'Ventana Trasera'),
      DamagePoint(id: 't_calavera_izq', view: VehicleView.trasera, relativeX: 0.3, relativeY: 0.45, zoneName: 'Calavera Izquierda'),
      DamagePoint(id: 't_calavera_der', view: VehicleView.trasera, relativeX: 0.7, relativeY: 0.45, zoneName: 'Calavera Derecha'),
      DamagePoint(id: 't_defensa', view: VehicleView.trasera, relativeX: 0.5, relativeY: 0.6, zoneName: 'Defensa Trasera'),
      DamagePoint(id: 't_placa', view: VehicleView.trasera, relativeX: 0.5, relativeY: 0.52, zoneName: 'Placa'),
      DamagePoint(id: 't_salpicadera_izq', view: VehicleView.trasera, relativeX: 0.25, relativeY: 0.55, zoneName: 'Salpicadera Izquierda'),
      DamagePoint(id: 't_salpicadera_der', view: VehicleView.trasera, relativeX: 0.75, relativeY: 0.55, zoneName: 'Salpicadera Derecha'),
    ];
  }

  void _onViewChanged(VehicleView view) {
    setState(() {
      _state = _state.copyWith(currentView: view);
    });
  }

  void _onPointTap(DamagePoint point) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DamageDetailSheet(
          point: point,
          onSave: (detail) => _saveDamage(point, detail),
        ),
      ),
    );
  }

  void _saveDamage(DamagePoint point, DamageDetail detail) {
    setState(() {
      final index = _state.points.indexWhere((p) => p.id == point.id);
      if (index != -1) {
        final updatedPoints = List<DamagePoint>.from(_state.points);
        updatedPoints[index] = point.copyWith(
          isDamaged: true,
          damageDetail: detail,
        );
        _state = _state.copyWith(points: updatedPoints);
      }
    });
  }

  String _getViewLabel(VehicleView view) {
    switch (view) {
      case VehicleView.frontal:
        return 'Frontal';
      case VehicleView.trasera:
        return 'Trasera';
      case VehicleView.lateralIzquierdo:
        return 'Lateral Izquierdo';
      case VehicleView.lateralDerecho:
        return 'Lateral Derecho';
    }
  }

  String _getDamageTypeLabel(DamageType type) {
    switch (type) {
      case DamageType.abolladura:
        return 'Abolladura';
      case DamageType.rayon:
        return 'Rayón';
      case DamageType.rotura:
        return 'Rotura';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegistroDanosColors.background(context),
      appBar: AppBar(
        backgroundColor: RegistroDanosColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: RegistroDanosColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Inspección Exterior',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: RegistroDanosColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgress(context),
                  const SizedBox(height: 20),
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildViewTabs(context),
                  const SizedBox(height: 16),
                  _buildVehicleArea(context),
                  const SizedBox(height: 24),
                  _buildResumen(context),
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
              'Paso 3 de 8',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: RegistroDanosColors.textSecondary(context),
                  ),
            ),
            Text(
              'Registro de Daños',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: RegistroDanosColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 3 / 8,
            backgroundColor: RegistroDanosColors.tabUnselected(context),
            valueColor: const AlwaysStoppedAnimation<Color>(RegistroDanosColors.pointDamaged),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 3),
        Text(
          'Toca las áreas del vehículo donde observes golpes, rayaduras o abolladuras.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RegistroDanosColors.textSecondary(context),
              ),
        ),
      ],
    );
  }

  Widget _buildViewTabs(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: VehicleView.values.map((view) {
          final isSelected = _state.currentView == view;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onViewChanged(view),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? RegistroDanosColors.tabSelected
                      : RegistroDanosColors.tabUnselected(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getViewLabel(view),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : RegistroDanosColors.textSecondary(context),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildVehicleArea(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: RegistroDanosColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: VehicleViewWidget(
        view: _state.currentView,
        points: _state.currentViewPoints,
        onPointTap: _onPointTap,
      ),
    );
  }

  Widget _buildResumen(BuildContext context) {
    final damagedPoints = _state.damagedPoints;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RegistroDanosColors.resumenBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: RegistroDanosColors.textSecondary(context),
                      letterSpacing: 1,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: RegistroDanosColors.resumenBadge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${damagedPoints.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (damagedPoints.isEmpty) ...[
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: RegistroDanosColors.textSecondary(context).withValues(alpha: 0.5),
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No se han registrado daños',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: RegistroDanosColors.textSecondary(context),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ] else ...[
            const SizedBox(height: 12),
            ...damagedPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: RegistroDanosColors.pointDamaged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_getDamageTypeLabel(point.damageDetail!.damageType)} en ${point.zoneName}',
                          style: TextStyle(
                            color: RegistroDanosColors.textPrimary(context),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildContinuarButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.onContinuar ?? () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001C6A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
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
      ),
    );
  }
}
