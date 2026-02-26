import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/validators.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/app_alert_banner.dart';
import 'login_colors.dart';

class RecuperarContrasenaPage extends ConsumerStatefulWidget {
  const RecuperarContrasenaPage({super.key});

  @override
  ConsumerState<RecuperarContrasenaPage> createState() => _RecuperarContrasenaPageState();
}

class _RecuperarContrasenaPageState extends ConsumerState<RecuperarContrasenaPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _enviarInstrucciones() async {
    debugPrint('[RecuperarContrasenaPage] Enviar pulsado');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[RecuperarContrasenaPage] Validación fallida, no se envía');
      return;
    }

    final userName = _emailController.text.trim();
    debugPrint('[RecuperarContrasenaPage] Enviando recuperarAcceso userName=$userName');

    setState(() => _isLoading = true);

    await ref.read(authControllerProvider.notifier).recuperarAcceso(
          context: context,
          userName: userName,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      debugPrint('[RecuperarContrasenaPage] Flujo Enviar finalizado (mounted=$mounted)');
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
                          'Introduce tu correo electrónico para buscar tu cuenta.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: LoginColors.placeholder(context),
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '¡Te enviaremos las instrucciones a tu correo electrónico!',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: LoginColors.textPrimary(context),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildEmailField(context),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _enviarInstrucciones,
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
                              : const Text('Enviar'),
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
                            onTap: () => Navigator.of(context).pop(),
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

  Widget _buildEmailField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correo Electrónico:',
          style: TextStyle(
            color: LoginColors.textPrimary(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          style: TextStyle(color: LoginColors.textPrimary(context)),
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'Ingresa tu correo electrónico',
            hintStyle: TextStyle(color: LoginColors.placeholder(context)),
            filled: true,
            fillColor: LoginColors.inputBackground(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: LoginColors.focusBorder(context), width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          validator: Validators.email,
        ),
      ],
    );
  }
}
