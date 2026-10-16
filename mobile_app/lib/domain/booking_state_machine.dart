import '../models/booking_model.dart';
import '../models/user_model.dart';

class InvalidStateTransitionException implements Exception {
  final String message;
  const InvalidStateTransitionException(this.message);
  @override
  String toString() => message;
}

class BookingStateMachine {
  /// Maps each status to its valid next states and permitted actor roles
  static final Map<BookingStatus, List<BookingStatus>> _allowedTransitions = {
    BookingStatus.pendingAssignment: [
      BookingStatus.driverAssigned,
      BookingStatus.cancelledByPassenger,
      BookingStatus.cancelledByAdmin,
    ],
    BookingStatus.driverAssigned: [
      BookingStatus.driverAccepted,
      BookingStatus.driverRejected,
      BookingStatus.cancelledByPassenger,
      BookingStatus.cancelledByAdmin,
    ],
    BookingStatus.driverRejected: [
      BookingStatus.pendingAssignment,
      BookingStatus.driverAssigned,
      BookingStatus.cancelledByAdmin,
    ],
    BookingStatus.driverAccepted: [
      BookingStatus.driverArrived,
      BookingStatus.cancelledByAdmin,
    ],
    BookingStatus.driverArrived: [
      BookingStatus.inProgress,
      BookingStatus.cancelledByAdmin,
    ],
    BookingStatus.inProgress: [
      BookingStatus.completed,
    ],
    BookingStatus.completed: [],
    BookingStatus.cancelledByPassenger: [],
    BookingStatus.cancelledByAdmin: [],
  };

  /// Verify if transition from current to target status is valid
  static bool canTransition(BookingStatus current, BookingStatus target) {
    final allowed = _allowedTransitions[current];
    if (allowed == null) return false;
    return allowed.contains(target);
  }

  /// Validates transition with role authority checks
  static void validateTransition({
    required BookingStatus current,
    required BookingStatus target,
    required UserRole actorRole,
    bool isSystemDispatch = false,
  }) {
    if (!canTransition(current, target)) {
      throw InvalidStateTransitionException(
        'Invalid booking state transition from ${current.toDbString()} to ${target.toDbString()}.',
      );
    }

    // Role authority guards
    switch (target) {
      case BookingStatus.driverAssigned:
        if (!isSystemDispatch && actorRole != UserRole.admin) {
          throw const InvalidStateTransitionException('Only system auto-dispatch or administrators can assign drivers.');
        }
        break;

      case BookingStatus.driverAccepted:
      case BookingStatus.driverRejected:
      case BookingStatus.driverArrived:
      case BookingStatus.inProgress:
      case BookingStatus.completed:
        if (!isSystemDispatch && actorRole != UserRole.driver && actorRole != UserRole.admin) {
          throw const InvalidStateTransitionException('Only assigned drivers can advance trip milestones.');
        }
        break;

      case BookingStatus.cancelledByPassenger:
        if (actorRole != UserRole.passenger && actorRole != UserRole.admin) {
          throw const InvalidStateTransitionException('Only the booking passenger can perform passenger cancellation.');
        }
        break;

      case BookingStatus.cancelledByAdmin:
        if (actorRole != UserRole.admin) {
          throw const InvalidStateTransitionException('Only administrators can execute administrative cancellations.');
        }
        break;

      case BookingStatus.pendingAssignment:
        break;
    }
  }
}
