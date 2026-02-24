import 'package:flutter/material.dart';

import '../models/checklist_type.dart';
import 'niveles_fluido_colors.dart';

class NivelesFluidoPage extends StatefulWidget {
  const NivelesFluidoPage({
    super.key,
    this.onContinuar,
    this.checklistType = ChecklistType.apertura,
  });

  final VoidCallback? onContinuar;
  final ChecklistType checklistType;

  @override
  State<NivelesFluidoPage> createState() => _NivelesFluidoPageState();
}

class _NivelesFluidoPageState extends State<NivelesFluidoPage> {
  final Map<String, double> _niveles = {
    'gasolina': 1.0,
    'aceite': 0.65,
    'electrolito': 0.35,
    'anticongelante': 0.75,
    'liquido_frenos': 0.95,
  };

  void _updateNivel(String key, double value) {
    setState(() {
      _niveles[key] = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NivelesFluidoColors.background(context),
      appBar: AppBar(
        backgroundColor: NivelesFluidoColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: NivelesFluidoColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
                  _buildNivelesCard(context),
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
          onPressed: () {
            if (widget.onContinuar != null) {
              widget.onContinuar!();
            } else {
              Navigator.of(context).pop();
            }
          },
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
