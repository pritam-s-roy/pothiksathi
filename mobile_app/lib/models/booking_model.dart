import 'fare_model.dart';
export 'fare_model.dart';

enum BookingStatus {
  pendingAssignment,
  driverAssigned,
  driverAccepted,
  driverRejected,
  driverArrived,
  inProgress,
  completed,
  cancelledByPassenger,
  cancelledByAdmin;

  static BookingStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'driver_assigned':
      case 'assigned':
        return BookingStatus.driverAssigned;
      case 'driver_accepted':
      case 'accepted':
        return BookingStatus.driverAccepted;
      case 'driver_rejected':
      case 'rejected':
        return BookingStatus.driverRejected;
      case 'driver_arrived':
      case 'arrived':
        return BookingStatus.driverArrived;
      case 'in_progress':
      case 'picked_up':
        return BookingStatus.inProgress;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled_by_passenger':
        return BookingStatus.cancelledByPassenger;
      case 'cancelled_by_admin':
      case 'cancelled':
        return BookingStatus.cancelledByAdmin;
      case 'pending_assignment':
      case 'pending':
      default:
        return BookingStatus.pendingAssignment;
    }
  }

  String toDbString() {
    switch (this) {
      case BookingStatus.pendingAssignment:
        return 'pending_assignment';
      case BookingStatus.driverAssigned:
        return 'driver_assigned';
      case BookingStatus.driverAccepted:
        return 'driver_accepted';
      case BookingStatus.driverRejected:
        return 'driver_rejected';
      case BookingStatus.driverArrived:
        return 'driver_arrived';
      case BookingStatus.inProgress:
        return 'in_progress';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelledByPassenger:
        return 'cancelled_by_passenger';
      case BookingStatus.cancelledByAdmin:
        return 'cancelled_by_admin';
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pendingAssignment:
        return 'Matching Available Driver';
      case BookingStatus.driverAssigned:
        return 'Driver Offered / Awaiting Confirmation';
      case BookingStatus.driverAccepted:
        return 'Driver Accepted / On The Way';
      case BookingStatus.driverRejected:
        return 'Reassigning Driver';
      case BookingStatus.driverArrived:
        return 'Driver Arrived at Pickup';
      case BookingStatus.inProgress:
        return 'Trip In Progress';
      case BookingStatus.completed:
        return 'Trip Completed';
      case BookingStatus.cancelledByPassenger:
        return 'Cancelled by You';
      case BookingStatus.cancelledByAdmin:
        return 'Cancelled by Admin';
    }
  }

  bool get isPending => this == BookingStatus.pendingAssignment;

  bool get isActive =>
      this == BookingStatus.pendingAssignment ||
      this == BookingStatus.driverAssigned ||
      this == BookingStatus.driverAccepted ||
      this == BookingStatus.driverArrived ||
      this == BookingStatus.inProgress;

  bool get isTerminal =>
      this == BookingStatus.completed ||
      this == BookingStatus.cancelledByPassenger ||
      this == BookingStatus.cancelledByAdmin;
}

class BookingModel {
  final String id;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;
  final BookingType bookingType;
  final int passengerCount;
  final String routeId;
  final String originName;
  final String destinationName;
  final double distanceKm;
  final double fare;
  final FareSnapshot fareSnapshot;
  final BookingStatus status;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? vehicleNumber;
  final String assignmentType; // 'automatic' (default), 'manual', 'manual_fallback'
  final DateTime? dispatchOfferedAt;
  final DateTime? dispatchExpiresAt;
  final List<String> attemptedDriverIds;
  final bool autoDispatchExhausted;
  final String? idempotencyKey; // Prevents duplicate submissions
  final DateTime createdAt;
  final DateTime? assignedAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;

  const BookingModel({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
    required this.bookingType,
    required this.passengerCount,
    required this.routeId,
    required this.originName,
    required this.destinationName,
    required this.distanceKm,
    required this.fare,
    required this.fareSnapshot,
    required this.status,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.vehicleNumber,
    this.assignmentType = 'automatic',
    this.dispatchOfferedAt,
    this.dispatchExpiresAt,
    this.attemptedDriverIds = const [],
    this.autoDispatchExhausted = false,
    this.idempotencyKey,
    required this.createdAt,
    this.assignedAt,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    this.completedAt,
    required this.updatedAt,
  });

  /// Remaining seconds on the driver acceptance countdown timer
  int get remainingOfferSeconds {
    if (dispatchExpiresAt == null) return 0;
    final diff = dispatchExpiresAt!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool get isOfferExpired {
    if (dispatchExpiresAt == null) return false;
    return DateTime.now().isAfter(dispatchExpiresAt!);
  }

  double get totalFare => fare;

  factory BookingModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return BookingModel(
      id: id ?? map['id'] ?? '',
      passengerId: map['passengerId'] ?? '',
      passengerName: map['passengerName'] ?? '',
      passengerPhone: map['passengerPhone'] ?? '',
      bookingType: BookingType.fromString(map['bookingType']),
      passengerCount: (map['passengerCount'] as num?)?.toInt() ?? 1,
      routeId: map['routeId'] ?? '',
      originName: map['originName'] ?? '',
      destinationName: map['destinationName'] ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      fare: (map['fare'] as num?)?.toDouble() ?? 0.0,
      fareSnapshot: map['fareSnapshot'] is Map<String, dynamic>
          ? FareSnapshot.fromMap(map['fareSnapshot'])
          : FareSnapshot(
              tariffVersion: 'KRM-2026',
              bookingType: BookingType.fromString(map['bookingType']),
              passengerCount: (map['passengerCount'] as num?)?.toInt() ?? 1,
              perPassengerRate: 10.0,
              baseVehicleRate: 0.0,
              minimumFareThreshold: 20.0,
              finalTotalFare: (map['fare'] as num?)?.toDouble() ?? 0.0,
              isTariffVerified: true,
              calculatedAt: DateTime.now(),
            ),
      status: BookingStatus.fromString(map['status']),
      driverId: map['driverId'],
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      vehicleNumber: map['vehicleNumber'],
      assignmentType: map['assignmentType'] ?? 'automatic',
      dispatchOfferedAt: map['dispatchOfferedAt'] != null
          ? DateTime.tryParse(map['dispatchOfferedAt'].toString())
          : null,
      dispatchExpiresAt: map['dispatchExpiresAt'] != null
          ? DateTime.tryParse(map['dispatchExpiresAt'].toString())
          : null,
      attemptedDriverIds: List<String>.from(map['attemptedDriverIds'] ?? []),
      autoDispatchExhausted: map['autoDispatchExhausted'] == true,
      idempotencyKey: map['idempotencyKey'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      assignedAt: map['assignedAt'] != null
          ? DateTime.tryParse(map['assignedAt'].toString())
          : null,
      acceptedAt: map['acceptedAt'] != null
          ? DateTime.tryParse(map['acceptedAt'].toString())
          : null,
      arrivedAt: map['arrivedAt'] != null
          ? DateTime.tryParse(map['arrivedAt'].toString())
          : null,
      startedAt: map['startedAt'] != null
          ? DateTime.tryParse(map['startedAt'].toString())
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'bookingType': bookingType.toDbString(),
      'passengerCount': passengerCount,
      'routeId': routeId,
      'originName': originName,
      'destinationName': destinationName,
      'distanceKm': distanceKm,
      'fare': fare,
      'fareSnapshot': fareSnapshot.toMap(),
      'status': status.toDbString(),
      'driverId': driverId,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'vehicleNumber': vehicleNumber,
      'assignmentType': assignmentType,
      'dispatchOfferedAt': dispatchOfferedAt?.toIso8601String(),
      'dispatchExpiresAt': dispatchExpiresAt?.toIso8601String(),
      'attemptedDriverIds': attemptedDriverIds,
      'autoDispatchExhausted': autoDispatchExhausted,
      'idempotencyKey': idempotencyKey,
      'createdAt': createdAt.toIso8601String(),
      'assignedAt': assignedAt?.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'arrivedAt': arrivedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  BookingModel copyWith({
    String? id,
    String? passengerId,
    String? passengerName,
    String? passengerPhone,
    BookingType? bookingType,
    int? passengerCount,
    String? routeId,
    String? originName,
    String? destinationName,
    double? distanceKm,
    double? fare,
    FareSnapshot? fareSnapshot,
    BookingStatus? status,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? vehicleNumber,
    String? assignmentType,
    DateTime? dispatchOfferedAt,
    DateTime? dispatchExpiresAt,
    List<String>? attemptedDriverIds,
    bool? autoDispatchExhausted,
    String? idempotencyKey,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
  }) {
    return BookingModel(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      passengerName: passengerName ?? this.passengerName,
      passengerPhone: passengerPhone ?? this.passengerPhone,
      bookingType: bookingType ?? this.bookingType,
      passengerCount: passengerCount ?? this.passengerCount,
      routeId: routeId ?? this.routeId,
      originName: originName ?? this.originName,
      destinationName: destinationName ?? this.destinationName,
      distanceKm: distanceKm ?? this.distanceKm,
      fare: fare ?? this.fare,
      fareSnapshot: fareSnapshot ?? this.fareSnapshot,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      assignmentType: assignmentType ?? this.assignmentType,
      dispatchOfferedAt: dispatchOfferedAt ?? this.dispatchOfferedAt,
      dispatchExpiresAt: dispatchExpiresAt ?? this.dispatchExpiresAt,
      attemptedDriverIds: attemptedDriverIds ?? this.attemptedDriverIds,
      autoDispatchExhausted: autoDispatchExhausted ?? this.autoDispatchExhausted,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
