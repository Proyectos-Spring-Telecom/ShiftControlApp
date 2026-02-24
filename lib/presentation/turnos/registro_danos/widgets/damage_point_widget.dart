import 'package:flutter/material.dart';

import '../models/damage_point_model.dart';
import '../registro_danos_colors.dart';

/// ! Widget reutilizable para punto interactivo de daño.
/// 
/// Representa un punto táctil sobre el vehículo que puede ser
/// activado/desactivado para registrar daños.
class DamagePointWidget extends StatefulWidget {
  const DamagePointWidget({
    super.key,
    required this.point,
    required this.onTap,
    this.size = 32,
  });

  final DamagePoint point;
  final VoidCallback onTap;
  final double size;

  @override
  State<DamagePointWidget> createState() => _DamagePointWidgetState();
}

class _DamagePointWidgetState extends State<DamagePointWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isDamaged = widget.point.isDamaged;
    final baseColor = isDamaged
        ? RegistroDanosColors.pointDamaged
        : RegistroDanosColors.pointNormal(context);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: baseColor.withValues(alpha: isDamaged ? 0.3 : 0.5),
            border: Border.all(
              color: isDamaged ? RegistroDanosColors.pointDamaged : RegistroDanosColors.pointBorder(context),
              width: 2,
            ),
          ),
          child: isDamaged
              ? Center(
                  child: Icon(
                    Icons.priority_high,
                    color: RegistroDanosColors.pointDamaged,
                    size: widget.size * 0.5,
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.add,
                    color: RegistroDanosColors.textSecondary(context),
                    size: widget.size * 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
