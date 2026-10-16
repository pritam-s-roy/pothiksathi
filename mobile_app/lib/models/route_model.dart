class RouteModel {
  final String id;
  final String name;
  final String origin;
  final String destination;
  final double distanceKm;
  final int estimatedMinutes;
  final bool isSharedAvailable;
  final bool isPrivateAvailable;
  final bool isActive;
  final List<String> landmarks;
  final DateTime? lastVerifiedAt;
  final String? verifiedBy;

  const RouteModel({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.estimatedMinutes,
    this.isSharedAvailable = true,
    this.isPrivateAvailable = true,
    this.isActive = true,
    this.landmarks = const [],
    this.lastVerifiedAt,
    this.verifiedBy,
  });

  factory RouteModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return RouteModel(
      id: id ?? map['id'] ?? '',
      name: map['name'] ?? '',
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      estimatedMinutes: (map['estimatedMinutes'] as num?)?.toInt() ?? 10,
      isSharedAvailable: map['isSharedAvailable'] ?? true,
      isPrivateAvailable: map['isPrivateAvailable'] ?? true,
      isActive: map['isActive'] ?? true,
      landmarks: List<String>.from(map['landmarks'] ?? []),
      lastVerifiedAt: map['lastVerifiedAt'] != null
          ? DateTime.tryParse(map['lastVerifiedAt'].toString())
          : null,
      verifiedBy: map['verifiedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'origin': origin,
      'destination': destination,
      'distanceKm': distanceKm,
      'estimatedMinutes': estimatedMinutes,
      'isSharedAvailable': isSharedAvailable,
      'isPrivateAvailable': isPrivateAvailable,
      'isActive': isActive,
      'landmarks': landmarks,
      'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
    };
  }

  /// Check whether route matches origin & destination regardless of direction
  bool matches(String from, String to) {
    final cleanFrom = from.trim().toLowerCase();
    final cleanTo = to.trim().toLowerCase();
    final rOrigin = origin.trim().toLowerCase();
    final rDest = destination.trim().toLowerCase();

    return (rOrigin.contains(cleanFrom) && rDest.contains(cleanTo)) ||
           (rOrigin.contains(cleanTo) && rDest.contains(cleanFrom));
  }
}
