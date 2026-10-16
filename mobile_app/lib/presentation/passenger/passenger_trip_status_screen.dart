import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/booking_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';

class PassengerTripStatusScreen extends StatelessWidget {
  const PassengerTripStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookingService = context.watch<BookingService>();
    final booking = bookingService.activeBooking;

    if (booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Status')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text('No Active Trip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You have no ongoing TOTO bookings right now.'),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Back to Home',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(booking.id),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Banner Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: Column(
                children: [
                  StatusBadge(status: booking.status.toDbString(), label: booking.status.displayName),
                  const SizedBox(height: 12),
                  Text(
                    booking.status.displayName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusSubtitle(booking),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Visual Milestone Step Bar
            _buildMilestoneTracker(booking.status),
            const SizedBox(height: 16),

            // Driver Details Card (When assigned)
            if (booking.driverName != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Assigned TOTO Driver (চালক বিবরণ)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.primaryTint,
                            child: const Icon(Icons.electric_rickshaw, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  booking.driverName!,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  booking.vehicleNumber ?? 'Verified Karimpur TOTO',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: AppColors.primary),
                            tooltip: 'Call Driver',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Calling ${booking.driverPhone}...')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Trip Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trip Specifications', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const Divider(height: 18),
                    _buildDetailRow('Pickup Location', booking.originName),
                    _buildDetailRow('Drop Location', booking.destinationName),
                    _buildDetailRow('Ride Category', booking.bookingType == BookingType.shared ? 'Shared TOTO (₹10/seat)' : 'Private Reserve'),
                    _buildDetailRow('Passenger Count', '${booking.passengerCount} passenger(s)'),
                    _buildDetailRow('Total Agreed Fare', Formatters.formatCurrency(booking.fare), isHighlighted: true),
                    _buildDetailRow('Payment Mode', 'Cash after trip completion'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Cancellation Action (If not completed or in progress)
            if (booking.status == BookingStatus.pendingAssignment ||
                booking.status == BookingStatus.driverAssigned ||
                booking.status == BookingStatus.driverAccepted) ...[
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel_outlined, color: AppColors.statusCancelled),
                label: const Text('Cancel Booking Request', style: TextStyle(color: AppColors.statusCancelled)),
                onPressed: () => _confirmCancellation(context, bookingService),
              ),
            ],

            if (booking.status == BookingStatus.completed) ...[
              CustomButton(
                text: 'Done & Return to Home',
                onPressed: () {
                  bookingService.clearActiveBooking();
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMilestoneTracker(BookingStatus currentStatus) {
    final steps = [
      {'title': 'Requested', 'status': BookingStatus.pendingAssignment},
      {'title': 'Assigned', 'status': BookingStatus.driverAssigned},
      {'title': 'Accepted', 'status': BookingStatus.driverAccepted},
      {'title': 'Arrived', 'status': BookingStatus.driverArrived},
      {'title': 'On Trip', 'status': BookingStatus.inProgress},
      {'title': 'Done', 'status': BookingStatus.completed},
    ];

    int currentIndex = _getStatusIndex(currentStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isPassed = index <= currentIndex;
          final isCurrent = index == currentIndex;

          return Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPassed ? AppColors.primary : Colors.grey.shade300,
                  border: isCurrent ? Border.all(color: AppColors.primaryLight, width: 2) : null,
                ),
                child: Center(
                  child: isPassed
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : Text('${index + 1}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[index]['title'] as String,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  int _getStatusIndex(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingAssignment:
        return 0;
      case BookingStatus.driverAssigned:
        return 1;
      case BookingStatus.driverAccepted:
        return 2;
      case BookingStatus.driverArrived:
        return 3;
      case BookingStatus.inProgress:
        return 4;
      case BookingStatus.completed:
        return 5;
      default:
        return 0;
    }
  }

  String _getStatusSubtitle(BookingModel booking) {
    switch (booking.status) {
      case BookingStatus.pendingAssignment:
        if (booking.autoDispatchExhausted) {
          return '⚠️ Automatic matching busy. Switched to Karimpur Admin Desk manual dispatch.';
        }
        return '🤖 Auto-matching nearest eligible TOTO captain in Karimpur...';
      case BookingStatus.driverAssigned:
        return 'Offering trip to Captain ${booking.driverName ?? "assigned"} (${booking.remainingOfferSeconds}s timer)';
      case BookingStatus.driverAccepted:
        return 'Captain accepted and is traveling to your pickup point.';
      case BookingStatus.driverArrived:
        return 'Captain has arrived at your pickup location!';
      case BookingStatus.inProgress:
        return 'Trip underway. Please enjoy your ride.';
      case BookingStatus.completed:
        return 'You have arrived. Please hand cash fare directly to the captain.';
      default:
        return '';
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
              color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmCancellation(BuildContext context, BookingService bookingService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No, Keep Ride')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusCancelled),
            onPressed: () {
              Navigator.pop(ctx);
              bookingService.cancelBookingByPassenger('Passenger requested cancellation');
            },
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
