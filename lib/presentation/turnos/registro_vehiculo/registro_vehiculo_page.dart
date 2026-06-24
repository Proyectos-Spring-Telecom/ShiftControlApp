import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/models/registro_vehiculo_request.dart';
import '../../widgets/app_alert_banner.dart';
import '../identificar_placa/identificar_placa_page.dart';
import 'models/registro_vehiculo_form_data.dart';
import 'registro_vehiculo_colors.dart';
import 'registro_vehiculo_provider.dart';

/// Rango permitido para el selector de año del vehículo.
abstract final class RegistroVehiculoAnioPicker {
  RegistroVehiculoAnioPicker._();

  static const int minYear = 1980;

  static int get maxYear => DateTime.now().year + 1;

  static List<int> get availableYears {
    final years = <int>[];
    for (var year = maxYear; year >= minYear; year--) {
      years.add(year);
    }
    return years;
  }
}

/// Pantalla de registro de vehículo alineada al diseño ShiftControl existente.
class RegistroVehiculoPage extends ConsumerStatefulWidget {
  const RegistroVehiculoPage({super.key});

  @override
  ConsumerState<RegistroVehiculoPage> createState() => _RegistroVehiculoPageState();
}

class _RegistroVehiculoPageState extends ConsumerState<RegistroVehiculoPage> {
  late final TextEditingController _numeroPlacaController;
  late final TextEditingController _marcaController;
  late final TextEditingController _modeloController;
  late final TextEditingController _anioController;
  late final TextEditingController _colorController;
  late final TextEditingController _numeroEconomicoController;

  bool _guardando = false;
  bool _capturandoPlaca = false;

  bool get _puedeGuardar {
    if (_guardando || _capturandoPlaca) return false;
    if (_numeroPlacaController.text.trim().isEmpty) return false;
    if (_marcaController.text.trim().isEmpty) return false;
    if (_modeloController.text.trim().isEmpty) return false;
    if (_anioController.text.trim().length != 4) return false;
    if (_colorController.text.trim().isEmpty) return false;
    if (_numeroEconomicoController.text.trim().isEmpty) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _numeroPlacaController = TextEditingController();
    _marcaController = TextEditingController();
    _modeloController = TextEditingController();
    _anioController = TextEditingController();
    _colorController = TextEditingController();
    _numeroEconomicoController = TextEditingController();

    for (final c in [
      _numeroPlacaController,
      _marcaController,
      _modeloController,
      _anioController,
      _colorController,
      _numeroEconomicoController,
    ]) {
      c.addListener(_onFormChanged);
    }
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [
      _numeroPlacaController,
      _marcaController,
      _modeloController,
      _anioController,
      _colorController,
      _numeroEconomicoController,
    ]) {
      c.removeListener(_onFormChanged);
      c.dispose();
    }
    super.dispose();
  }

  RegistroVehiculoFormData _construirFormData() {
    return RegistroVehiculoFormData(
      numeroPlaca: _numeroPlacaController.text.trim(),
      marca: _marcaController.text.trim(),
      modelo: _modeloController.text.trim(),
      anio: _anioController.text.trim(),
      color: _colorController.text.trim(),
      numeroEconomico: _numeroEconomicoController.text.trim(),
    );
  }

  RegistroVehiculoRequest _construirRequest(RegistroVehiculoFormData data) {
    return RegistroVehiculoRequest(
      numeroPlaca: data.numeroPlaca,
      marca: data.marca,
      modelo: data.modelo,
      anio: int.parse(data.anio),
      color: data.color,
      numeroEconomico: data.numeroEconomico,
    );
  }

  Future<void> _capturarPlaca() async {
    if (_guardando || _capturandoPlaca) return;

    setState(() => _capturandoPlaca = true);

    final plate = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (ctx) => IdentificarPlacaPage(
          onPlacaIdentificada: (plateNumber, {Uint8List? imageBytes}) {
            Navigator.of(ctx).pop(plateNumber.trim());
          },
          onRegresar: () => Navigator.of(ctx).pop(),
        ),
      ),
    );

    if (!mounted) return;
    setState(() => _capturandoPlaca = false);

    if (plate != null && plate.isNotEmpty) {
      _numeroPlacaController.text = plate.toUpperCase();
      return;
    }

    if (plate != null && plate.isEmpty) {
      showAppAlertError(
        context,
        message: 'No se pudo detectar una placa. Intente nuevamente.',
      );
    }
  }

  Future<void> _seleccionarAnio() async {
    if (_guardando || _capturandoPlaca) return;

    final parsedYear = int.tryParse(_anioController.text.trim());
    final initialYear = (parsedYear != null &&
            parsedYear >= RegistroVehiculoAnioPicker.minYear &&
            parsedYear <= RegistroVehiculoAnioPicker.maxYear)
        ? parsedYear
        : null;

    final selectedYear = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RegistroVehiculoAnioPickerSheet(
        years: RegistroVehiculoAnioPicker.availableYears,
        selectedYear: initialYear,
      ),
    );

    if (!mounted || selectedYear == null) return;

    _anioController.text = selectedYear.toString();
  }

  Future<void> _guardarRegistro() async {
    if (!_puedeGuardar) {
      showAppAlertError(
        context,
        message: 'Completa número de placa, marca y modelo, año, color y número económico.',
      );
      return;
    }

    final formData = _construirFormData();
    final request = _construirRequest(formData);

    setState(() => _guardando = true);

    try {
      await ref.read(registroVehiculoRepositoryProvider).registrar(request: request);

      if (!mounted) return;
      setState(() => _guardando = false);
      ref.read(registroVehiculoEnviadoProvider.notifier).state = formData;
      showAppAlertSuccess(context, message: 'Vehículo registrado correctamente');
      Navigator.of(context).pop(formData);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showAppAlertError(context, message: e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showAppAlertError(context, message: e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      showAppAlertError(
        context,
        message: 'No fue posible registrar el vehículo.\nIntenta nuevamente.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegistroVehiculoColors.background(context),
      appBar: AppBar(
        backgroundColor: RegistroVehiculoColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: RegistroVehiculoColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Registro de Vehículo',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: RegistroVehiculoColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
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
                  _buildInfoBox(context),
                  const SizedBox(height: 16),
                  _buildSectionLabel(context, 'Datos del vehículo'),
                  const SizedBox(height: 8),
                  _buildDatosVehiculoCard(context),
                ],
              ),
            ),
          ),
          _buildGuardarButton(context),
        ],
      ),
    );
  }

  Widget _buildInfoBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RegistroVehiculoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RegistroVehiculoColors.outline(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RegistroVehiculoColors.infoIcon(context).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_car_outlined,
              color: RegistroVehiculoColors.infoIcon(context),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Ingresa los datos de identificación del vehículo para completar el registro.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: RegistroVehiculoColors.textSecondary(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: RegistroVehiculoColors.textSecondary(context),
      ),
    );
  }

  Widget _buildDatosVehiculoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RegistroVehiculoColors.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RegistroVehiculoColors.outline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlacaField(context),
          const SizedBox(height: 8),
          _buildTextField(
            context,
            label: 'Marca',
            controller: _marcaController,
            leadingIcon: Icons.label_outlined,
            hint: 'Ej: Ford',
          ),
          const SizedBox(height: 8),
          _buildTextField(
            context,
            label: 'Modelo',
            controller: _modeloController,
            leadingIcon: Icons.directions_car_outlined,
            hint: 'Ej: Transit',
          ),
          const SizedBox(height: 8),
          _buildAnioField(context),
          const SizedBox(height: 8),
          _buildTextField(
            context,
            label: 'Color',
            controller: _colorController,
            leadingIcon: Icons.palette_outlined,
            hint: 'Ej: Blanco',
          ),
          const SizedBox(height: 8),
          _buildTextField(
            context,
            label: 'Número económico',
            controller: _numeroEconomicoController,
            leadingIcon: Icons.tag_outlined,
            hint: 'Ej: T804',
          ),
        ],
      ),
    );
  }

  Widget _buildPlacaField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          context,
          label: 'Número de placa',
          controller: _numeroPlacaController,
          leadingIcon: Icons.pin_outlined,
          hint: 'Ej: ABC-123-D',
          textCapitalization: TextCapitalization.characters,
          trailing: _FieldActionIconButton(
            icon: Icons.camera_alt_outlined,
            tooltip: 'Capturar placa',
            isLoading: _capturandoPlaca,
            onPressed: (_guardando || _capturandoPlaca) ? null : _capturarPlaca,
          ),
        ),
        const SizedBox(height: 8),
        _SecondaryFormButton(
          label: _capturandoPlaca ? 'Capturando...' : 'Capturar placa',
          icon: Icons.camera_alt_outlined,
          isLoading: _capturandoPlaca,
          onPressed: (_guardando || _capturandoPlaca) ? null : _capturarPlaca,
        ),
      ],
    );
  }

  Widget _buildAnioField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Año',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RegistroVehiculoColors.textPrimary(context),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: RegistroVehiculoColors.inputBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RegistroVehiculoColors.outline(context)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: RegistroVehiculoColors.textSecondary(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _anioController,
                  readOnly: true,
                  onTap: _seleccionarAnio,
                  enabled: !_guardando && !_capturandoPlaca,
                  style: TextStyle(color: RegistroVehiculoColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: 'Ej: 2024',
                    hintStyle: TextStyle(color: RegistroVehiculoColors.textSecondary(context)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                    filled: true,
                    fillColor: RegistroVehiculoColors.inputBackground(context),
                  ),
                ),
              ),
              _FieldActionIconButton(
                icon: Icons.calendar_today_outlined,
                tooltip: 'Seleccionar año',
                onPressed: (_guardando || _capturandoPlaca) ? null : _seleccionarAnio,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required IconData leadingIcon,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: RegistroVehiculoColors.textPrimary(context),
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: RegistroVehiculoColors.inputBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RegistroVehiculoColors.outline(context)),
          ),
          child: Row(
            children: [
              Icon(
                leadingIcon,
                size: 20,
                color: RegistroVehiculoColors.textSecondary(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: !_guardando && !_capturandoPlaca,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  textCapitalization: textCapitalization,
                  style: TextStyle(color: RegistroVehiculoColors.textPrimary(context)),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: RegistroVehiculoColors.textSecondary(context)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                    filled: true,
                    fillColor: RegistroVehiculoColors.inputBackground(context),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuardarButton(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _puedeGuardar ? _guardarRegistro : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: RegistroVehiculoColors.buttonPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: RegistroVehiculoColors.textSecondary(context),
              disabledForegroundColor: Colors.white70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _guardando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Guardar vehículo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _FieldActionIconButton extends StatelessWidget {
  const _FieldActionIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: RegistroVehiculoColors.textSecondary(context),
              ),
            )
          : Icon(
              icon,
              color: onPressed == null
                  ? RegistroVehiculoColors.textSecondary(context)
                  : RegistroVehiculoColors.progressFilled,
            ),
    );
  }
}

class _RegistroVehiculoAnioPickerSheet extends StatefulWidget {
  const _RegistroVehiculoAnioPickerSheet({
    required this.years,
    this.selectedYear,
  });

  final List<int> years;
  final int? selectedYear;

  @override
  State<_RegistroVehiculoAnioPickerSheet> createState() =>
      _RegistroVehiculoAnioPickerSheetState();
}

class _RegistroVehiculoAnioPickerSheetState extends State<_RegistroVehiculoAnioPickerSheet> {
  static const double _itemExtent = 56;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    final selectedYear = widget.selectedYear;
    if (selectedYear != null) {
      final index = widget.years.indexOf(selectedYear);
      if (index >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scrollController.hasClients) return;
          _scrollController.jumpTo(index * _itemExtent);
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: RegistroVehiculoColors.cardBackground(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: RegistroVehiculoColors.outline(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Año',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: RegistroVehiculoColors.textPrimary(context),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  itemExtent: _itemExtent,
                  itemCount: widget.years.length,
                  itemBuilder: (context, index) {
                    final year = widget.years[index];
                    final isSelected = year == widget.selectedYear;

                    return InkWell(
                      onTap: () => Navigator.of(context).pop(year),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                year.toString(),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: isSelected
                                          ? RegistroVehiculoColors.progressFilled
                                          : RegistroVehiculoColors.textPrimary(context),
                                      fontWeight:
                                          isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check,
                                size: 20,
                                color: RegistroVehiculoColors.progressFilled,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryFormButton extends StatelessWidget {
  const _SecondaryFormButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: RegistroVehiculoColors.textSecondary(context),
                ),
              )
            : Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: RegistroVehiculoColors.background(context),
          foregroundColor: RegistroVehiculoColors.textPrimary(context),
          disabledBackgroundColor: RegistroVehiculoColors.background(context),
          disabledForegroundColor: RegistroVehiculoColors.textSecondary(context),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: RegistroVehiculoColors.textSecondary(context).withValues(alpha: 0.25),
            ),
          ),
        ),
      ),
    );
  }
}
