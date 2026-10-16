import '../models/fare_model.dart';
import '../models/route_model.dart';

class FareCalculationException implements Exception {
  final String message;
  const FareCalculationException(this.message);
  @override
  String toString() => message;
}

class FareCalculationResult {
  final double totalFare;
  final double baseRate;
  final int passengerCount;
  final BookingType bookingType;
  final bool isVerified;
  final String? unverifiedReason;
  final FareSnapshot snapshot;

  const FareCalculationResult({
    required this.totalFare,
    required this.baseRate,
    required this.passengerCount,
    required this.bookingType,
    required this.isVerified,
    this.unverifiedReason,
    required this.snapshot,
  });
}

class FareCalculator {
  static const int standardTotoCapacity = 4;
  static const double standardMinimumPrivateFare = 20.0;
  static const double standardLocalSharedFare = 10.0; // ₹10 per passenger in Karimpur

  /// Calculate and validate fare for a given route and passenger count
  static FareCalculationResult calculate({
    required BookingType bookingType,
    required int passengerCount,
    required RouteModel? route,
    required RouteFareModel? tariff,
  }) {
    // 1. Validate Passenger Capacity
    if (passengerCount < 1) {
      throw const FareCalculationException('At least 1 passenger is required.');
    }
    if (passengerCount > standardTotoCapacity) {
      throw FareCalculationException(
        'Passenger count ($passengerCount) exceeds maximum TOTO capacity of $standardTotoCapacity passengers.',
      );
    }

    // 2. Validate Route Existence
    if (route == null || tariff == null) {
      return FareCalculationResult(
        totalFare: 0.0,
        baseRate: 0.0,
        passengerCount: passengerCount,
        bookingType: bookingType,
        isVerified: false,
        unverifiedReason: 'Unverified route: No approved tariff exists between selected locations. Requires admin quote.',
        snapshot: FareSnapshot(
          tariffVersion: 'UNVERIFIED',
          bookingType: bookingType,
          passengerCount: passengerCount,
          perPassengerRate: 0.0,
          baseVehicleRate: 0.0,
          minimumFareThreshold: standardMinimumPrivateFare,
          finalTotalFare: 0.0,
          isTariffVerified: false,
          calculatedAt: DateTime.now(),
        ),
      );
    }

    // 3. Shared Booking Calculation
    if (bookingType == BookingType.shared) {
      if (!route.isSharedAvailable) {
        throw const FareCalculationException('Shared TOTO service is not offered on this specific route.');
      }

      final perPassengerFare = tariff.sharedFarePerPassenger;
      final calculatedTotal = perPassengerFare * passengerCount;

      return FareCalculationResult(
        totalFare: calculatedTotal,
        baseRate: perPassengerFare,
        passengerCount: passengerCount,
        bookingType: BookingType.shared,
        isVerified: true,
        snapshot: FareSnapshot(
          tariffVersion: 'KRM-TARIFF-2026',
          bookingType: BookingType.shared,
          passengerCount: passengerCount,
          perPassengerRate: perPassengerFare,
          baseVehicleRate: 0.0,
          minimumFareThreshold: 0.0,
          finalTotalFare: calculatedTotal,
          isTariffVerified: true,
          calculatedAt: DateTime.now(),
        ),
      );
    }

    // 4. Private (Reserve) Whole-Vehicle Calculation
    if (!route.isPrivateAvailable) {
      throw const FareCalculationException('Private reserve service is currently disabled on this route.');
    }

    // Treat fare as whole-vehicle price, subject to minimum fare threshold
    final vehicleRate = tariff.privateBaseFare;
    final minThreshold = tariff.minimumFare > 0 ? tariff.minimumFare : standardMinimumPrivateFare;
    final finalPrivateFare = vehicleRate < minThreshold ? minThreshold : vehicleRate;

    return FareCalculationResult(
      totalFare: finalPrivateFare,
      baseRate: vehicleRate,
      passengerCount: passengerCount,
      bookingType: BookingType.private,
      isVerified: true,
      snapshot: FareSnapshot(
        tariffVersion: 'KRM-TARIFF-2026',
        bookingType: BookingType.private,
        passengerCount: passengerCount,
        perPassengerRate: 0.0,
        baseVehicleRate: vehicleRate,
        minimumFareThreshold: minThreshold,
        finalTotalFare: finalPrivateFare,
        isTariffVerified: true,
        calculatedAt: DateTime.now(),
      ),
    );
  }
}
