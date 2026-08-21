import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/route_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../auth/profile/profile_page.dart';
import '../../settings/appearance_page.dart';
import '../../turnos/control_turnos_page.dart';
import '../../turnos/historial_turnos/historial_turnos_page.dart';
import '../../turnos/mi_turno_provider.dart';
import '../../turnos/registro_vehiculo/registro_vehiculo_page.dart';
import '../../afiliar_rostro/afiliar_rostro_page.dart';

/// Fondo del encabezado del drawer (navy de la referencia visual).
const Color _kDrawerHeaderBg = Color(0xFF12224A);

/// Azul del avatar sin foto (referencia clara).
const Color _kDrawerAvatarBg = Color(0xFF3F9BEE);
class AppDrawer extends ConsumerWidget {
  const AppDrawer({
    super.key,
    this.onControlTurnosTap,
    this.onHistorialTap,
    this.onProfileTap,
  });

  /// Si se proporciona, se usa en lugar de navegar por ruta (ej. desde MainShell).
  final VoidCallback? onControlTurnosTap;
  final VoidCallback? onHistorialTap;
  final VoidCallback? onProfileTap;

  double _drawerWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 900) {
      return math.min(360.0, width * 0.32);
    }
    if (width >= 600) {
      return math.min(340.0, width * 0.42);
    }
    return (width * 0.82).clamp(260.0, 360.0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final user = ref.watch(authControllerProvider).user;
    final name = user?.name;
    final email = user?.email;
    final fotoPerfilUrl = user?.fotoPerfil;
    final fallbackInitial = (name != null && name.isNotEmpty)
        ? name.substring(0, 1).toUpperCase()
        : (email != null && email.isNotEmpty
            ? email.substring(0, 1).toUpperCase()
            : '?');

    final miTurnoAsync = ref.watch(miTurnoActivoProvider);
    final themePreference = ref.watch(themeModePreferenceProvider);

    final surface = isDark
        ? AppColors.darkBackground
        : AppColors.lightCardBackground;
    final dividerColor = AppColors.divider(context);
    final itemColor = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final selectedBg = isDark
        ? AppColors.accentBlue.withValues(alpha: 0.35)
        : AppColors.accentBlue.withValues(alpha: 0.08);
    final selectedFg = isDark ? AppColors.infoIcon : AppColors.accentBlue;

    return Drawer(
      width: _drawerWidth(context),
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DrawerUserHeader(
              displayName: user?.name ?? 'Usuario',
              email: user?.email,
              fotoPerfilUrl: fotoPerfilUrl,
              fallbackInitial: fallbackInitial,
              turnoActivo: miTurnoAsync.whenOrNull(
                data: (data) => data.turnoActivo,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                children: [
                  _SectionLabel('OPERACIÓN'),
                  const SizedBox(height: 4),
                  _DrawerMenuItem(
                    icon: Icons.schedule,
                    label: 'Control de Turnos',
                    foreground: itemColor,
                    selectedForeground: selectedFg,
                    selectedBackground: selectedBg,
                    onTap: () {
                      if (onControlTurnosTap != null) {
                        onControlTurnosTap!();
                      } else {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ControlTurnosPage(
                              onBack: () => Navigator.of(context).pop(),
                              onOpenDrawer: null,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.history,
                    label: 'Historial',
                    foreground: itemColor,
                    selectedForeground: selectedFg,
                    selectedBackground: selectedBg,
                    onTap: () {
                      if (onHistorialTap != null) {
                        onHistorialTap!();
                      } else {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HistorialTurnosPage(),
                          ),
                        );
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.directions_car_outlined,
                    label: 'Registro de Vehículo',
                    foreground: itemColor,
                    selectedForeground: selectedFg,
                    selectedBackground: selectedBg,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const RegistroVehiculoPage(),
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: dividerColor),
                  ),
                  _SectionLabel('CUENTA'),
                  const SizedBox(height: 4),
                  _DrawerMenuItem(
                    icon: Icons.person_outline,
                    label: 'Perfil',
                    foreground: itemColor,
                    selectedForeground: selectedFg,
                    selectedBackground: selectedBg,
                    onTap: () {
                      if (onProfileTap != null) {
                        onProfileTap!();
                      } else {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.face_outlined,
                    label: 'Afiliar Rostro',
                    foreground: itemColor,
                    selectedForeground: selectedFg,
                    selectedBackground: selectedBg,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AfiliarRostroPage(),
                        ),
                      );
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.palette_outlined,
                    label: 'Apariencia',
                    foreground: itemColor,
                    selectedForeground: selectedFg,
                    selectedBackground: selectedBg,
                    trailing: _AppearanceChip(
                      preference: themePreference,
                      isDark: isDark,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          showAppearanceBottomSheet(context);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Divider(height: 1, color: dividerColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: _DrawerMenuItem(
                icon: Icons.logout,
                label: 'Cerrar sesión',
                foreground: AppColors.accent,
                selectedForeground: AppColors.accent,
                selectedBackground: selectedBg,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      RouteConstants.login,
                      (_) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerUserHeader extends StatelessWidget {
  const _DrawerUserHeader({
    required this.displayName,
    required this.fallbackInitial,
    this.email,
    this.fotoPerfilUrl,
    this.turnoActivo,
  });

  final String displayName;
  final String? email;
  final String? fotoPerfilUrl;
  final String fallbackInitial;
  final bool? turnoActivo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Navy de la referencia (#12224A), no accentBlue del tema.
    const headerBg = _kDrawerHeaderBg;
    const nameColor = Colors.white;
    final emailColor = Colors.white.withValues(alpha: 0.72);

    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 20),
      decoration: const BoxDecoration(color: headerBg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _UserAvatar(
                fotoPerfilUrl: fotoPerfilUrl,
                fallbackInitial: fallbackInitial,
              ),
              const Spacer(),
              Image.asset(
                'assets/images/logoHorizontall-02.webp',
                height: 28,
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              color: nameColor,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          if (email != null && email!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: emailColor,
                height: 1.25,
              ),
            ),
          ],
          if (turnoActivo != null) ...[
            const SizedBox(height: 12),
            _TurnoStatusChip(activo: turnoActivo!),
          ],
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.fallbackInitial,
    this.fotoPerfilUrl,
  });

  final String? fotoPerfilUrl;
  final String fallbackInitial;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = fotoPerfilUrl != null && fotoPerfilUrl!.isNotEmpty;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _kDrawerAvatarBg,
        borderRadius: BorderRadius.circular(14),
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(fotoPerfilUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              fallbackInitial,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
    );
  }
}

class _TurnoStatusChip extends StatelessWidget {
  const _TurnoStatusChip({required this.activo});

  final bool activo;

  @override
  Widget build(BuildContext context) {
    // Sobre el header navy: chip oscuro con acento verde (como la referencia).
    final bg = activo
        ? const Color(0xFF1B3A2E)
        : const Color(0xFF243056);
    final fg = activo
        ? AppColors.statusPillForegroundDark
        : AppColors.statusClosedPillForegroundDark;
    final label = activo ? 'EN TURNO' : 'TURNO CERRADO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Gris / slate de las referencias (más suave que onSurfaceVariant).
    final color = isDark
        ? const Color(0xFF8B95A8)
        : const Color(0xFF9A9AA8);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 1.6,
              height: 1.2,
            ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.selectedForeground,
    required this.selectedBackground,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color selectedForeground;
  final Color selectedBackground;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: selectedBackground,
          highlightColor: selectedForeground.withValues(alpha: 0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: foreground, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppearanceChip extends StatelessWidget {
  const _AppearanceChip({
    required this.preference,
    required this.isDark,
  });

  final ThemeModePreference preference;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Chip informativo: refleja la apariencia efectiva (o la preferencia explícita).
    final showDark = preference == ThemeModePreference.dark ||
        (preference == ThemeModePreference.system && isDark);
    final label = showDark ? 'Oscuro' : 'Claro';
    final icon = showDark ? Icons.dark_mode_outlined : Icons.wb_sunny_outlined;
    final bg = isDark
        ? AppColors.darkCardBackground
        : AppColors.accentBlue.withValues(alpha: 0.08);
    final fg = isDark ? AppColors.infoIcon : AppColors.accentBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
