enum DriverApprovalStatus {
  pending,
  approved,
  suspended,
  rejected;

  static DriverApprovalStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return DriverApprovalStatus.approved;
      case 'suspended':
        return DriverApprovalStatus.suspended;
      case 'rejected':
        return DriverApprovalStatus.rejected;
      case 'pending':
      default:
        return DriverApprovalStatus.pending;
    }
  }

  String toDbString() {
    switch (this) {
      case DriverApprovalStatus.approved:
        return 'approved';
      case DriverApprovalStatus.suspended:
        return 'suspended';
      case DriverApprovalStatus.rejected:
        return 'rejected';
      case DriverApprovalStatus.pending:
        return 'pending';
    }
  }

  bool get isApproved => this == DriverApprovalStatus.approved;
}

class DriverProfileModel {
  final String driverId;
  final String vehicleNumber; // e.g. WB-52-TOTO-2024
  final String? licenseOrId;
  final DriverApprovalStatus approvalStatus;
  final bool isOnline;
  final String? currentBookingId;
  final String? offeredBookingId; // For 30s auto-dispatch offer
  final int totalTrips;
  final double rating;
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;
  final String registeredHub; // e.g. Karimpur Bus Stand
  final DateTime? onlineSince;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime updatedAt;

  bool get isApproved => approvalStatus == DriverApprovalStatus.approved;

  const DriverProfileModel({
    required this.driverId,
    required this.vehicleNumber,
    this.licenseOrId,
    required this.approvalStatus,
    required this.isOnline,
    this.currentBookingId,
    this.offeredBookingId,
    this.totalTrips = 0,
    this.rating = 5.0,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.registeredHub = 'Karimpur Bus Stand',
    this.onlineSince,
    this.approvedBy,
    this.approvedAt,
    required this.updatedAt,
  });

  factory DriverProfileModel.fromMap(Map<String, dynamic> map, {String? driverId}) {
    return DriverProfileModel(
      driverId: driverId ?? map['driverId'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      licenseOrId: map['licenseOrId'],
      approvalStatus: DriverApprovalStatus.fromString(map['approvalStatus']),
      isOnline: map['isOnline'] == true,
      currentBookingId: map['currentBookingId'],
      offeredBookingId: map['offeredBookingId'],
      totalTrips: (map['totalTrips'] as num?)?.toInt() ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationUpdatedAt: map['locationUpdatedAt'] != null
          ? DateTime.tryParse(map['locationUpdatedAt'].toString())
          : null,
      registeredHub: map['registeredHub'] ?? 'Karimpur Bus Stand',
      onlineSince: map['onlineSince'] != null
          ? DateTime.tryParse(map['onlineSince'].toString())
          : null,
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt'] != null
          ? DateTime.tryParse(map['approvedAt'].toString())
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverId': driverId,
      'vehicleNumber': vehicleNumber,
      'licenseOrId': licenseOrId,
      'approvalStatus': approvalStatus.toDbString(),
      'isOnline': isOnline,
      'currentBookingId': currentBookingId,
      'offeredBookingId': offeredBookingId,
      'totalTrips': totalTrips,
      'rating': rating,
      'latitude': latitude,
      'longitude': longitude,
      'locationUpdatedAt': locationUpdatedAt?.toIso8601String(),
      'registeredHub': registeredHub,
      'onlineSince': onlineSince?.toIso8601String(),
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  DriverProfileModel copyWith({
    String? driverId,
    String? vehicleNumber,
    String? licenseOrId,
    DriverApprovalStatus? approvalStatus,
    bool? isOnline,
    String? currentBookingId,
    String? offeredBookingId,
    int? totalTrips,
    double? rating,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    String? registeredHub,
    DateTime? onlineSince,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? updatedAt,
  }) {
    return DriverProfileModel(
      driverId: driverId ?? this.driverId,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      licenseOrId: licenseOrId ?? this.licenseOrId,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isOnline: isOnline ?? this.isOnline,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      offeredBookingId: offeredBookingId ?? this.offeredBookingId,
      totalTrips: totalTrips ?? this.totalTrips,
      rating: rating ?? this.rating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationUpdatedAt: locationUpdatedAt ?? this.locationUpdatedAt,
      registeredHub: registeredHub ?? this.registeredHub,
      onlineSince: onlineSince ?? this.onlineSince,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
