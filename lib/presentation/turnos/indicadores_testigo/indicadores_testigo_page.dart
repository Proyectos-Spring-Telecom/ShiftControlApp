import 'package:flutter/material.dart';

import '../models/checklist_type.dart';
import 'indicadores_testigo_colors.dart';

class IndicadoresTestigoPage extends StatefulWidget {
  const IndicadoresTestigoPage({
    super.key,
    this.onContinuar,
    this.checklistType = ChecklistType.apertura,
  });

  final VoidCallback? onContinuar;
  final ChecklistType checklistType;

  @override
  State<IndicadoresTestigoPage> createState() => _IndicadoresTestigoPageState();
}

class _IndicadoresTestigoPageState extends State<IndicadoresTestigoPage> {
  final Set<String> _selectedIndicators = {};

  final List<_IndicadorData> _indicadores = [
    _IndicadorData(id: 'abs', label: 'Frenos ABS', icon: Icons.album_outlined),
    _IndicadorData(id: 'aceite', label: 'Aceite', icon: Icons.opacity),
    _IndicadorData(id: 'bateria', label: 'Batería', icon: Icons.battery_alert),
    _IndicadorData(id: 'motor', label: 'Motor', icon: Icons.engineering),
    _IndicadorData(id: 'airbag', label: 'Airbag', icon: Icons.airline_seat_recline_normal),
    _IndicadorData(id: 'llantas', label: 'Llantas', icon: Icons.tire_repair),
    _IndicadorData(id: 'frenos', label: 'Frenos', icon: Icons.error_outline),
    _IndicadorData(id: 'temperatura', label: 'Temperatura', icon: Icons.thermostat),
    _IndicadorData(id: 'epc', label: 'Potencia', icon: Icons.bolt),
    _IndicadorData(id: 'cinturon', label: 'Cinturón', icon: Icons.airline_seat_legroom_reduced),
    _IndicadorData(id: 'luces', label: 'Luces', icon: Icons.lightbulb),
    _IndicadorData(id: 'direccion', label: 'Dirección', icon: Icons.directions_car),
  ];

  void _toggleIndicator(String id) {
    setState(() {
      if (_selectedIndicators.contains(id)) {
        _selectedIndicators.remove(id);
      } else {
        _selectedIndicators.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IndicadoresTestigoColors.background(context),
      appBar: AppBar(
        backgroundColor: IndicadoresTestigoColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: IndicadoresTestigoColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Indicadores',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: IndicadoresTestigoColors.textPrimary(context),
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
                  _buildIndicadoresGrid(context),
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
    final progressUnfilled = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF38384A)
        : const Color(0xFFE0E0E8);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Paso 4 de 8',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: IndicadoresTestigoColors.textSecondary(context),
                  ),
            ),
            Text(
              'Indicadores Testigo',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: IndicadoresTestigoColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 4 / 8,
            backgroundColor: progressUnfilled,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF681330)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: IndicadoresTestigoColors.textSecondary(context),
            ),
        children: const [
          TextSpan(text: 'Selecciona los iconos que veas '),
          TextSpan(
            text: 'activos',
            style: TextStyle(
              color: Color(0xFF681330),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: ' en tu tablero.'),
        ],
      ),
    );
  }

  Widget _buildIndicadoresGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _indicadores.length,
      itemBuilder: (context, index) {
        final indicador = _indicadores[index];
        final isSelected = _selectedIndicators.contains(indicador.id);
        return _IndicadorCard(
          indicador: indicador,
          isSelected: isSelected,
          onTap: () => _toggleIndicator(indicador.id),
        );
      },
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

class _IndicadorData {
  const _IndicadorData({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class _IndicadorCard extends StatelessWidget {
  const _IndicadorCard({
    required this.indicador,
    required this.isSelected,
    required this.onTap,
  });

  final _IndicadorData indicador;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected 
        ? IndicadoresTestigoColors.selectedBg(context) 
        : IndicadoresTestigoColors.indicatorInactiveBg(context);
    final iconColor = isSelected 
        ? IndicadoresTestigoColors.selectedIcon(context) 
        : IndicadoresTestigoColors.indicatorActive(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              indicador.icon,
              color: iconColor,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              indicador.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected 
                        ? IndicadoresTestigoColors.selectedIcon(context) 
                        : IndicadoresTestigoColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
