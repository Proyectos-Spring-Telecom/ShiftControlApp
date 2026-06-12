class UbicacionReverseResult {
  const UbicacionReverseResult({
    this.displayName,
    this.address,
    required this.lat,
    required this.lon,
  });

  final String? displayName;
  final Map<String, dynamic>? address;
  final double lat;
  final double lon;

  factory UbicacionReverseResult.fromJson(Map<String, dynamic> json) {
    return UbicacionReverseResult(
      displayName: json['displayName'] as String?,
      address: json['address'] as Map<String, dynamic>?,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
    );
  }
}
