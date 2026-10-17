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
  final int _completedToday = 5;
  final double _todayEarnings = 260.0;

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Captain Dashboard',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3),
            ),
            Text(
              '${driver?.vehicleNumber ?? "TOTO"} • Karimpur Zone',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20, color: AppColors.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Online / Offline Status Toggle Card (inDrive style)
            _buildStatusToggleCard(isOnline, authService),
            const SizedBox(height: 14),

            // Performance & Today's Earnings Summary
            _buildEarningsRow(),
            const SizedBox(height: 16),

            // Main Content Area: Offline State / Active Radar / Live Trip Offer
            if (!isOnline)
              _buildOfflineCard()
            else if (!isMyBooking)
              _buildRadarActiveCard()
            else
              _buildLiveTripCard(context, liveBooking, driver!, bookingService),

            const SizedBox(height: 16),

            // Driver Safety & Guidelines Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 16, color: AppColors.brandBlack),
                      SizedBox(width: 6),
                      Text(
                        'Karimpur Operating Rules',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Collect verified cash fare of ₹10 per shared passenger.\n• 30-second offer acceptance timer. Unaccepted offers cascade automatically.\n• Zero surge pricing enforced on all local routes.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggleCard(bool isOnline, AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnline ? AppColors.brandBlack : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOnline ? AppColors.brandBlack : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppColors.brandLime : AppColors.textLight,
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
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: isOnline ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isOnline ? 'Receiving auto-dispatch rides' : 'Go online to get trip offers',
                    style: TextStyle(
                      fontSize: 11,
                      color: isOnline ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: isOnline,
            activeColor: AppColors.brandLime,
            activeTrackColor: const Color(0xFF2E3320),
            inactiveThumbColor: AppColors.textLight,
            inactiveTrackColor: AppColors.surfaceSubtle,
            onChanged: (val) {
              authService.toggleDriverOnline(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Today's Earnings", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(_todayEarnings),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Completed Trips", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  '$_completedToday',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.power_settings_new, size: 36, color: AppColors.textLight),
          SizedBox(height: 10),
          Text(
            'You are currently offline',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          SizedBox(height: 4),
          Text(
            'Switch online above to begin receiving automatic dispatch offers from Karimpur passengers.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarActiveCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppColors.brandLimeTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.radar, size: 32, color: AppColors.brandBlack),
          ),
          const SizedBox(height: 12),
          const Text(
            'Radar Active • Searching Rides',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          const Text(
            'Listening for nearby rides in Karimpur. New offers will appear with an instant 30-second acceptance timer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOfferedState ? AppColors.brandLimeDark : AppColors.brandBlack,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Header: Booking ID + Countdown Timer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.id,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textSecondary),
              ),
              if (isOfferedState)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandLimeTint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: AppColors.brandBlack),
                      const SizedBox(width: 4),
                      Text(
                        '${remainingSecs}s left',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.brandBlack),
                      ),
                    ],
                  ),
                )
              else
                StatusBadge(status: booking.status.toDbString()),
            ],
          ),
          const SizedBox(height: 14),

          // Big inDrive Fare Display
          Center(
            child: Column(
              children: [
                Text(
                  Formatters.formatCurrency(booking.totalFare),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  booking.bookingType == BookingType.shared
                      ? 'Shared TOTO (${booking.passengerCount} Seat)'
                      : 'Private Reserve Ride',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 30s Countdown Progress Indicator
          if (isOfferedState) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (remainingSecs / 30.0).clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceSubtle,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandLime),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Route Details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSubtle,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.brandLimeDark, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'PICKUP: ${booking.originName}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 3.5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(width: 1, height: 14, color: AppColors.border),
                  ),
                ),
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.brandBlack, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'DROP: ${booking.destinationName}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons:
          // In Offered state: Decline (Grey) / Accept (Lime)
          if (isOfferedState)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () async {
                      await bookingService.rejectOffer(booking.id, driver.driverId);
                    },
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandLime,
                      foregroundColor: AppColors.brandBlack,
                      minimumSize: const Size(double.infinity, 50),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    onPressed: () async {
                      await bookingService.acceptOffer(booking.id, driver.driverId);
                    },
                    child: const Text('Accept Offer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            )
          else ...[
            // In Progress Trip State Stepper Actions
            if (booking.status == BookingStatus.driverAccepted)
              CustomButton(
                text: 'Captain Arrived at Pickup (পৌঁছে গেছি)',
                isLime: true,
                onPressed: () => bookingService.markDriverArrived(booking.id),
              ),
            if (booking.status == BookingStatus.driverArrived)
              CustomButton(
                text: 'Start Trip (যাত্রা শুরু করুন)',
                isLime: true,
                onPressed: () => bookingService.startTrip(booking.id),
              ),
            if (booking.status == BookingStatus.inProgress)
              CustomButton(
                text: 'Complete & Collect ${Formatters.formatCurrency(booking.totalFare)}',
                isLime: true,
                onPressed: () => bookingService.completeTrip(booking.id),
              ),
          ],
        ],
      ),
    );
  }
}
