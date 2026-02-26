import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/auth_controller.dart';
import '../../widgets/app_alert_banner.dart';
import 'login_colors.dart';

// ! Ruta pública accesible desde navegador (#/nueva-contrasena?token=...)
// ? Token desde URL (Uri.base.fragment) o pasado por el router.

class NuevaContrasenaPage extends ConsumerStatefulWidget {
  const NuevaContrasenaPage({super.key, this.token});

  /// Token pasado por el router (p. ej. desde name="/nueva-contrasena?token=...").
  final String? token;

  @override
  ConsumerState<NuevaContrasenaPage> createState() => _NuevaContrasenaPageState();
}

class _NuevaContrasenaPageState extends ConsumerState<NuevaContrasenaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nuevaContrasenaController = TextEditingController();
  final _confirmarContrasenaController = TextEditingController();

  bool _obscureNueva = true;
  bool _obscureConfirmar = true;
  bool _isLoading = false;

  String? _errorNueva;
  String? _errorConfirmar;

  /// Token extraído de la URL (hash routing: fragment contiene /nueva-contrasena?token=...).
  late final String? _token;

  /// Lee el token desde el fragment con hash routing (#/nueva-contrasena?token=...).
  String? _getTokenFromUrl() {
    final uri = Uri.base;
    if (uri.fragment.isEmpty) return null;

    final fragment = uri.fragment;
    // Ejemplo: "/nueva-contrasena?token=123456"
    final fragmentUri = Uri.parse(fragment);
    return fragmentUri.queryParameters['token'];
  }

  /// Muestra banner de error cuando no hay token. No navega.
  void _mostrarErrorToken() {
    if (!mounted) return;
    showAppAlertBanner(
      context,
      type: AppAlertType.info,
      title: 'Token requerido',
      message: 'Token inválido o no proporcionado.',
    );
  }

  @override
  void initState() {
    super.initState();
    _token = widget.token ?? _getTokenFromUrl();

    debugPrint('[NuevaContrasenaPage] Interfaz: NuevaContrasenaPage (restaurar contraseña)');
    final tokenPreview = _token != null && _token!.length > 12
        ? '${_token!.substring(0, 8)}...'
        : (_token != null ? 'ok' : 'null');
    debugPrint('[NuevaContrasenaPage] Token recibido: $tokenPreview');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_token == null || _token!.isEmpty) {
        _mostrarErrorToken();
      }
    });
  }

  @override
  void dispose() {
    _nuevaContrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }

  bool _tieneMayuscula(String value) => value.contains(RegExp(r'[A-Z]'));
  bool _tieneMinuscula(String value) => value.contains(RegExp(r'[a-z]'));
  bool _tieneNumero(String value) => value.contains(RegExp(r'[0-9]'));
  bool _tieneCaracterEspecial(String value) => value.contains(RegExp(r'[#?!@$%^&*\-_+=(){}[\]|\\:;"<>,./]'));
  bool _tieneLongitudValida(String value) => value.length > 6 && value.length < 16;

  int _calcularNivelSeguridad(String value) {
    if (value.isEmpty) return 0;

    int nivel = 0;
    if (_tieneMayuscula(value)) nivel++;
    if (_tieneMinuscula(value)) nivel++;
    if (_tieneNumero(value)) nivel++;
    if (_tieneCaracterEspecial(value)) nivel++;
    if (_tieneLongitudValida(value)) nivel++;

    return nivel;
  }

  String? _validarNuevaContrasena(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (!_tieneLongitudValida(value)) {
      return 'La contraseña debe tener entre 7 y 15 caracteres';
    }
    if (!_tieneMayuscula(value)) {
      return 'Debe tener al menos una mayúscula';
    }
    if (!_tieneMinuscula(value)) {
      return 'Debe tener al menos una minúscula';
    }
    if (!_tieneNumero(value)) {
      return 'Debe tener al menos un número';
    }
    if (!_tieneCaracterEspecial(value)) {
      return 'Debe tener al menos un carácter especial (#?!&)';
    }
    return null;
  }

  void _validarCampos() {
    setState(() {
      _errorNueva = _validarNuevaContrasena(_nuevaContrasenaController.text);

      if (_confirmarContrasenaController.text.isEmpty) {
        _errorConfirmar = 'Confirma tu nueva contraseña';
      } else if (_confirmarContrasenaController.text != _nuevaContrasenaController.text) {
        _errorConfirmar = 'Las contraseñas no coinciden';
      } else {
        _errorConfirmar = null;
      }
    });
  }

  Future<void> _guardarContrasena() async {
    _validarCampos();

    if (_errorNueva != null || _errorConfirmar != null) return;

    final token = _token;
    if (token == null || token.isEmpty) {
      _mostrarErrorToken();
      return;
    }

    setState(() => _isLoading = true);

    await ref.read(authControllerProvider.notifier).cambiarContrasenaDesdeRecuperacion(
          context: context,
          token: token,
          passwordNueva: _nuevaContrasenaController.text.trim(),
          passwordConfirmacion: _confirmarContrasenaController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 48),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/images/spring_logo.png',
                          height: 80,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 60),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recuperar Contraseña',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: LoginColors.textPrimary(context),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recuerda que tu contraseña será la misma para ingresar a nuestra aplicación.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: LoginColors.placeholder(context),
                              ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildPasswordField(
                        context,
                        controller: _nuevaContrasenaController,
                        label: 'Nueva Contraseña:',
                        hint: 'Ingresa tu nueva contraseña',
                        obscure: _obscureNueva,
                        onToggleObscure: () => setState(() => _obscureNueva = !_obscureNueva),
                        error: _errorNueva,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordField(
                        context,
                        controller: _confirmarContrasenaController,
                        label: 'Confirmar Contraseña:',
                        hint: 'Confirma tu nueva contraseña',
                        obscure: _obscureConfirmar,
                        onToggleObscure: () => setState(() => _obscureConfirmar = !_obscureConfirmar),
                        error: _errorConfirmar,
                      ),
                      const SizedBox(height: 24),
                      _buildSemaforoSeguridad(context),
                      const SizedBox(height: 24),
                      _buildRequisitos(context),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _guardarContrasena,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LoginColors.button,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: LoginColors.button.withValues(alpha: 0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Guardar Contraseña'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '¿La recuerdas? ',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: LoginColors.placeholder(context),
                                ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                            child: Text(
                              'Iniciar Sesión',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: LoginColors.button,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Text(
                'Al iniciar aceptas nuestros Términos y Condiciones y Política de Privacidad.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: LoginColors.textPrimary(context).withValues(alpha: 0.85),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
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
        Text(
          label,
          style: TextStyle(
            color: LoginColors.textPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: LoginColors.textPrimary(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: LoginColors.placeholder(context)),
            filled: true,
            fillColor: LoginColors.inputBackground(context),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: LoginColors.placeholder(context),
              ),
              onPressed: onToggleObscure,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasError
                  ? const BorderSide(color: Colors.redAccent, width: 2)
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? Colors.redAccent : LoginColors.focusBorder(context),
                width: 1,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          onChanged: (value) {
            if (_errorNueva != null || _errorConfirmar != null) {
              _validarCampos();
            }
            onChanged?.call(value);
          },
        ),
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  error,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.redAccent,
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
    final nivel = _calcularNivelSeguridad(_nuevaContrasenaController.text);
    final password = _nuevaContrasenaController.text;

    String nivelTexto;
    Color nivelColor;

    if (password.isEmpty) {
      nivelTexto = 'Ingresa una contraseña';
      nivelColor = LoginColors.placeholder(context);
    } else if (nivel <= 2) {
      nivelTexto = 'Seguridad baja';
      nivelColor = const Color(0xFFE53935);
    } else if (nivel <= 4) {
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
        color: LoginColors.inputBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nivel de seguridad',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: LoginColors.textPrimary(context),
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
                  isActive: password.isNotEmpty && nivel >= 1,
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
                  isActive: nivel >= 5,
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
                password.isEmpty
                    ? Icons.security_outlined
                    : nivel <= 2
                        ? Icons.warning_amber_rounded
                        : nivel <= 4
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
                color: isActive ? color : LoginColors.placeholder(context),
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildRequisitos(BuildContext context) {
    final password = _nuevaContrasenaController.text;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LoginColors.inputBackground(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos de la contraseña',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: LoginColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          _buildRequisitoItem(
            context,
            texto: 'Entre 7 y 15 caracteres',
            cumplido: _tieneLongitudValida(password),
            mostrarEstado: password.isNotEmpty,
          ),
          _buildRequisitoItem(
            context,
            texto: 'Al menos una mayúscula (A-Z)',
            cumplido: _tieneMayuscula(password),
            mostrarEstado: password.isNotEmpty,
          ),
          _buildRequisitoItem(
            context,
            texto: 'Al menos una minúscula (a-z)',
            cumplido: _tieneMinuscula(password),
            mostrarEstado: password.isNotEmpty,
          ),
          _buildRequisitoItem(
            context,
            texto: 'Al menos un número (0-9)',
            cumplido: _tieneNumero(password),
            mostrarEstado: password.isNotEmpty,
          ),
          _buildRequisitoItem(
            context,
            texto: 'Al menos un carácter especial (#?!&)',
            cumplido: _tieneCaracterEspecial(password),
            mostrarEstado: password.isNotEmpty,
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
      iconColor = LoginColors.placeholder(context);
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
                        : LoginColors.placeholder(context),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
