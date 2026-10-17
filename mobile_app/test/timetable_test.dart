import 'package:flutter_test/flutter_test.dart';
import 'package:pothiksathi/models/bus_timetable_model.dart';

void main() {
  group('Bus Timetable & Offline Cache Tests', () {
    final sampleTimetable = BusTimetableModel(
      id: 'bus_test_01',
      routeName: 'Karimpur – Krishnanagar',
      origin: 'Karimpur Bus Stand',
      destination: 'Krishnanagar Bus Stand',
      viaStops: ['Tehatta', 'Chapra'],
      departureTime: '05:45',
      arrivalTime: '07:30',
      operatorName: 'SBSTC Ordinary Express',
      busType: 'Express',
      serviceDays: 'Daily',
      fareEstimate: 55,
      isVerified: true,
      lastVerifiedAt: DateTime(2026, 3, 10),
    );

    test('Query matching matches destination accurately', () {
      expect(sampleTimetable.matchesQuery('Krishnanagar'), isTrue);
      expect(sampleTimetable.matchesQuery('krishnanagar'), isTrue);
      expect(sampleTimetable.matchesQuery('Kolkata'), isFalse);
    });

    test('Query matching matches via intermediate stops', () {
      expect(sampleTimetable.matchesQuery('Tehatta'), isTrue);
      expect(sampleTimetable.matchesQuery('Chapra'), isTrue);
      expect(sampleTimetable.matchesQuery('Ranaghat'), isFalse);
    });

    test('Query matching matches operator name', () {
      expect(sampleTimetable.matchesQuery('SBSTC'), isTrue);
      expect(sampleTimetable.matchesQuery('NBSTC'), isFalse);
    });

    test('Timetable serialization to and from Map preserves verified date and status', () {
      final map = sampleTimetable.toMap();
      final restored = BusTimetableModel.fromMap(map);

      expect(restored.id, equals('bus_test_01'));
      expect(restored.isVerified, isTrue);
      expect(restored.fareEstimate, equals(55.0));
      expect(restored.lastVerifiedAt, isNotNull);
    });
  });
}
