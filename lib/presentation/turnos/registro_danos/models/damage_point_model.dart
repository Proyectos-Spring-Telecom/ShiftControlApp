import '../../models/checklist_type.dart';

enum VehicleView {
  frontal(1, 'Frontal'),
  trasera(2, 'Trasera'),
  lateralIzquierdo(3, 'Lateral Izquierdo'),
  lateralDerecho(4, 'Lateral Derecho');

  const VehicleView(this.idSeccion, this.nombre);

  final int idSeccion;
  final String nombre;

  /// Alias requerido por POST /api/turnos/inspeccion-vehiculo-ex.
  int get idCatVistaVehiculo => idSeccion;
}

enum DamageType {
  rayon(1, 'Rayón'),
  golpe(2, 'Golpe'),
  abolladura(3, 'Abolladura'),
  grieta(4, 'Grieta'),
  rotura(5, 'Rotura'),
  raspon(6, 'Raspón'),
  corrosionOxido(7, 'Corrosión / Óxido'),
  pinturaDanada(8, 'Pintura dañada'),
  faltante(9, 'Faltante'),
  estrellado(10, 'Estrellado');

  const DamageType(this.idTipoDanio, this.nombre);

  final int idTipoDanio;
  final String nombre;

  /// Alias requerido por POST /api/turnos/inspeccion-vehiculo-ex.
  int get idCatTipoDano => idTipoDanio;
}

enum DamageSeverity {
  baja(1, 'Baja'),
  media(2, 'Media'),
  alta(3, 'Alta'),
  critico(4, 'Crítico');

  const DamageSeverity(this.idCatGradoSeveridad, this.nombre);

  final int idCatGradoSeveridad;
  final String nombre;
}

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

  /// ID de sección del vehículo según la vista (Frontal=1, Trasera=2, etc.).
  int get idSeccion => view.idSeccion;
  String get nombreSeccion => view.nombre;

  /// Sección + tipo de daño registrado (disponible cuando [damageDetail] no es null).
  Map<String, dynamic>? get datosRegistroDanio => damageDetail?.datosRegistroConSeccion(
        idSeccion: idSeccion,
        nombreSeccion: nombreSeccion,
      );

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

  int get idTipoDanio => damageType.idTipoDanio;
  int get idCatTipoDano => damageType.idCatTipoDano;
  String get nombreTipoDanio => damageType.nombre;

  int get idCatGradoSeveridad => severity.idCatGradoSeveridad;
  String get nombreSeveridad => severity.nombre;

  /// Sección del vehículo + tipo de daño para consumo futuro de API.
  Map<String, dynamic> datosRegistroConSeccion({
    required int idSeccion,
    required String nombreSeccion,
  }) =>
      {
        'idSeccion': idSeccion,
        'nombreSeccion': nombreSeccion,
        'idTipoDanio': idTipoDanio,
        'nombreTipoDanio': nombreTipoDanio,
      };

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

  /// Sección visual seleccionada (pestaña activa).
  int get idSeccionSeleccionada => currentView.idSeccion;
  String get nombreSeccionSeleccionada => currentView.nombre;

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
