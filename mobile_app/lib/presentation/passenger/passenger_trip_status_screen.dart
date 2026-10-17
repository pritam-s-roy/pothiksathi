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
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Trip Status')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, size: 36, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Active Trip',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'You currently have no ongoing TOTO bookings.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Back to Home',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                booking.id,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: StatusBadge(status: booking.status.toDbString(), label: booking.status.displayName),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Hero Card
            _buildStatusHeroCard(booking),
            const SizedBox(height: 16),

            // Driver Card (when assigned)
            if (booking.driverName != null) ...[
              _buildCaptainCard(context, booking),
              const SizedBox(height: 16),
            ],

            // Route Details Card
            _buildRouteDetailsCard(booking),
            const SizedBox(height: 16),

            // Fare Summary Card
            _buildFareCard(booking),
            const SizedBox(height: 24),

            // Cancel Booking Button (if allowed by state machine)
            if (booking.status.isPending || booking.status == BookingStatus.driverAssigned || booking.status == BookingStatus.driverAccepted)
              OutlinedButton(
                onPressed: () => _handleCancel(context, bookingService, booking.id),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusCancelled,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text(
                  'Cancel Ride (যাত্রা বাতিল করুন)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeroCard(BookingModel booking) {
    IconData heroIcon;
    String title;
    String subtitle;
    bool isSearching = booking.status.isPending || booking.status == BookingStatus.driverAssigned;

    if (booking.status.isPending) {
      heroIcon = Icons.radar;
      title = 'Looking for Nearby Captains...';
      subtitle = 'PothikSathi is matching your ride with online Karimpur TOTO drivers.';
    } else if (booking.status == BookingStatus.driverAssigned) {
      heroIcon = Icons.hourglass_top;
      title = 'Captain Offer Pending';
      subtitle = 'Offered to nearby captain with 30s acceptance window.';
    } else if (booking.status == BookingStatus.driverAccepted) {
      heroIcon = Icons.electric_rickshaw;
      title = 'Captain is On the Way!';
      subtitle = '${booking.driverName ?? "Captain"} accepted your ride and is heading to pickup.';
    } else if (booking.status == BookingStatus.driverArrived) {
      heroIcon = Icons.location_on;
      title = 'Captain has Arrived';
      subtitle = 'Your TOTO is waiting at ${booking.originName}. Please board.';
    } else if (booking.status == BookingStatus.inProgress) {
      heroIcon = Icons.directions;
      title = 'Trip in Progress';
      subtitle = 'Heading towards ${booking.destinationName}. Enjoy your journey!';
    } else {
      heroIcon = Icons.check_circle;
      title = booking.status.displayName;
      subtitle = 'Trip completed. Pay cash to driver.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
            decoration: BoxDecoration(
              color: isSearching ? AppColors.brandLimeTint : AppColors.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(heroIcon, size: 30, color: AppColors.brandBlack),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptainCard(BuildContext context, BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.brandBlack,
            child: const Icon(Icons.electric_rickshaw, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      booking.driverName ?? 'Captain',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.brandLimeTint,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 10, color: AppColors.brandBlack),
                          SizedBox(width: 2),
                          Text('4.9', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  booking.vehicleNumber ?? 'Karimpur Verified TOTO',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Call Button
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling Captain at ${booking.driverPhone ?? "..."}')),
              );
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.brandLime,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone, color: AppColors.brandBlack, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetailsCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route Details',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.brandLimeDark, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Point', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                    Text(booking.originName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 3.5),
            child: Container(width: 1, height: 16, color: AppColors.border),
          ),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.brandBlack, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destination', style: TextStyle(fontSize: 10, color: AppColors.textLight)),
                    Text(booking.destinationName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFareCard(BookingModel booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fare to Collect (নগদ ভাড়া)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(
                booking.bookingType.name == 'shared'
                    ? 'Shared TOTO (${booking.passengerCount} seat)'
                    : 'Private Reserve',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            Formatters.formatCurrency(booking.totalFare),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  void _handleCancel(BuildContext context, BookingService bookingService, String bookingId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Ride?'),
        content: const Text('Are you sure you want to cancel this booking request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No, Keep Ride'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCancelled,
              minimumSize: const Size(100, 40),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await bookingService.cancelBooking(bookingId, 'Cancelled by passenger');
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
