import 'package:flutter_test/flutter_test.dart';
import 'package:pothiksathi/domain/booking_state_machine.dart';
import 'package:pothiksathi/models/booking_model.dart';
import 'package:pothiksathi/models/user_model.dart';

void main() {
  group('Booking Lifecycle & State Machine Tests', () {
    test('Allowed progression: pending -> assigned -> accepted -> arrived -> in_progress -> completed', () {
      expect(
        BookingStateMachine.canTransition(BookingStatus.pendingAssignment, BookingStatus.driverAssigned),
        isTrue,
      );
      expect(
        BookingStateMachine.canTransition(BookingStatus.driverAssigned, BookingStatus.driverAccepted),
        isTrue,
      );
      expect(
        BookingStateMachine.canTransition(BookingStatus.driverAccepted, BookingStatus.driverArrived),
        isTrue,
      );
      expect(
        BookingStateMachine.canTransition(BookingStatus.driverArrived, BookingStatus.inProgress),
        isTrue,
      );
      expect(
        BookingStateMachine.canTransition(BookingStatus.inProgress, BookingStatus.completed),
        isTrue,
      );
    });

    test('Invalid jump: pending directly to completed is strictly rejected', () {
      expect(
        BookingStateMachine.canTransition(BookingStatus.pendingAssignment, BookingStatus.completed),
        isFalse,
      );

      expect(
        () => BookingStateMachine.validateTransition(
          current: BookingStatus.pendingAssignment,
          target: BookingStatus.completed,
          actorRole: UserRole.driver,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );
    });

    test('Only admin can assign driver', () {
      // Driver cannot assign themselves
      expect(
        () => BookingStateMachine.validateTransition(
          current: BookingStatus.pendingAssignment,
          target: BookingStatus.driverAssigned,
          actorRole: UserRole.driver,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );

      // Passenger cannot assign driver
      expect(
        () => BookingStateMachine.validateTransition(
          current: BookingStatus.pendingAssignment,
          target: BookingStatus.driverAssigned,
          actorRole: UserRole.passenger,
        ),
        throwsA(isA<InvalidStateTransitionException>()),
      );

      // Admin CAN assign driver
      expect(
        () => BookingStateMachine.validateTransition(
          current: BookingStatus.pendingAssignment,
          target: BookingStatus.driverAssigned,
          actorRole: UserRole.admin,
        ),
        returnsNormally,
      );
    });

    test('Driver can reject assigned booking returning to reassignment', () {
      expect(
        BookingStateMachine.canTransition(BookingStatus.driverAssigned, BookingStatus.driverRejected),
        isTrue,
      );
      expect(
        BookingStateMachine.canTransition(BookingStatus.driverRejected, BookingStatus.pendingAssignment),
        isTrue,
      );
    });

    test('Passenger can cancel before driver arrival, but not after trip has started', () {
      // Allowed while pending
      expect(
        BookingStateMachine.canTransition(BookingStatus.pendingAssignment, BookingStatus.cancelledByPassenger),
        isTrue,
      );

      // Denied once trip is in progress
      expect(
        BookingStateMachine.canTransition(BookingStatus.inProgress, BookingStatus.cancelledByPassenger),
        isFalse,
      );
    });
  });
}
