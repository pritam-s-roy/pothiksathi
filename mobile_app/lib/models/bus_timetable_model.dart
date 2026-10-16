class BusTimetableModel {
  final String id;
  final String routeName;
  final String origin;
  final String destination;
  final List<String> viaStops;
  final String departureTime; // Format "HH:mm"
  final String arrivalTime;
  final String operatorName;
  final String busType; // "Ordinary", "Express", "Rocket", "Night Express"
  final String serviceDays; // "Daily", "Mon-Sat", etc.
  final double fareEstimate;
  final bool isVerified;
  final bool isActive;
  final DateTime? lastVerifiedAt;

  const BusTimetableModel({
    required this.id,
    required this.routeName,
    required this.origin,
    required this.destination,
    required this.viaStops,
    required this.departureTime,
    required this.arrivalTime,
    required this.operatorName,
    required this.busType,
    required this.serviceDays,
    required this.fareEstimate,
    this.isVerified = true,
    this.isActive = true,
    this.lastVerifiedAt,
  });

  factory BusTimetableModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return BusTimetableModel(
      id: id ?? map['id'] ?? '',
      routeName: map['routeName'] ?? '',
      origin: map['origin'] ?? '',
      destination: map['destination'] ?? '',
      viaStops: List<String>.from(map['viaStops'] ?? []),
      departureTime: map['departureTime'] ?? '',
      arrivalTime: map['arrivalTime'] ?? '',
      operatorName: map['operatorName'] ?? '',
      busType: map['busType'] ?? 'Ordinary',
      serviceDays: map['serviceDays'] ?? 'Daily',
      fareEstimate: (map['fareEstimate'] as num?)?.toDouble() ?? 0.0,
      isVerified: map['isVerified'] == true,
      isActive: map['isActive'] != false,
      lastVerifiedAt: map['lastVerifiedAt'] != null
          ? DateTime.tryParse(map['lastVerifiedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'routeName': routeName,
      'origin': origin,
      'destination': destination,
      'viaStops': viaStops,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'operatorName': operatorName,
      'busType': busType,
      'serviceDays': serviceDays,
      'fareEstimate': fareEstimate,
      'isVerified': isVerified,
      'isActive': isActive,
      'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
    };
  }

  /// Check whether search query matches destination, route name, or via stops
  bool matchesQuery(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    return routeName.toLowerCase().contains(q) ||
        destination.toLowerCase().contains(q) ||
        origin.toLowerCase().contains(q) ||
        operatorName.toLowerCase().contains(q) ||
        viaStops.any((stop) => stop.toLowerCase().contains(q));
  }
}
