import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/auth_controller.dart';

/// Azul del botón "Comenzar" (mismo que botones Siguiente en flujo turnos).
const Color _kComenzarButton = Color(0xFF001C6A);

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key, this.onComenzarTap});

  /// Al pulsar "Comenzar", navega a la interfaz de Turnos (Control de Turnos).
  final VoidCallback? onComenzarTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final welcomeLabel = user?.name != null && user!.name.isNotEmpty
        ? 'Bienvenido, ${user.name}'
        : (user?.id != null ? 'Bienvenido, ${user!.id}' : 'Bienvenido, appi.1529');

    return Stack(
      fit: StackFit.expand,
      children: [
        // Imagen de fondo (con fallback si el asset no carga)
        Positioned.fill(
          child: Image.asset(
            'assets/images/bienvenida.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A1A2E),
            ),
          ),
        ),
        // Overlay oscuro para legibilidad
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        // Contenido inferior: logo, texto, botón
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Image.asset(
                    'assets/images/spring_logo.png',
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    welcomeLabel,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onComenzarTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kComenzarButton,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Comenzar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
