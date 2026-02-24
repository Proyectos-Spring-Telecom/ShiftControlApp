import 'package:flutter/material.dart';

import '../models/checklist_type.dart';
import 'accesorios_colors.dart';

class AccesoriosPage extends StatefulWidget {
  const AccesoriosPage({
    super.key,
    this.onContinuar,
    this.checklistType = ChecklistType.apertura,
  });

  final VoidCallback? onContinuar;
  final ChecklistType checklistType;

  @override
  State<AccesoriosPage> createState() => _AccesoriosPageState();
}

class _AccesoriosPageState extends State<AccesoriosPage> {
  final Map<String, bool> _accesoriosEstado = {
    'limpiadores': false,
    'aguas': true,
    'extintor': true,
    'triangulos': true,
    'radio': true,
    'tapetes': true,
    'gato': true,
    'herramientas': true,
    'llanta_refaccion': true,
    'impermeable': false,
  };

  void _toggleAccesorio(String key) {
    setState(() {
      _accesoriosEstado[key] = !_accesoriosEstado[key]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AccesoriosColors.background(context),
      appBar: AppBar(
        backgroundColor: AccesoriosColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AccesoriosColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Verificar Accesorios',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AccesoriosColors.textPrimary(context),
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
                  _buildInfoBox(context),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context),
                  const SizedBox(height: 12),
                  _buildAccesoriosList(context),
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
              'Paso 7 de 8',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AccesoriosColors.textSecondary(context),
                  ),
            ),
            Text(
              'Verificar Accesorios',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AccesoriosColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 7 / 8,
            backgroundColor: AccesoriosColors.switchTrackInactive(context),
            valueColor: const AlwaysStoppedAnimation<Color>(AccesoriosColors.switchActive),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AccesoriosColors.infoBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AccesoriosColors.infoIcon(context).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline,
              color: AccesoriosColors.infoIcon(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Confirme el estado de los accesorios. Desactive si falta o está dañado.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AccesoriosColors.textSecondary(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Text(
      'LISTA DE VERIFICACIÓN',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AccesoriosColors.sectionHeader(context),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
    );
  }

  Widget _buildAccesoriosList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AccesoriosColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _AccesorioItem(
            icon: Icons.check,
            label: 'Limpiadores',
            isActive: _accesoriosEstado['limpiadores']!,
            onToggle: () => _toggleAccesorio('limpiadores'),
            showDivider: true,
          ),
          _AccesorioItem(
            icon: Icons.water_drop_outlined,
            label: 'Aguas',
            isActive: _accesoriosEstado['aguas']!,
            onToggle: () => _toggleAccesorio('aguas'),
            showDivider: true,
          ),
          _AccesorioItem(
            icon: Icons.fire_extinguisher,
            label: 'Extintor',
            isActive: _accesoriosEstado['extintor']!,
            onToggle: () => _toggleAccesorio('extintor'),
            showDivider: true,
          ),
          _AccesorioItem(
            icon: Icons.warning_outlined,
            label: 'Triángulos',
            isActive: _accesoriosEstado['triangulos']!,
            onToggle: () => _toggleAccesorio('triangulos'),
            showDivider: true,
          ),
          _AccesorioItem(
            icon: Icons.radio,
            label: 'Radio',
            isActive: _accesoriosEstado['radio']!,
            onToggle: () => _toggleAccesorio('radio'),
            showDivider: true,
          ),
          _AccesorioItem(
            icon: Icons.grid_view_outlined,
            label: 'Tapetes',
            isActive: _accesoriosEstado['tapetes']!,
            onToggle: () => _toggleAccesorio('tapetes'),
            showDivider: true,
          ),
          _AccesorioItem(
            icon: Icons.settings_outlined,
            label: 'Gato',
            isActive: _accesoriosEstado['gato']!,
            onToggle: () => _toggleAccesorio('gato'),
            showDivider: true,
          ),
          _AccesorioItem(
            icon: Icons.build_outlined,
            label: 'Herramientas',
            isActive: _accesoriosEstado['herramientas']!,
            onToggle: () => _toggleAccesorio('herramientas'),
            showDivider: true,
          ),
          _AccesorioItem(
            icon: Icons.tire_repair_outlined,
            label: 'Llanta de refacción',
            isActive: _accesoriosEstado['llanta_refaccion']!,
            onToggle: () => _toggleAccesorio('llanta_refaccion'),
            showDivider: true,
          ),
          _AccesorioItem(
            icon: Icons.umbrella_outlined,
            label: 'Impermeable',
            isActive: _accesoriosEstado['impermeable']!,
            onToggle: () => _toggleAccesorio('impermeable'),
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

class _AccesorioItem extends StatelessWidget {
  const _AccesorioItem({
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
                color: AccesoriosColors.iconColor(context),
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AccesoriosColors.textPrimary(context),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Switch(
                value: isActive,
                onChanged: (_) => onToggle(),
                activeColor: Colors.white,
                activeTrackColor: AccesoriosColors.switchActive,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: AccesoriosColors.switchTrackInactive(context),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            color: AccesoriosColors.divider(context),
            height: 1,
            indent: 58,
            endIndent: 20,
          ),
      ],
    );
  }
}
