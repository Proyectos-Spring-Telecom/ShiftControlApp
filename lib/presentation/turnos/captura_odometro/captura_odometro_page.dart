import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/checklist_type.dart';
import 'captura_odometro_colors.dart';
import 'dashed_border_box.dart';
import '../registro_combustible/registro_combustible_page.dart';

class CapturaOdometroPage extends StatefulWidget {
  const CapturaOdometroPage({
    super.key,
    this.onSiguienteTap,
    this.checklistType = ChecklistType.apertura,
  });

  final VoidCallback? onSiguienteTap;
  final ChecklistType checklistType;

  @override
  State<CapturaOdometroPage> createState() => _CapturaOdometroPageState();
}

class _CapturaOdometroPageState extends State<CapturaOdometroPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _fotoTablero;

  Future<void> _tomarFotoTablero() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null && mounted) {
      final bytes = await photo.readAsBytes();
      if (mounted) setState(() => _fotoTablero = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isApertura = widget.checklistType == ChecklistType.apertura;
    final pageTitle = isApertura ? 'Apertura de Turno' : 'Cierre de Turno';
    
    return Scaffold(
      backgroundColor: CapturaOdometroColors.background(context),
      appBar: AppBar(
        backgroundColor: CapturaOdometroColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: CapturaOdometroColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            pageTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: CapturaOdometroColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
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
                  _buildVehicleCard(context),
                  const SizedBox(height: 24),
                  _buildFotoTablero(context, _fotoTablero, _tomarFotoTablero),
                  const SizedBox(height: 24),
                  _buildKilometraje(context),
                ],
              ),
            ),
          ),
          _buildSiguienteButton(context),
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
              'Paso 2 de 8',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CapturaOdometroColors.textSecondary(context),
                  ),
            ),
            Text(
              'Captura de Odómetro',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: CapturaOdometroColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 2 / 4,
            backgroundColor: CapturaOdometroColors.progressUnfilled(context),
            valueColor: const AlwaysStoppedAnimation<Color>(CapturaOdometroColors.progressFilled),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CapturaOdometroColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildT804Pill(context),
                const SizedBox(height: 8),
                Text(
                  'Nissan Versa 2022',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CapturaOdometroColors.textPrimary(context),
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Folio Operativo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CapturaOdometroColors.textSecondary(context),
                    ),
              ),
              const SizedBox(height: 6),
              _buildPill(context, 'OP-2024-892', CapturaOdometroColors.pillDarkGray(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildT804Pill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: CapturaOdometroColors.pillT804Background(context),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        'Placas: XJA-99-23',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: CapturaOdometroColors.pillT804Text(context),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildPill(BuildContext context, String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: CapturaOdometroColors.textPrimary(context),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildOcrActivoPill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      decoration: BoxDecoration(
        color: CapturaOdometroColors.ocrPillBackground(context),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: CapturaOdometroColors.ocrPillForeground(context),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'OCR Activo',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: CapturaOdometroColors.ocrPillForeground(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFotoTablero(BuildContext context, Uint8List? foto, VoidCallback onTap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CapturaOdometroColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Foto del tablero',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: CapturaOdometroColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          DashedBorderBox(
            height: 220,
            child: Material(
              color: CapturaOdometroColors.progressUnfilled(context),
              child: InkWell(
                onTap: onTap,
                child: foto != null
                    ? Image.memory(
                        foto,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              color: CapturaOdometroColors.photoIconLabel(context),
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Foto Tablero',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: CapturaOdometroColors.photoIconLabel(context),
                                  ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Asegúrate que los números sean legibles',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CapturaOdometroColors.textSecondary(context),
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKilometraje(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CapturaOdometroColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '2. Kilometraje detectado',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: CapturaOdometroColors.textPrimary(context),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              _buildOcrActivoPill(context),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: CapturaOdometroColors.background(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.speed, color: CapturaOdometroColors.textSecondary(context), size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '142.593',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: CapturaOdometroColors.textPrimary(context),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'km',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: CapturaOdometroColors.textSecondary(context),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: CapturaOdometroColors.textPrimary(context), size: 22),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiguienteButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (widget.onSiguienteTap != null) {
                widget.onSiguienteTap!();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RegistroCombustiblePage(),
                  ),
                );
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
                Text('Continuar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
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
