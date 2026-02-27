import 'package:flutter/material.dart';

/// Tipo de alerta: éxito, información o error.
enum AppAlertType { success, info, error }

/// Colores e iconos por tipo según el diseño de banner.
class _AlertStyle {
  const _AlertStyle({
    required this.backgroundColor,
    required this.primaryColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color primaryColor;
  final IconData icon;

  static const success = _AlertStyle(
    backgroundColor: Color(0xFFE8F5E9),
    primaryColor: Color(0xFF2E7D32),
    icon: Icons.check,
  );
  static const info = _AlertStyle(
    backgroundColor: Color(0xFFFFF3E0),
    primaryColor: Color(0xFFE65100),
    icon: Icons.info_outlined,
  );
  static const error = _AlertStyle(
    backgroundColor: Color(0xFFFFEBEE),
    primaryColor: Color(0xFFC62828),
    icon: Icons.error_outlined,
  );

  static _AlertStyle forType(AppAlertType type) {
    switch (type) {
      case AppAlertType.success:
        return success;
      case AppAlertType.info:
        return info;
      case AppAlertType.error:
        return error;
    }
  }
}

/// Banner de alerta con diseño: barra lateral, icono, título, mensaje y botón cerrar.
class AppAlertBanner extends StatelessWidget {
  const AppAlertBanner({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.onClose,
  });

  final AppAlertType type;
  final String title;
  final String message;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final style = _AlertStyle.forType(type);
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.only(left: 12, top: 14, bottom: 14, right: 8),
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: style.primaryColor.withValues(alpha: 0.6), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 56,
              decoration: BoxDecoration(
                color: style.primaryColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: style.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: style.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(style.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade800,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.grey.shade700, size: 22),
              onPressed: onClose,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra un banner de alerta en la parte superior usando el overlay.
/// [onDismissed] se llama cuando el usuario cierra el banner.
void showAppAlertBanner(
  BuildContext context, {
  required AppAlertType type,
  required String title,
  required String message,
  VoidCallback? onDismissed,
}) {
  late OverlayEntry entry;
  void remove() {
    entry.remove();
    onDismissed?.call();
  }

  entry = OverlayEntry(
    builder: (overlayContext) => Positioned(
      top: MediaQuery.of(overlayContext).padding.top + 8,
      left: 0,
      right: 0,
      child: AppAlertBanner(
        type: type,
        title: title,
        message: message,
        onClose: remove,
      ),
    ),
  );

  Overlay.of(context).insert(entry);
}
