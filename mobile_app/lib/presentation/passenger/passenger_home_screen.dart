import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/karimpur_locations.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/booking_model.dart';
import '../widgets/status_badge.dart';
import 'booking_flow_screen.dart';
import 'passenger_trip_status_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;
  final VoidCallback? onOpenBooking;
  final VoidCallback? onOpenTimetable;

  const PassengerHomeScreen({
    super.key,
    this.onNavigateTab,
    this.onOpenBooking,
    this.onOpenTimetable,
  });

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _currentBottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 14, color: AppColors.textPrimary),
                  SizedBox(width: 5),
                  Text(
                    'Karimpur, Nadia',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, size: 22),
            tooltip: 'Alerts',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Karimpur local routes running on fixed ₹10 tariff.')),
              );
            },
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.brandBlack,
              child: Text(
                user?.name?.isNotEmpty == true ? user!.name![0].toUpperCase() : 'P',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            tooltip: 'Profile',
            onPressed: () => _showUserMenu(context, authService),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildCurrentTab(user, authService),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          selectedItemColor: AppColors.brandBlack,
          unselectedItemColor: AppColors.textLight,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: (index) {
            setState(() => _currentBottomNavIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_filled),
              label: 'Ride',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'My Trips',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab(dynamic user, AuthService authService) {
    switch (_currentBottomNavIndex) {
      case 1:
        return _buildTripsHistoryView();
      case 2:
        return _buildProfileView(user, authService);
      case 0:
      default:
        return _buildHomeView(user);
    }
  }

  Widget _buildHomeView(dynamic user) {
    final bookingService = context.watch<BookingService>();
    final activeBooking = bookingService.activeBooking;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Active Live Booking Banner (if ongoing)
            if (activeBooking != null) ...[
              _buildActiveTripBanner(activeBooking),
              const SizedBox(height: 16),
            ],

            // inDrive "Where to?" Search Card
            _buildWhereToCard(),
            const SizedBox(height: 20),

            // Services Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose Ride Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Zero Surge Pricing',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Service 1: Shared TOTO (Hero Card)
            _buildServiceCard(
              title: 'Shared TOTO',
              bengaliTitle: 'শেয়ার টোটো',
              subtitle: '₹10 per passenger on designated local Karimpur routes.',
              priceTag: '₹10 / seat',
              isLimeTag: true,
              icon: Icons.electric_rickshaw,
              onTap: () {
                if (widget.onOpenBooking != null) {
                  widget.onOpenBooking!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookingFlowScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),

            // Service 2: Private Reserve
            _buildServiceCard(
              title: 'Private Reserve',
              bengaliTitle: 'রিজার্ভ টোটো',
              subtitle: 'Entire 4-seater e-rickshaw for family & personal trips.',
              priceTag: 'From ₹20',
              isLimeTag: false,
              icon: Icons.local_taxi,
              onTap: () {
                if (widget.onOpenBooking != null) {
                  widget.onOpenBooking!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BookingFlowScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),

            // Service 3: Bus Timetables
            _buildServiceCard(
              title: 'Bus Schedules',
              bengaliTitle: 'বাস সময়সূচী',
              subtitle: 'Krishnanagar, Berhampore, Esplanade & Malda routes.',
              priceTag: 'Offline Ready',
              isLimeTag: false,
              icon: Icons.directions_bus_outlined,
              onTap: () {
                if (widget.onOpenTimetable != null) {
                  widget.onOpenTimetable!();
                } else {
                  Navigator.pushNamed(context, '/timetable/search');
                }
              },
            ),
            const SizedBox(height: 20),

            // Verified Tariff Guarantee Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.brandLimeTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user, color: AppColors.brandBlack, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verified Karimpur Municipal Tariffs',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'No bargaining or hidden fees. All fares strictly governed by local authority standards.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                        ),
                      ],
                    ),
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

  Widget _buildActiveTripBanner(BookingModel booking) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PassengerTripStatusScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.brandBlack,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.brandLime,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        booking.status.displayName,
                        style: const TextStyle(
                          color: AppColors.brandLime,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${Formatters.formatCurrency(booking.totalFare)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'To: ${booking.destinationName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: AppColors.brandLime, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildWhereToCard() {
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
          // Search box trigger
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingFlowScreen()),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 20, color: AppColors.textPrimary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Where to? (কোথায় যাবেন?)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 18, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Quick Destination Chips
          const Text(
            'Popular Karimpur Hubs',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickDestinationChip('Pannadevi College', Icons.school_outlined),
                _buildQuickDestinationChip('Rural Hospital', Icons.local_hospital_outlined),
                _buildQuickDestinationChip('Regulated Market', Icons.storefront_outlined),
                _buildQuickDestinationChip('Shikarpur Ghat', Icons.directions_boat_outlined),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDestinationChip(String destination, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BookingFlowScreen(initialDestination: destination),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surfaceSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.textPrimary),
              const SizedBox(width: 6),
              Text(
                destination,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String bengaliTitle,
    required String subtitle,
    required String priceTag,
    required bool isLimeTag,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLimeTag ? AppColors.brandLimeTint : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 26, color: AppColors.brandBlack),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($bengaliTitle)',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLimeTag ? AppColors.brandLime : AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                priceTag,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isLimeTag ? AppColors.brandBlack : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsHistoryView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My Trips History (আমার যাত্রা)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
          const SizedBox(height: 12),
          _buildPastTripCard(
            origin: 'Karimpur Bus Stand',
            destination: 'Karimpur Pannadevi College',
            date: 'Today, 10:15 AM',
            fare: 10.0,
            type: 'Shared TOTO',
            status: 'completed',
          ),
          const SizedBox(height: 10),
          _buildPastTripCard(
            origin: 'Karimpur Bus Stand',
            destination: 'Karimpur Rural Hospital',
            date: 'Yesterday, 04:30 PM',
            fare: 20.0,
            type: 'Private Reserve',
            status: 'completed',
          ),
        ],
      ),
    );
  }

  Widget _buildPastTripCard({
    required String origin,
    required String destination,
    required String date,
    required double fare,
    required String type,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: AppColors.brandBlack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(origin, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: 3),
            child: SizedBox(height: 12, child: VerticalDivider(thickness: 1.5, color: AppColors.border)),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 10, color: AppColors.brandBlack),
              const SizedBox(width: 8),
              Expanded(
                child: Text(destination, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(type, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text(
                Formatters.formatCurrency(fare),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView(dynamic user, AuthService authService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.brandBlack,
                  child: Text(
                    user?.name?.isNotEmpty == true ? user!.name![0].toUpperCase() : 'P',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Passenger',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  user?.phoneNumber ?? '+91 98765 43210',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline, color: AppColors.brandBlack),
                  title: const Text('Helpline & Support', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Karimpur Transport Support: +91 3471 255 100')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.statusCancelled),
                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.statusCancelled)),
                  onTap: () => authService.signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserMenu(BuildContext context, AuthService authService) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.statusCancelled),
                  title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    authService.signOut();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
