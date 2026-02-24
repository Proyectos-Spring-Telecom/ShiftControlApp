import 'package:flutter/material.dart';

import '../models/checklist_type.dart';
import 'luces_vehiculo_colors.dart';

class LucesVehiculoPage extends StatefulWidget {
  const LucesVehiculoPage({
    super.key,
    this.onContinuar,
    this.checklistType = ChecklistType.apertura,
  });

  final VoidCallback? onContinuar;
  final ChecklistType checklistType;

  @override
  State<LucesVehiculoPage> createState() => _LucesVehiculoPageState();
}

class _LucesVehiculoPageState extends State<LucesVehiculoPage> {
  final Map<String, bool> _lucesEstado = {
    'carretera': true,
    'cruce': true,
    'intermitentes_delanteras': true,
    'direccionales_delanteras': true,
    'intermitentes_laterales': false,
    'intermitentes_traseras': false,
    'direccionales_traseras': false,
    'reversa': false,
    'freno': false,
  };

  void _toggleLuz(String key) {
    setState(() {
      _lucesEstado[key] = !_lucesEstado[key]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LucesVehiculoColors.background(context),
      appBar: AppBar(
        backgroundColor: LucesVehiculoColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: LucesVehiculoColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Luces del Vehículo',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: LucesVehiculoColors.textPrimary(context),
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
                  _buildLucesCard(context),
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
              'Paso 6 de 8',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LucesVehiculoColors.textSecondary(context),
                  ),
            ),
            Text(
              'Luces del Vehículo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LucesVehiculoColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 6 / 8,
            backgroundColor: LucesVehiculoColors.switchTrackInactive(context),
            valueColor: const AlwaysStoppedAnimation<Color>(LucesVehiculoColors.switchActive),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Text(
      'Selecciona las luces que se encuentren en buen estado.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: LucesVehiculoColors.textSecondary(context),
          ),
    );
  }

  Widget _buildLucesCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LucesVehiculoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _LuzItem(
            icon: Icons.highlight,
            label: 'Carretera (Altas)',
            isActive: _lucesEstado['carretera']!,
            onToggle: () => _toggleLuz('carretera'),
            showDivider: true,
          ),
          _LuzItem(
            icon: Icons.lightbulb_outline,
            label: 'Cruce (Cortas)',
            isActive: _lucesEstado['cruce']!,
            onToggle: () => _toggleLuz('cruce'),
            showDivider: true,
          ),
          _LuzItem(
            icon: Icons.swap_horiz,
            label: 'Intermitentes delanteras',
            isActive: _lucesEstado['intermitentes_delanteras']!,
            onToggle: () => _toggleLuz('intermitentes_delanteras'),
            showDivider: true,
          ),
          _LuzItem(
            icon: Icons.turn_right,
            label: 'Direccionales delanteras',
            isActive: _lucesEstado['direccionales_delanteras']!,
            onToggle: () => _toggleLuz('direccionales_delanteras'),
            showDivider: true,
          ),
          _LuzItem(
            icon: Icons.warning_amber_outlined,
            label: 'Intermitentes laterales',
            isActive: _lucesEstado['intermitentes_laterales']!,
            onToggle: () => _toggleLuz('intermitentes_laterales'),
            showDivider: true,
          ),
          _LuzItem(
            icon: Icons.circle_outlined,
            label: 'Intermitentes traseras',
            isActive: _lucesEstado['intermitentes_traseras']!,
            onToggle: () => _toggleLuz('intermitentes_traseras'),
            showDivider: true,
          ),
          _LuzItem(
            icon: Icons.turn_left,
            label: 'Direccionales traseras',
            isActive: _lucesEstado['direccionales_traseras']!,
            onToggle: () => _toggleLuz('direccionales_traseras'),
            showDivider: true,
          ),
          _LuzItem(
            icon: Icons.chevron_left,
            label: 'Reversa',
            isActive: _lucesEstado['reversa']!,
            onToggle: () => _toggleLuz('reversa'),
            showDivider: true,
          ),
          _LuzItem(
            icon: Icons.pan_tool_outlined,
            label: 'Freno',
            isActive: _lucesEstado['freno']!,
            onToggle: () => _toggleLuz('freno'),
            showDivider: false,
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

class _LuzItem extends StatelessWidget {
  const _LuzItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onToggle,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onToggle;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: LucesVehiculoColors.iconColor(context),
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: LucesVehiculoColors.textPrimary(context),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (_) => onToggle(),
                activeColor: Colors.white,
                activeTrackColor: LucesVehiculoColors.switchTrackActive,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: LucesVehiculoColors.switchTrackInactive(context),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: LucesVehiculoColors.divider(context),
            height: 1,
            indent: 60,
            endIndent: 20,
          ),
      ],
    );
  }
}
