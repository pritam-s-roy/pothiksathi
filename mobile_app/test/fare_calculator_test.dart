import 'package:flutter_test/flutter_test.dart';
import 'package:pothiksathi/domain/fare_calculator.dart';
import 'package:pothiksathi/models/fare_model.dart';
import 'package:pothiksathi/models/route_model.dart';

void main() {
  group('TOTO Fare Calculator & Tariff Engine Tests', () {
    final sampleRoute = RouteModel(
      id: 'krm_route_01',
      name: 'Karimpur Bus Stand <-> Pannadevi College',
      origin: 'Karimpur Bus Stand',
      destination: 'Karimpur Pannadevi College',
      distanceKm: 1.8,
      estimatedMinutes: 8,
      isSharedAvailable: true,
      isPrivateAvailable: true,
      lastVerifiedAt: DateTime.now(),
      verifiedBy: 'admin_karimpur',
    );

    final sampleTariff = RouteFareModel(
      routeId: 'krm_route_01',
      sharedFarePerPassenger: 10.0,
      privateBaseFare: 25.0,
      minimumFare: 20.0,
      maxCapacity: 4,
      isNegotiable: false,
    );

    test('Shared fare calculates ₹10 per passenger on verified local route', () {
      final res1 = FareCalculator.calculate(
        bookingType: BookingType.shared,
        passengerCount: 1,
        route: sampleRoute,
        tariff: sampleTariff,
      );
      expect(res1.totalFare, equals(10.0));
      expect(res1.isVerified, isTrue);

      final res3 = FareCalculator.calculate(
        bookingType: BookingType.shared,
        passengerCount: 3,
        route: sampleRoute,
        tariff: sampleTariff,
      );
      expect(res3.totalFare, equals(30.0));
      expect(res3.snapshot.finalTotalFare, equals(30.0));
    });

    test('Shared booking caps passenger capacity at exactly 4 passengers', () {
      // 4 passengers is allowed
      final res4 = FareCalculator.calculate(
        bookingType: BookingType.shared,
        passengerCount: 4,
        route: sampleRoute,
        tariff: sampleTariff,
      );
      expect(res4.totalFare, equals(40.0));

      // 5 passengers throws CapacityExceeded
      expect(
        () => FareCalculator.calculate(
          bookingType: BookingType.shared,
          passengerCount: 5,
          route: sampleRoute,
          tariff: sampleTariff,
        ),
        throwsA(isA<FareCalculationException>()),
      );

      // 0 passengers throws error
      expect(
        () => FareCalculator.calculate(
          bookingType: BookingType.shared,
          passengerCount: 0,
          route: sampleRoute,
          tariff: sampleTariff,
        ),
        throwsA(isA<FareCalculationException>()),
      );
    });

    test('Private booking treats fare as whole-vehicle charge and enforces minimum fare of ₹20', () {
      final lowTariff = RouteFareModel(
        routeId: 'krm_route_low',
        sharedFarePerPassenger: 10.0,
        privateBaseFare: 15.0, // Proposed lower than minimum threshold
        minimumFare: 20.0,
      );

      final res = FareCalculator.calculate(
        bookingType: BookingType.private,
        passengerCount: 2,
        route: sampleRoute,
        tariff: lowTariff,
      );

      // Must be enforced to minimum fare ₹20
      expect(res.totalFare, equals(20.0));
    });

    test('Unverified route does not invent fares and flags for admin quotation', () {
      final res = FareCalculator.calculate(
        bookingType: BookingType.shared,
        passengerCount: 1,
        route: null,
        tariff: null,
      );

      expect(res.isVerified, isFalse);
      expect(res.totalFare, equals(0.0));
      expect(res.unverifiedReason, isNotNull);
      expect(res.snapshot.isTariffVerified, isFalse);
    });
  });
}
