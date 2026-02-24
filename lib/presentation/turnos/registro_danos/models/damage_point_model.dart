import '../../models/checklist_type.dart';

enum VehicleView { frontal, trasera, lateralIzquierdo, lateralDerecho }

enum DamageType { abolladura, rayon, rotura }

enum DamageSeverity { baja, media, alta }

/// Representa un punto interactivo en el vehículo.
class DamagePoint {
  DamagePoint({
    required this.id,
    required this.view,
    required this.relativeX,
    required this.relativeY,
    required this.zoneName,
    this.isDamaged = false,
    this.damageDetail,
  });

  final String id;
  final VehicleView view;
  /// Posición X relativa (0.0 - 1.0) para responsividad.
  final double relativeX;
  /// Posición Y relativa (0.0 - 1.0) para responsividad.
  final double relativeY;
  final String zoneName;
  bool isDamaged;
  DamageDetail? damageDetail;

  DamagePoint copyWith({
    bool? isDamaged,
    DamageDetail? damageDetail,
  }) {
    return DamagePoint(
      id: id,
      view: view,
      relativeX: relativeX,
      relativeY: relativeY,
      zoneName: zoneName,
      isDamaged: isDamaged ?? this.isDamaged,
      damageDetail: damageDetail ?? this.damageDetail,
    );
  }
}

/// Detalle del daño registrado en un punto.
class DamageDetail {
  DamageDetail({
    required this.affectedPart,
    required this.damageType,
    required this.severity,
    this.description,
    this.photoPath,
  });

  final String affectedPart;
  final DamageType damageType;
  final DamageSeverity severity;
  final String? description;
  final String? photoPath;

  DamageDetail copyWith({
    String? affectedPart,
    DamageType? damageType,
    DamageSeverity? severity,
    String? description,
    String? photoPath,
  }) {
    return DamageDetail(
      affectedPart: affectedPart ?? this.affectedPart,
      damageType: damageType ?? this.damageType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
    );
  }
}

/// Estado completo del registro de daños.
class DamageRegistrationState {
  DamageRegistrationState({
    required this.checklistType,
    required this.points,
    this.currentView = VehicleView.lateralIzquierdo,
  });

  final ChecklistType checklistType;
  final List<DamagePoint> points;
  final VehicleView currentView;

  List<DamagePoint> get currentViewPoints =>
      points.where((p) => p.view == currentView).toList();

  List<DamagePoint> get damagedPoints =>
      points.where((p) => p.isDamaged).toList();

  int get totalDamages => damagedPoints.length;

  DamageRegistrationState copyWith({
    ChecklistType? checklistType,
    List<DamagePoint>? points,
    VehicleView? currentView,
  }) {
    return DamageRegistrationState(
      checklistType: checklistType ?? this.checklistType,
      points: points ?? this.points,
      currentView: currentView ?? this.currentView,
    );
  }
}
