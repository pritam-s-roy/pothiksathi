import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking_model.dart';
import '../../models/fare_model.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _completedToday = 5;
  double _todayEarnings = 260.0;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final bookingService = context.watch<BookingService>();
    final driver = authService.driverProfile;
    final isOnline = driver?.isOnline ?? false;

    // Check if there is an active booking assigned to this driver
    final liveBooking = bookingService.activeBooking;
    final isMyBooking = liveBooking != null &&
        (liveBooking.driverId == driver?.driverId ||
         (liveBooking.status == BookingStatus.driverAssigned && liveBooking.driverId == driver?.driverId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Captain Dashboard (চালক)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              '${driver?.vehicleNumber ?? 'TOTO'} • Karimpur Zone',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Availability Status Banner Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isOnline ? AppColors.accent : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOnline ? 'ONLINE (সক্রিয়)' : 'OFFLINE (নিষ্ক্রিয়)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isOnline ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              isOnline
                                  ? 'Automatic Dispatch matching active'
                                  : 'Turn online to receive booking offers',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        authService.toggleDriverOnline(val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Today's Performance & Earnings Summary
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Trips",
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_completedToday',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'Completed',
                            style: TextStyle(fontSize: 10, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's Fare",
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.formatCurrency(_todayEarnings),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                          const Text(
                            'Cash Collected',
                            style: TextStyle(fontSize: 10, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Active Assignment Section
            const Text(
              'Trip Assignment Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),

            if (!isOnline)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.power_settings_new, size: 36, color: AppColors.textLight),
                    SizedBox(height: 8),
                    Text(
                      'You are currently offline',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    Text(
                      'Switch online above to receive auto-dispatch ride requests from Karimpur commuters.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                  ],
                ),
              )
            else if (!isMyBooking)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.radar, size: 40, color: AppColors.primaryLight),
                    SizedBox(height: 10),
                    Text(
                      'Auto-Dispatch Radar Active',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Listening for nearby rides in Karimpur. You will receive an incoming alert with a 30-second acceptance countdown.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              // Live Offered / Active Trip Card
              _buildLiveTripCard(context, liveBooking, driver!, bookingService),

            const SizedBox(height: 24),

            // Driver Safety & Audit Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gavel_outlined, size: 16, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        'Operating Guidelines & Audit Policy',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '1. Confirmed fares cannot be altered without admin dispatch authorization.\n2. Always collect exact cash of ${Formatters.formatCurrency(10)} per shared passenger on verified local routes.\n3. Automatic dispatch offers have a 30s response window. Unanswered offers cascade to the next captain.',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTripCard(
    BuildContext context,
    BookingModel booking,
    dynamic driver,
    BookingService bookingService,
  ) {
    final isOfferedState = booking.status == BookingStatus.driverAssigned;
    final remainingSecs = booking.remainingOfferSeconds;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOfferedState ? const Color(0xFFEF6C00) : AppColors.primary,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Booking ID + Countdown Timer / Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.confirmation_number_outlined, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      booking.id,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                if (isOfferedState)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFB74D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, size: 14, color: Color(0xFFE65100)),
                        const SizedBox(width: 4),
                        Text(
                          '$remainingSecs s remaining',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  StatusBadge(status: booking.status.toDbString()),
              ],
            ),
            const Divider(height: 20),

            // 30s Progress Bar when in offered state
            if (isOfferedState) ...[
              LinearProgressIndicator(
                value: remainingSecs / 30.0,
                backgroundColor: const Color(0xFFFFE0B2),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
              ),
              const SizedBox(height: 14),
            ],

            // Route Details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Column(
                  children: [
                    Icon(Icons.radio_button_checked, size: 16, color: AppColors.primary),
                    SizedBox(height: 20, child: VerticalDivider(thickness: 2, color: AppColors.border)),
                    Icon(Icons.location_on, size: 16, color: Colors.red),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PICKUP: ${booking.originName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'DROP: ${booking.destinationName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Passenger & Fare specs
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Passenger', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text(
                        '${booking.passengerCount} person(s)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(height: 24, width: 1, color: AppColors.border),
                  Column(
                    children: [
                      const Text('Ride Type', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text(
                        booking.bookingType == BookingType.shared ? 'Shared (₹10/seat)' : 'Private Reserve',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(height: 24, width: 1, color: AppColors.border),
                  Column(
                    children: [
                      const Text('Agreed Fare', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      Text(
                        Formatters.formatCurrency(booking.fare),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Flow Buttons
            if (isOfferedState) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        bookingService.rejectDriverOffer(driver.driverId, 'Declined by captain');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Trip declined. Cascading to next candidate captain.'),
                            backgroundColor: AppColors.statusCancelled,
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.statusCancelled,
                        side: const BorderSide(color: AppColors.statusCancelled),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final ok = await bookingService.acceptDriverOffer(driver.driverId);
                        if (ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Trip Accepted! Head towards pickup location.'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Accept Trip'),
                    ),
                  ),
                ],
              ),
            ] else if (booking.status == BookingStatus.completed) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.primary, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      'Trip Completed! Collect ${Formatters.formatCurrency(booking.fare)} Cash',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              CustomButton(
                text: 'Dismiss & Ready for Next Assignment',
                onPressed: () {
                  setState(() {
                    _todayEarnings += booking.fare;
                    _completedToday += 1;
                  });
                  bookingService.clearActiveBooking();
                },
              ),
            ] else ...[
              CustomButton(
                text: _getStepActionText(booking.status),
                icon: _getStepActionIcon(booking.status),
                onPressed: () {
                  final nextStatus = _getNextTripStatus(booking.status);
                  if (nextStatus != null) {
                    bookingService.advanceDriverStatus(nextStatus);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  BookingStatus? _getNextTripStatus(BookingStatus current) {
    switch (current) {
      case BookingStatus.driverAccepted:
        return BookingStatus.driverArrived;
      case BookingStatus.driverArrived:
        return BookingStatus.inProgress;
      case BookingStatus.inProgress:
        return BookingStatus.completed;
      default:
        return null;
    }
  }

  String _getStepActionText(BookingStatus status) {
    switch (status) {
      case BookingStatus.driverAccepted:
        return 'Mark As Arrived at Pickup Point';
      case BookingStatus.driverArrived:
        return 'Confirm Passenger Picked Up & Start Trip';
      case BookingStatus.inProgress:
        return 'Mark Trip Completed (Collect Cash)';
      default:
        return 'Update Trip Status';
    }
  }

  IconData _getStepActionIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.driverAccepted:
        return Icons.pin_drop_outlined;
      case BookingStatus.driverArrived:
        return Icons.group_add_outlined;
      case BookingStatus.inProgress:
        return Icons.task_alt_outlined;
      default:
        return Icons.arrow_forward;
    }
  }
}
