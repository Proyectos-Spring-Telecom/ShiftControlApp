import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../features/profile/models/update_nip_request.dart';
import '../../../features/profile/services/profile_service.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_alert_banner.dart';
import '../../widgets/loading_overlay.dart';
import 'profile_colors.dart';

class CrearNipPage extends ConsumerStatefulWidget {
  const CrearNipPage({super.key});

  @override
  ConsumerState<CrearNipPage> createState() => _CrearNipPageState();
}

class _CrearNipPageState extends ConsumerState<CrearNipPage> {
  final _formKey = GlobalKey<FormState>();
  final _nuevoNipController = TextEditingController();
  final _confirmarNipController = TextEditingController();

  bool _obscureNuevoNip = true;
  bool _obscureConfirmarNip = true;
  bool _isLoading = false;
  String? _errorNuevoNip;
  String? _errorConfirmarNip;

  @override
  void dispose() {
    _nuevoNipController.dispose();
    _confirmarNipController.dispose();
    super.dispose();
  }

  bool _tieneNumerosConsecutivos(String nip) {
    for (int i = 0; i < nip.length - 1; i++) {
      final current = int.parse(nip[i]);
      final next = int.parse(nip[i + 1]);
      if (next == current + 1 || next == current - 1) {
        return true;
      }
    }
    return false;
  }

  bool _tieneNumerosRepetidos(String nip) {
    for (int i = 0; i < nip.length - 1; i++) {
      if (nip[i] == nip[i + 1]) {
        return true;
      }
    }
    return false;
  }

  bool _tieneLongitudValida(String nip) => nip.length == 6 || nip.length == 8;

  int _calcularNivelSeguridad(String nip) {
    if (nip.isEmpty) return 0;

    int nivel = 0;
    
    // +1 si tiene al menos 4 dígitos (progreso inicial)
    if (nip.length >= 4) nivel++;
    
    // +1 si tiene longitud válida (6 u 8)
    if (_tieneLongitudValida(nip)) nivel++;
    
    // +1 si no tiene números consecutivos
    if (!_tieneNumerosConsecutivos(nip)) nivel++;
    
    // +1 si no tiene números repetidos
    if (!_tieneNumerosRepetidos(nip)) nivel++;

    return nivel;
  }

  String? _validarNip(String? value) {
    if (value == null || value.isEmpty) {
      return 'El NIP es requerido';
    }
    if (value.length != 6 && value.length != 8) {
      return 'El NIP debe tener 6 u 8 dígitos';
    }
    if (_tieneNumerosConsecutivos(value)) {
      return 'El NIP no puede tener números consecutivos';
    }
    if (_tieneNumerosRepetidos(value)) {
      return 'El NIP no puede tener números repetidos';
    }
    return null;
  }

  void _validarCampos() {
    setState(() {
      _errorNuevoNip = _validarNip(_nuevoNipController.text);
      
      if (_confirmarNipController.text.isEmpty) {
        _errorConfirmarNip = 'Confirma tu NIP';
      } else if (_confirmarNipController.text != _nuevoNipController.text) {
        _errorConfirmarNip = 'Los NIP no coinciden';
      } else {
        _errorConfirmarNip = null;
      }
    });
  }

  Future<void> _guardarNip() async {
    _validarCampos();

    if (_errorNuevoNip != null || _errorConfirmarNip != null) {
      showAppAlertBanner(
        context,
        type: AppAlertType.info,
        title: 'Revisa los datos',
        message: 'Completa correctamente los campos antes de continuar.',
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    // Enviar el valor de "Confirmar NIP" como pinHash (según especificación).
    final request = UpdateNipRequest(
      pinHash: _confirmarNipController.text.trim(),
    );

    try {
      final profileService = ref.read(profileServiceProvider);
      await profileService.updateUserNip(request);

      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppAlertBanner(
        context,
        type: AppAlertType.success,
        title: 'NIP configurado',
        message: 'Tu NIP fue configurado correctamente.',
        onDismissed: () => Navigator.of(context).pop(),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (e.code == '401') {
        showAppAlertBanner(
          context,
          type: AppAlertType.info,
          title: 'Sesión expirada',
          message: e.message,
          onDismissed: () => Navigator.of(context).pop(),
        );
      } else {
        showAppAlertBanner(
          context,
          type: AppAlertType.error,
          title: 'Error',
          message: e.message,
        );
      }
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppAlertBanner(
        context,
        type: AppAlertType.error,
        title: 'Error',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppAlertBanner(
        context,
        type: AppAlertType.error,
        title: 'Error',
        message: 'No se pudo guardar el NIP. Intenta de nuevo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: ProfileColors.background(context),
        appBar: AppBar(
        backgroundColor: ProfileColors.background(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: ProfileColors.textPrimary(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          'Crear NIP',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ProfileColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard(context),
              const SizedBox(height: 32),
              _buildNipSection(context),
              const SizedBox(height: 24),
              _buildSemaforoSeguridad(context),
              const SizedBox(height: 24),
              _buildRequisitos(context),
              const SizedBox(height: 32),
              _buildGuardarButton(context),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ProfileColors.cardBackground(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ProfileColors.buttonPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pin_outlined,
              color: ProfileColors.buttonPrimary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Crea un NIP de acceso',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: ProfileColors.textPrimary(context),
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Con tu NIP podrás iniciar sesión sin necesidad de las credenciales.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ProfileColors.textSecondary(context),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNipSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurar NIP',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ProfileColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'El NIP debe tener 6 u 8 dígitos. No se permiten números consecutivos ni repetidos.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ProfileColors.textSecondary(context),
              ),
        ),
        const SizedBox(height: 20),
        _buildNipInput(
          context,
          controller: _nuevoNipController,
          hint: 'Nuevo NIP',
          obscure: _obscureNuevoNip,
          onToggleObscure: () => setState(() => _obscureNuevoNip = !_obscureNuevoNip),
          error: _errorNuevoNip,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        _buildNipInput(
          context,
          controller: _confirmarNipController,
          hint: 'Confirmar NIP',
          obscure: _obscureConfirmarNip,
          onToggleObscure: () => setState(() => _obscureConfirmarNip = !_obscureConfirmarNip),
          error: _errorConfirmarNip,
        ),
      ],
    );
  }

  Widget _buildNipInput(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = error != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: ProfileColors.inputBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError ? ProfileColors.accentWine : ProfileColors.inputBorder(context),
              width: hasError ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  keyboardType: TextInputType.number,
                  maxLength: 8,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(
                    color: ProfileColors.textPrimary(context),
                    fontSize: 16,
                    letterSpacing: obscure ? 4 : 2,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: ProfileColors.textSecondary(context),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.transparent,
                    counterText: '',
                  ),
                  onChanged: (value) {
                    if (_errorNuevoNip != null || _errorConfirmarNip != null) {
                      _validarCampos();
                    }
                    onChanged?.call(value);
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ProfileColors.textSecondary(context),
                  size: 22,
                ),
                onPressed: onToggleObscure,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: ProfileColors.accentWine,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ProfileColors.accentWine,
                      ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSemaforoSeguridad(BuildContext context) {
    final nivel = _calcularNivelSeguridad(_nuevoNipController.text);
    final nip = _nuevoNipController.text;

    String nivelTexto;
    Color nivelColor;

    if (nip.isEmpty) {
      nivelTexto = 'Ingresa un NIP';
      nivelColor = ProfileColors.textSecondary(context);
    } else if (nivel <= 2) {
      nivelTexto = 'Seguridad baja';
      nivelColor = const Color(0xFFE53935);
    } else if (nivel <= 3) {
      nivelTexto = 'Seguridad media';
      nivelColor = const Color(0xFFFFA726);
    } else {
      nivelTexto = 'Seguridad alta';
      nivelColor = const Color(0xFF43A047);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nivel de seguridad',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ProfileColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSemaforoIndicador(
                  context,
                  color: const Color(0xFFE53935),
                  isActive: nip.isNotEmpty && nivel >= 1,
                  label: 'Baja',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSemaforoIndicador(
                  context,
                  color: const Color(0xFFFFA726),
                  isActive: nivel >= 3,
                  label: 'Media',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSemaforoIndicador(
                  context,
                  color: const Color(0xFF43A047),
                  isActive: nivel >= 4,
                  label: 'Alta',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                nip.isEmpty
                    ? Icons.security_outlined
                    : nivel <= 2
                        ? Icons.warning_amber_rounded
                        : nivel <= 3
                            ? Icons.shield_outlined
                            : Icons.verified_user_outlined,
                color: nivelColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                nivelTexto,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: nivelColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemaforoIndicador(
    BuildContext context, {
    required Color color,
    required bool isActive,
    required String label,
  }) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? color : color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive ? color : ProfileColors.textSecondary(context),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildRequisitos(BuildContext context) {
    final nip = _nuevoNipController.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ProfileColors.cardBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos del NIP',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: ProfileColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildRequisitoItem(
            context,
            texto: 'Debe tener 6 u 8 dígitos',
            cumplido: _tieneLongitudValida(nip),
            mostrarEstado: nip.isNotEmpty,
          ),
          _buildRequisitoItem(
            context,
            texto: 'Sin números consecutivos (ej. 123, 321)',
            cumplido: !_tieneNumerosConsecutivos(nip),
            mostrarEstado: nip.length >= 2,
          ),
          _buildRequisitoItem(
            context,
            texto: 'Sin números repetidos (ej. 112, 223)',
            cumplido: !_tieneNumerosRepetidos(nip),
            mostrarEstado: nip.length >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildRequisitoItem(
    BuildContext context, {
    required String texto,
    required bool cumplido,
    required bool mostrarEstado,
  }) {
    final Color iconColor;
    final IconData iconData;

    if (!mostrarEstado) {
      iconColor = ProfileColors.textSecondary(context);
      iconData = Icons.circle_outlined;
    } else if (cumplido) {
      iconColor = const Color(0xFF43A047);
      iconData = Icons.check_circle;
    } else {
      iconColor = const Color(0xFFE53935);
      iconData = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: mostrarEstado && cumplido
                        ? const Color(0xFF43A047)
                        : ProfileColors.textSecondary(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuardarButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _guardarNip,
        style: ElevatedButton.styleFrom(
          backgroundColor: ProfileColors.buttonPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              'Guardar NIP',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
