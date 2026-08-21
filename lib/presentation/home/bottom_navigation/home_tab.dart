import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/mi_turno_activo_response.dart';
import '../../controllers/auth_controller.dart';
import '../../turnos/mi_turno_provider.dart';

/// Azul de acción primario (mismo que botones del flujo de turnos).
const Color _kPrimaryAction = AppColors.accentBlue;

/// Azul de la etiqueta superior (eyebrow) en apariencia clara.
const Color _kEyebrowLight = Color(0xFF1B5FD9);

class HomeTab extends ConsumerWidget {
  const HomeTab({
    super.key,
    this.onComenzarTap,
    this.onOpenDrawer,
    this.onHistorialTap,
  });

  /// Al pulsar el botón principal, navega a Control de Turnos.
  final VoidCallback? onComenzarTap;

  /// Abre el menú lateral (mismo callback del shell).
  final VoidCallback? onOpenDrawer;

  /// Navega a Historial (misma acción del drawer / tab Historial).
  final VoidCallback? onHistorialTap;

  void _openDrawer(BuildContext context) {
    if (onOpenDrawer != null) {
      onOpenDrawer!();
      return;
    }
    Scaffold.maybeOf(context)?.openDrawer();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authControllerProvider).user;
    final miTurnoAsync = ref.watch(miTurnoActivoProvider);

    final rolNombre = user?.roleName?.trim();
    final displayName = (user?.name != null && user!.name.trim().isNotEmpty)
        ? user.name.trim()
        : (user?.email != null && user!.email.trim().isNotEmpty)
            ? user.email.trim()
            : 'Operador';

    final eyebrow = (rolNombre != null && rolNombre.isNotEmpty)
        ? rolNombre.toUpperCase()
        : 'OPERADOR';

    final secondaryText = _secondaryFromTurno(miTurnoAsync);

    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final headerFg = isDark ? Colors.white : AppColors.lightTextPrimary;
    final titleColor = isDark ? Colors.white : AppColors.accentBlue;
    final secondaryColor = theme.colorScheme.onSurfaceVariant;
    final eyebrowColor = isDark ? AppColors.infoIcon : _kEyebrowLight;
    final outlinedBorder = isDark
        ? AppColors.infoIcon.withValues(alpha: 0.55)
        : AppColors.accentBlue.withValues(alpha: 0.35);
    final outlinedFg = isDark ? AppColors.infoIcon : AppColors.accentBlue;
    final wash = isDark
        ? AppColors.accentBlue.withValues(alpha: 0.22)
        : AppColors.accentBlue.withValues(alpha: 0.10);

    return ColoredBox(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HomeHeader(
              foreground: headerFg,
              isDark: isDark,
              onMenuTap: () => _openDrawer(context),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo: la imagen llega hasta abajo del área (detrás del contenido).
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/home.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => ColoredBox(
                        color: isDark
                            ? AppColors.darkCardBackground
                            : const Color(0xFFD6E4F5),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(color: wash),
                    ),
                  ),
                  // Degradado encima de la imagen (no la recorta ni la desplaza).
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              bg.withValues(alpha: 0.35),
                              bg.withValues(alpha: 0.82),
                              bg,
                            ],
                            stops: const [0.0, 0.38, 0.55, 0.72, 0.88],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bienvenida + botones sobre el fondo ilustrado.
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            eyebrow,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: eyebrowColor,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Bienvenido,',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            displayName,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          if (secondaryText != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              secondaryText,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: secondaryColor,
                                height: 1.35,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: onComenzarTap,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimaryAction,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Comenzar',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: onHistorialTap,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: outlinedFg,
                                backgroundColor: isDark
                                    ? Colors.transparent
                                    : bg.withValues(alpha: 0.65),
                                side: BorderSide(
                                  color: outlinedBorder,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Ver mi historial',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: outlinedFg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _secondaryFromTurno(AsyncValue<MiTurnoActivoResponse> miTurnoAsync) {
    return miTurnoAsync.whenOrNull(
      data: (data) {
        if (data.turnoActivo) {
          final placa = data.vehiculo?.placas.trim();
          if (placa != null && placa.isNotEmpty) {
            return 'Turno activo · $placa';
          }
          return 'Turno activo';
        }
        return 'Sin turno activo';
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.foreground,
    required this.isDark,
    required this.onMenuTap,
  });

  final Color foreground;
  final bool isDark;
  final VoidCallback onMenuTap;

  @override
  Widget build(BuildContext context) {
    final logoAsset = isDark
        ? 'assets/images/logoHorizontall-02.webp'
        : 'assets/images/logoHorizontall-03.webp';

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.menu, color: foreground),
              onPressed: onMenuTap,
              tooltip: 'Menú',
            ),
            const SizedBox(width: 4),
            Image.asset(
              logoAsset,
              height: 36,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
