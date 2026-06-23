import 'package:flutter/material.dart';
import '../../widgets/app_alert_banner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/registrar_niveles_fluidos_request.dart';
import '../checklist_apertura_navigation.dart';
import '../checklist_progress_provider.dart';
import '../mi_turno_provider.dart';
import '../models/checklist_type.dart';
import '../turno_bitacora_helper.dart';
import 'niveles_fluido_colors.dart';

class NivelesFluidoPage extends ConsumerStatefulWidget {
  const NivelesFluidoPage({
    super.key,
    this.onContinuar,
    this.checklistType = ChecklistType.apertura,
  });

  final VoidCallback? onContinuar;
  final ChecklistType checklistType;

  @override
  ConsumerState<NivelesFluidoPage> createState() => _NivelesFluidoPageState();
}

class _NivelesFluidoPageState extends ConsumerState<NivelesFluidoPage> {
  bool _guardandoNiveles = false;

  @override
  void initState() {
    super.initState();
    if (widget.checklistType == ChecklistType.apertura ||
        widget.checklistType == ChecklistType.cierre) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(checklistProgressServiceProvider)
            .actualizarPaso(ChecklistAperturaPasos.nivelesFluido);
      });
    }
  }

  final Map<String, double> _niveles = {
    'gasolina': 0.5,
    'aceite': 0.5,
    'electrolito': 0.5,
    'anticongelante': 0.5,
    'liquido_frenos': 0.5,
  };

  void _updateNivel(String key, double value) {
    setState(() {
      _niveles[key] = value;
    });
  }

  Future<void> _continuar() async {
    final idBitacora =
        idBitacoraVehiculoParaChecklist(ref, widget.checklistType);
    if (idBitacora == null) {
      showAppAlertError(context, message: mensajeBitacoraFaltante(widget.checklistType));
      return;
    }

    setState(() => _guardandoNiveles = true);

    try {
      final request = RegistrarNivelesFluidosRequest.fromNivelesUi(
        idBitacoraVehiculo: idBitacora,
        nivelesUi: _niveles,
      );

      await ref.read(turnosServiceProvider).registrarNivelesFluidos(request);

      if (!mounted) return;
      setState(() => _guardandoNiveles = false);
      _navegarSiguiente();
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _guardandoNiveles = false);
      showAppAlertError(context, message: e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _guardandoNiveles = false);
      showAppAlertError(context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardandoNiveles = false);
      showAppAlertError(context, message: 'Error al registrar niveles de fluidos: $e');
    }
  }

  void _navegarSiguiente() {
    if (widget.onContinuar != null) {
      widget.onContinuar!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      backgroundColor: NivelesFluidoColors.background(context),
      appBar: AppBar(
        backgroundColor: NivelesFluidoColors.background(context),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const SizedBox.shrink(),
        leadingWidth: AppConstants.appBarLeadingWidthWithoutBack,
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Niveles de Fluido',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: NivelesFluidoColors.textPrimary(context),
                fontWeight: FontWeight.bold,
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
                  _buildProgress(context),
                  const SizedBox(height: 20),
                  _buildInstructions(context),
                  const SizedBox(height: 20),
                  _buildNivelesCard(context),
                ],
              ),
            ),
          ),
          _buildContinuarButton(context),
        ],
      ),
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
              'Paso 5 de 8',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NivelesFluidoColors.textSecondary(context),
                  ),
            ),
            Text(
              'Niveles de Fluido',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: NivelesFluidoColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 5 / 8,
            backgroundColor: NivelesFluidoColors.sliderInactive(context),
            valueColor: const AlwaysStoppedAnimation<Color>(NivelesFluidoColors.sliderActive),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Text(
      'Marca el nivel de porcentaje de cada nivel de fluido.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: NivelesFluidoColors.textSecondary(context),
          ),
    );
  }

  Widget _buildNivelesCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NivelesFluidoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _NivelSlider(
            icon: Icons.local_gas_station_outlined,
            label: 'Gasolina',
            value: _niveles['gasolina']!,
            onChanged: (v) => _updateNivel('gasolina', v),
          ),
          Divider(color: NivelesFluidoColors.divider(context), height: 24),
          _NivelSlider(
            icon: Icons.opacity_outlined,
            label: 'Aceite',
            value: _niveles['aceite']!,
            onChanged: (v) => _updateNivel('aceite', v),
          ),
          Divider(color: NivelesFluidoColors.divider(context), height: 24),
          _NivelSlider(
            icon: Icons.battery_charging_full_outlined,
            label: 'Electrólito',
            value: _niveles['electrolito']!,
            onChanged: (v) => _updateNivel('electrolito', v),
          ),
          Divider(color: NivelesFluidoColors.divider(context), height: 24),
          _NivelSlider(
            icon: Icons.ac_unit_outlined,
            label: 'Anticongelante',
            value: _niveles['anticongelante']!,
            onChanged: (v) => _updateNivel('anticongelante', v),
          ),
          Divider(color: NivelesFluidoColors.divider(context), height: 24),
          _NivelSlider(
            icon: Icons.warning_amber_outlined,
            label: 'Líquido de frenos',
            value: _niveles['liquido_frenos']!,
            onChanged: (v) => _updateNivel('liquido_frenos', v),
          ),
        ],
      ),
    );
  }

  Widget _buildContinuarButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _guardandoNiveles ? null : _continuar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF001C6A),
            foregroundColor: Colors.white,
            disabledBackgroundColor: NivelesFluidoColors.textSecondary(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _guardandoNiveles
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
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
    );
  }
}

class _NivelSlider extends StatelessWidget {
  const _NivelSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percentage = (value * 100).round();
    
    return Row(
      children: [
        Icon(
          icon,
          color: NivelesFluidoColors.textSecondary(context),
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NivelesFluidoColors.textPrimary(context),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  Text(
                    '$percentage%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: NivelesFluidoColors.textPrimary(context),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  activeTrackColor: NivelesFluidoColors.sliderActive,
                  inactiveTrackColor: NivelesFluidoColors.sliderInactive(context),
                  thumbColor: NivelesFluidoColors.sliderThumb,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayColor: NivelesFluidoColors.sliderActive.withValues(alpha: 0.2),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  min: 0,
                  max: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
