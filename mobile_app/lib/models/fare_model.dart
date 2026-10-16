enum BookingType {
  shared,
  private;

  static BookingType fromString(String? type) {
    switch (type?.toLowerCase()) {
      case 'private':
      case 'reserve':
        return BookingType.private;
      case 'shared':
      default:
        return BookingType.shared;
    }
  }

  String toDbString() {
    switch (this) {
      case BookingType.private:
        return 'private';
      case BookingType.shared:
        return 'shared';
    }
  }
}

/// Administrator-configured tariff record for a specific route
class RouteFareModel {
  final String routeId;
  final double sharedFarePerPassenger; // ₹10.0 on designated local routes
  final double privateBaseFare;        // Vehicle charge
  final double minimumFare;            // Minimum threshold (default ₹20)
  final int maxCapacity;               // Standard TOTO capacity (4 seats)
  final bool isNegotiable;             // Always false for verified MVP routes
  final DateTime? lastVerifiedAt;

  const RouteFareModel({
    required this.routeId,
    required this.sharedFarePerPassenger,
    required this.privateBaseFare,
    this.minimumFare = 20.0,
    this.maxCapacity = 4,
    this.isNegotiable = false,
    this.lastVerifiedAt,
  });

  factory RouteFareModel.fromMap(Map<String, dynamic> map, {String? routeId}) {
    return RouteFareModel(
      routeId: routeId ?? map['routeId'] ?? '',
      sharedFarePerPassenger: (map['sharedFarePerPassenger'] as num?)?.toDouble() ?? 10.0,
      privateBaseFare: (map['privateBaseFare'] as num?)?.toDouble() ?? 25.0,
      minimumFare: (map['minimumFare'] as num?)?.toDouble() ?? 20.0,
      maxCapacity: (map['maxCapacity'] as num?)?.toInt() ?? 4,
      isNegotiable: map['isNegotiable'] == true,
      lastVerifiedAt: map['lastVerifiedAt'] != null
          ? DateTime.tryParse(map['lastVerifiedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'routeId': routeId,
      'sharedFarePerPassenger': sharedFarePerPassenger,
      'privateBaseFare': privateBaseFare,
      'minimumFare': minimumFare,
      'maxCapacity': maxCapacity,
      'isNegotiable': isNegotiable,
      'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
    };
  }
}

/// Immutable snapshot of the exact fare rules, tariffs, and parameters
/// at the time of booking creation. Cannot be retroactively tampered with.
class FareSnapshot {
  final String tariffVersion;
  final BookingType bookingType;
  final int passengerCount;
  final double perPassengerRate;
  final double baseVehicleRate;
  final double minimumFareThreshold;
  final double finalTotalFare;
  final bool isTariffVerified;
  final DateTime calculatedAt;

  const FareSnapshot({
    required this.tariffVersion,
    required this.bookingType,
    required this.passengerCount,
    required this.perPassengerRate,
    required this.baseVehicleRate,
    required this.minimumFareThreshold,
    required this.finalTotalFare,
    required this.isTariffVerified,
    required this.calculatedAt,
  });

  factory FareSnapshot.fromMap(Map<String, dynamic> map) {
    return FareSnapshot(
      tariffVersion: map['tariffVersion'] ?? 'KRM-2026-V1',
      bookingType: BookingType.fromString(map['bookingType']),
      passengerCount: (map['passengerCount'] as num?)?.toInt() ?? 1,
      perPassengerRate: (map['perPassengerRate'] as num?)?.toDouble() ?? 0.0,
      baseVehicleRate: (map['baseVehicleRate'] as num?)?.toDouble() ?? 0.0,
      minimumFareThreshold: (map['minimumFareThreshold'] as num?)?.toDouble() ?? 20.0,
      finalTotalFare: (map['finalTotalFare'] as num?)?.toDouble() ?? 0.0,
      isTariffVerified: map['isTariffVerified'] == true,
      calculatedAt: map['calculatedAt'] != null
          ? DateTime.tryParse(map['calculatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tariffVersion': tariffVersion,
      'bookingType': bookingType.toDbString(),
      'passengerCount': passengerCount,
      'perPassengerRate': perPassengerRate,
      'baseVehicleRate': baseVehicleRate,
      'minimumFareThreshold': minimumFareThreshold,
      'finalTotalFare': finalTotalFare,
      'isTariffVerified': isTariffVerified,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }
}
