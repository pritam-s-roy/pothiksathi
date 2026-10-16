import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/booking_state_machine.dart';
import '../../models/booking_model.dart';
import '../../models/fare_model.dart';
import '../../models/route_model.dart';
import '../../models/user_model.dart';

class MockDriverCandidate {
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String vehicleNumber;
  final double rating;
  final double latitude;
  final double longitude;
  final String registeredHub;
  final DateTime onlineSince;

  MockDriverCandidate({
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.vehicleNumber,
    required this.rating,
    required this.latitude,
    required this.longitude,
    required this.registeredHub,
    required this.onlineSince,
  });
}

class BookingService extends ChangeNotifier {
  BookingModel? _activeBooking;
  final List<BookingModel> _history = [];
  bool _isSubmitting = false;
  String? _lastIdempotencyKey;
  String? _errorMessage;

  // Dispatch mode configuration: default is 'automatic'
  String _dispatchMode = 'automatic'; // 'automatic' | 'manual'
  Timer? _offerTimeoutTimer;
  Timer? _countdownTickTimer;

  BookingModel? get activeBooking => _activeBooking;
  List<BookingModel> get history => List.unmodifiable(_history);
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasActiveBooking => _activeBooking != null && _activeBooking!.status.isActive;
  String get dispatchMode => _dispatchMode;
  bool get isAutoDispatch => _dispatchMode == 'automatic';

  // Available online approved driver fleet in Karimpur
  final List<MockDriverCandidate> _driverFleet = [
    MockDriverCandidate(
      driverId: 'drv_01',
      driverName: 'Bapi Mondal (বাপ্পি মণ্ডল)',
      driverPhone: '+91 98000 12345',
      vehicleNumber: 'WB-52-TOTO-8812',
      rating: 4.9,
      latitude: 23.9682,
      longitude: 88.6201, // Karimpur Bus Stand
      registeredHub: 'Karimpur Bus Stand',
      onlineSince: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    MockDriverCandidate(
      driverId: 'drv_02',
      driverName: 'Tarun Ghosh (তরুণ ঘোষ)',
      driverPhone: '+91 97330 99887',
      vehicleNumber: 'WB-52-TOTO-3301',
      rating: 4.8,
      latitude: 23.9740,
      longitude: 88.6225, // Near Rural Hospital
      registeredHub: 'Karimpur Rural Hospital',
      onlineSince: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    MockDriverCandidate(
      driverId: 'drv_05',
      driverName: 'Prabir Das (প্রবীর দাস)',
      driverPhone: '+91 94340 77112',
      vehicleNumber: 'WB-52-TOTO-5104',
      rating: 4.7,
      latitude: 23.9610,
      longitude: 88.6280, // Near Pannadevi College
      registeredHub: 'Karimpur Pannadevi College',
      onlineSince: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  BookingService() {
    _loadSampleHistory();
  }

  @override
  void dispose() {
    _offerTimeoutTimer?.cancel();
    _countdownTickTimer?.cancel();
    super.dispose();
  }

  void _loadSampleHistory() {
    _history.add(
      BookingModel(
        id: 'BK-KRM-2026-041',
        passengerId: 'passenger_karimpur_01',
        passengerName: 'Sourav Biswas',
        passengerPhone: '9876543210',
        bookingType: BookingType.shared,
        passengerCount: 1,
        routeId: 'krm_route_01',
        originName: 'Karimpur Bus Stand',
        destinationName: 'Karimpur Pannadevi College',
        distanceKm: 1.8,
        fare: 10.0,
        fareSnapshot: FareSnapshot(
          tariffVersion: 'KRM-2026-V1',
          bookingType: BookingType.shared,
          passengerCount: 1,
          perPassengerRate: 10.0,
          baseVehicleRate: 0.0,
          minimumFareThreshold: 0.0,
          finalTotalFare: 10.0,
          isTariffVerified: true,
          calculatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        status: BookingStatus.completed,
        driverId: 'drv_01',
        driverName: 'Bapi Mondal',
        driverPhone: '9800012345',
        vehicleNumber: 'WB-52-TOTO-8812',
        assignmentType: 'automatic',
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
        completedAt: DateTime.now().subtract(const Duration(days: 2, hours: 1, minutes: 45)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2, hours: 1, minutes: 45)),
      ),
    );
  }

  /// Toggle system dispatch mode
  void setDispatchMode(String mode) {
    _dispatchMode = mode;
    notifyListeners();
  }

  /// Create a new booking request with idempotency protection and auto-dispatch
  Future<BookingModel?> createBooking({
    required UserModel passenger,
    required RouteModel route,
    required BookingType bookingType,
    required int passengerCount,
    required double fare,
    required FareSnapshot snapshot,
    required String idempotencyKey,
  }) async {
    if (_isSubmitting || (_lastIdempotencyKey != null && _lastIdempotencyKey == idempotencyKey)) {
      debugPrint('Duplicate booking request ignored: $idempotencyKey');
      return _activeBooking;
    }

    _isSubmitting = true;
    _lastIdempotencyKey = idempotencyKey;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final bookingId = 'BK-KRM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final newBooking = BookingModel(
        id: bookingId,
        passengerId: passenger.id,
        passengerName: passenger.name,
        passengerPhone: passenger.phoneNumber,
        bookingType: bookingType,
        passengerCount: passengerCount,
        routeId: route.id,
        originName: route.origin,
        destinationName: route.destination,
        distanceKm: route.distanceKm,
        fare: fare,
        fareSnapshot: snapshot,
        status: BookingStatus.pendingAssignment,
        assignmentType: _dispatchMode,
        idempotencyKey: idempotencyKey,
        attemptedDriverIds: const [],
        autoDispatchExhausted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _activeBooking = newBooking;
      _isSubmitting = false;
      notifyListeners();

      // Trigger automatic matching if in automatic mode
      if (_dispatchMode == 'automatic') {
        _runAutoDispatchSequence(newBooking);
      }

      return newBooking;
    } catch (e) {
      _errorMessage = 'Booking creation failed: $e';
      _isSubmitting = false;
      notifyListeners();
      return null;
    }
  }

  /// Automated driver dispatch sequence with 30s timeout and cascading offers
  Future<void> _runAutoDispatchSequence(BookingModel booking) async {
    _offerTimeoutTimer?.cancel();
    _countdownTickTimer?.cancel();

    if (_activeBooking?.id != booking.id || _activeBooking?.status.isTerminal == true) {
      return;
    }

    // 1. Filter out drivers already attempted for this booking
    final attempted = List<String>.from(_activeBooking?.attemptedDriverIds ?? []);
    final eligible = _driverFleet.where((d) => !attempted.contains(d.driverId)).toList();

    // 2. Fallback check: If candidate pool exhausted -> Alert Admin Desk
    if (eligible.isEmpty) {
      debugPrint('Auto-dispatch candidate list exhausted. Escalating to Karimpur Admin Desk.');
      _activeBooking = _activeBooking!.copyWith(
        status: BookingStatus.pendingAssignment,
        autoDispatchExhausted: true,
        assignmentType: 'manual_fallback',
        driverId: null,
        driverName: null,
        driverPhone: null,
        vehicleNumber: null,
        dispatchOfferedAt: null,
        dispatchExpiresAt: null,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return;
    }

    // 3. Rank eligible drivers: Match origin hub first or nearest
    eligible.sort((a, b) {
      final aSameHub = booking.originName.toLowerCase().contains(a.registeredHub.toLowerCase());
      final bSameHub = booking.originName.toLowerCase().contains(b.registeredHub.toLowerCase());
      if (aSameHub && !bSameHub) return -1;
      if (!aSameHub && bSameHub) return 1;
      return b.rating.compareTo(a.rating);
    });

    final candidate = eligible.first;
    attempted.add(candidate.driverId);

    final now = DateTime.now();
    const timeoutDuration = Duration(seconds: 30);
    final expiresAt = now.add(timeoutDuration);

    _activeBooking = _activeBooking!.copyWith(
      status: BookingStatus.driverAssigned,
      driverId: candidate.driverId,
      driverName: candidate.driverName,
      driverPhone: candidate.driverPhone,
      vehicleNumber: candidate.vehicleNumber,
      assignmentType: 'automatic',
      dispatchOfferedAt: now,
      dispatchExpiresAt: expiresAt,
      attemptedDriverIds: attempted,
      autoDispatchExhausted: false,
      assignedAt: now,
      updatedAt: now,
    );
    notifyListeners();

    // 4. Start 1-second countdown ticker for UI responsiveness
    _countdownTickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeBooking == null ||
          _activeBooking!.status != BookingStatus.driverAssigned ||
          _activeBooking!.isOfferExpired) {
        timer.cancel();
      } else {
        notifyListeners(); // Refresh remainingOfferSeconds on UI
      }
    });

    // 5. 30-Second Acceptance Timeout Timer
    _offerTimeoutTimer = Timer(timeoutDuration, () {
      if (_activeBooking?.id == booking.id &&
          _activeBooking?.status == BookingStatus.driverAssigned &&
          _activeBooking?.driverId == candidate.driverId) {
        debugPrint('Driver ${candidate.driverName} timed out (30s). Cascading to next candidate.');
        _handleDriverRejectionOrTimeout('Offer acceptance window expired (30s timeout)');
      }
    });
  }

  /// Driver accepts offered trip
  Future<bool> acceptDriverOffer(String driverId) async {
    if (_activeBooking == null || _activeBooking!.driverId != driverId) return false;

    if (_activeBooking!.isOfferExpired) {
      _errorMessage = 'Offer acceptance window expired.';
      notifyListeners();
      return false;
    }

    _offerTimeoutTimer?.cancel();
    _countdownTickTimer?.cancel();

    try {
      BookingStateMachine.validateTransition(
        current: _activeBooking!.status,
        target: BookingStatus.driverAccepted,
        actorRole: UserRole.driver,
      );

      _activeBooking = _activeBooking!.copyWith(
        status: BookingStatus.driverAccepted,
        acceptedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Driver rejects offered trip (or times out) -> Triggers automatic cascade
  Future<void> rejectDriverOffer(String driverId, String reason) async {
    if (_activeBooking == null || _activeBooking!.driverId != driverId) return;

    _offerTimeoutTimer?.cancel();
    _countdownTickTimer?.cancel();

    _handleDriverRejectionOrTimeout(reason);
  }

  void _handleDriverRejectionOrTimeout(String reason) {
    if (_activeBooking == null) return;

    _activeBooking = _activeBooking!.copyWith(
      status: BookingStatus.pendingAssignment,
      driverId: null,
      driverName: null,
      driverPhone: null,
      vehicleNumber: null,
      dispatchOfferedAt: null,
      dispatchExpiresAt: null,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    // Cascade to next driver if in auto mode
    if (_dispatchMode == 'automatic') {
      _runAutoDispatchSequence(_activeBooking!);
    }
  }

  /// Admin manual assignment override
  Future<bool> adminManualAssign(String driverId, String name, String phone, String vehicle) async {
    if (_activeBooking == null) return false;

    _offerTimeoutTimer?.cancel();
    _countdownTickTimer?.cancel();

    _activeBooking = _activeBooking!.copyWith(
      status: BookingStatus.driverAssigned,
      driverId: driverId,
      driverName: name,
      driverPhone: phone,
      vehicleNumber: vehicle,
      assignmentType: 'manual',
      assignedAt: DateTime.now(),
      dispatchOfferedAt: null,
      dispatchExpiresAt: null,
      autoDispatchExhausted: false,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return true;
  }

  /// Passenger manually cancels booking before driver arrives
  Future<bool> cancelBookingByPassenger(String reason) async {
    if (_activeBooking == null) return false;

    _offerTimeoutTimer?.cancel();
    _countdownTickTimer?.cancel();

    try {
      BookingStateMachine.validateTransition(
        current: _activeBooking!.status,
        target: BookingStatus.cancelledByPassenger,
        actorRole: UserRole.passenger,
      );

      final cancelled = _activeBooking!.copyWith(
        status: BookingStatus.cancelledByPassenger,
        updatedAt: DateTime.now(),
      );

      _history.insert(0, cancelled);
      _activeBooking = cancelled;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Driver advances trip status (Arrived -> In Progress -> Completed)
  Future<bool> advanceDriverStatus(BookingStatus newStatus) async {
    if (_activeBooking == null) return false;

    try {
      BookingStateMachine.validateTransition(
        current: _activeBooking!.status,
        target: newStatus,
        actorRole: UserRole.driver,
      );

      final updated = _activeBooking!.copyWith(
        status: newStatus,
        arrivedAt: newStatus == BookingStatus.driverArrived ? DateTime.now() : _activeBooking!.arrivedAt,
        startedAt: newStatus == BookingStatus.inProgress ? DateTime.now() : _activeBooking!.startedAt,
        completedAt: newStatus == BookingStatus.completed ? DateTime.now() : _activeBooking!.completedAt,
        updatedAt: DateTime.now(),
      );

      _activeBooking = updated;
      if (newStatus == BookingStatus.completed) {
        _history.insert(0, updated);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearActiveBooking() {
    _offerTimeoutTimer?.cancel();
    _countdownTickTimer?.cancel();
    _activeBooking = null;
    notifyListeners();
  }
}
