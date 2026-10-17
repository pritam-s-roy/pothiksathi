import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/karimpur_locations.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/booking_service.dart';
import '../../core/utils/formatters.dart';
import '../../domain/fare_calculator.dart';
import '../../models/fare_model.dart';
import '../../models/route_model.dart';
import '../widgets/custom_button.dart';
import 'passenger_trip_status_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  final String? initialDestination;

  const BookingFlowScreen({super.key, this.initialDestination});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  String _selectedOrigin = 'Karimpur Bus Stand';
  String _selectedDestination = 'Karimpur Pannadevi College';
  BookingType _selectedBookingType = BookingType.shared;
  int _passengerCount = 1;

  late List<RouteModel> _availableRoutes;
  late List<RouteFareModel> _availableFares;

  @override
  void initState() {
    super.initState();
    if (widget.initialDestination != null) {
      // Find matching verified hub
      for (final hub in KarimpurLocations.verifiedHubs) {
        final hubName = hub['name'] as String;
        if (hubName.toLowerCase().contains(widget.initialDestination!.toLowerCase())) {
          _selectedDestination = hubName;
          break;
        }
      }
    }
    _initKarimpurRoutes();
  }

  void _initKarimpurRoutes() {
    _availableRoutes = [
      const RouteModel(
        id: 'krm_route_01',
        name: 'Karimpur Bus Stand ↔ Pannadevi College',
        origin: 'Karimpur Bus Stand',
        destination: 'Karimpur Pannadevi College',
        distanceKm: 1.8,
        estimatedMinutes: 8,
      ),
      const RouteModel(
        id: 'krm_route_02',
        name: 'Karimpur Bus Stand ↔ Rural Hospital',
        origin: 'Karimpur Bus Stand',
        destination: 'Karimpur Rural Hospital',
        distanceKm: 1.2,
        estimatedMinutes: 6,
      ),
      const RouteModel(
        id: 'krm_route_03',
        name: 'Karimpur Bus Stand ↔ Regulated Market (Nizampur)',
        origin: 'Karimpur Bus Stand',
        destination: 'Karimpur Regulated Market (Nizampur)',
        distanceKm: 1.0,
        estimatedMinutes: 5,
      ),
      const RouteModel(
        id: 'krm_route_04',
        name: 'Karimpur Bus Stand ↔ Shikarpur Ghat',
        origin: 'Karimpur Bus Stand',
        destination: 'Shikarpur Ghat / More',
        distanceKm: 7.5,
        estimatedMinutes: 22,
      ),
      const RouteModel(
        id: 'krm_route_05',
        name: 'Karimpur Bus Stand ↔ Jamserpur More',
        origin: 'Karimpur Bus Stand',
        destination: 'Jamserpur More',
        distanceKm: 3.2,
        estimatedMinutes: 12,
      ),
    ];

    _availableFares = [
      const RouteFareModel(
        routeId: 'krm_route_01',
        sharedFarePerPassenger: 10.0,
        privateBaseFare: 25.0,
        minimumFare: 20.0,
      ),
      const RouteFareModel(
        routeId: 'krm_route_02',
        sharedFarePerPassenger: 10.0,
        privateBaseFare: 20.0,
        minimumFare: 20.0,
      ),
      const RouteFareModel(
        routeId: 'krm_route_03',
        sharedFarePerPassenger: 10.0,
        privateBaseFare: 20.0,
        minimumFare: 20.0,
      ),
      const RouteFareModel(
        routeId: 'krm_route_04',
        sharedFarePerPassenger: 20.0,
        privateBaseFare: 80.0,
        minimumFare: 20.0,
      ),
      const RouteFareModel(
        routeId: 'krm_route_05',
        sharedFarePerPassenger: 15.0,
        privateBaseFare: 40.0,
        minimumFare: 20.0,
      ),
    ];
  }

  RouteModel? _findMatchingRoute() {
    for (final r in _availableRoutes) {
      if (r.matches(_selectedOrigin, _selectedDestination)) {
        return r;
      }
    }
    return null;
  }

  RouteFareModel? _findMatchingTariff(String? routeId) {
    if (routeId == null) return null;
    for (final f in _availableFares) {
      if (f.routeId == routeId) return f;
    }
    return null;
  }

  FareCalculationResult _calculateCurrentFare() {
    final route = _findMatchingRoute();
    final tariff = _findMatchingTariff(route?.id);

    try {
      return FareCalculator.calculate(
        bookingType: _selectedBookingType,
        passengerCount: _passengerCount,
        route: route,
        tariff: tariff,
      );
    } catch (e) {
      return FareCalculationResult(
        totalFare: 0,
        baseRate: 0,
        passengerCount: _passengerCount,
        bookingType: _selectedBookingType,
        isVerified: false,
        unverifiedReason: e.toString(),
        snapshot: FareSnapshot(
          tariffVersion: 'INVALID',
          bookingType: _selectedBookingType,
          passengerCount: _passengerCount,
          perPassengerRate: 0.0,
          baseVehicleRate: 0.0,
          minimumFareThreshold: 20.0,
          finalTotalFare: 0.0,
          isTariffVerified: false,
          calculatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _handleBookRide() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = Provider.of<BookingService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book a ride.')),
      );
      return;
    }

    final route = _findMatchingRoute();
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected route is not currently available for dispatch.')),
      );
      return;
    }

    final fareResult = _calculateCurrentFare();
    if (!fareResult.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fareResult.unverifiedReason ?? 'Cannot verify route fare.')),
      );
      return;
    }

    final idempotencyKey = '${user.id}_${route.id}_${DateTime.now().millisecondsSinceEpoch ~/ 5000}';

    final booking = await bookingService.createBooking(
      passenger: user,
      route: route,
      bookingType: _selectedBookingType,
      passengerCount: _passengerCount,
      fare: fareResult.totalFare,
      snapshot: fareResult.snapshot,
      idempotencyKey: idempotencyKey,
    );

    if (booking != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PassengerTripStatusScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fareResult = _calculateCurrentFare();
    final bookingService = context.watch<BookingService>();
    final route = _findMatchingRoute();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Ride (টোটো বুকিং)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // inDrive Route Card (Pickup -> Destination)
            _buildRouteCard(route),
            const SizedBox(height: 16),

            // inDrive Ride Type Selector (Shared vs Private)
            const Text(
              'Select Ride Type',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildRideTypeCard(
                    title: 'Shared TOTO',
                    bengali: 'শেয়ার',
                    priceText: '₹10 / seat',
                    subtitle: 'Fixed route seat',
                    type: BookingType.shared,
                    icon: Icons.electric_rickshaw,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildRideTypeCard(
                    title: 'Private Reserve',
                    bengali: 'রিজার্ভ',
                    priceText: 'From ₹20',
                    subtitle: 'Entire 4-seater',
                    type: BookingType.private,
                    icon: Icons.local_taxi,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Passenger Seat Count Stepper (if shared or multi-passenger)
            _buildPassengerCountCard(),
            const SizedBox(height: 16),

            // inDrive Fare Breakdown Card
            _buildFareSummaryCard(fareResult),
            const SizedBox(height: 24),

            // Find Captain Button (inDrive style full-width button)
            CustomButton(
              text: fareResult.isVerified
                  ? 'Find a Captain • ${Formatters.formatCurrency(fareResult.totalFare)}'
                  : 'Route Unavailable',
              isLime: fareResult.isVerified,
              isLoading: bookingService.isLoading,
              onPressed: fareResult.isVerified && !bookingService.isLoading
                  ? _handleBookRide
                  : null,
            ),
            const SizedBox(height: 14),

            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 12, color: AppColors.textSecondary),
                  SizedBox(width: 4),
                  Text(
                    'Cash payment to driver • 100% verified tariff',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(RouteModel? route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Origin input
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.brandLimeDark,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedOrigin,
                  decoration: const InputDecoration(
                    labelText: 'Pickup Point (যাত্রা শুরু)',
                    labelStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: KarimpurLocations.verifiedHubs.map((hub) {
                    return DropdownMenuItem<String>(
                      value: hub['name'] as String,
                      child: Text(
                        hub['name'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedOrigin = val);
                  },
                ),
              ),
            ],
          ),

          // Connector line
          Padding(
            padding: const EdgeInsets.only(left: 4.5),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 1,
                height: 16,
                color: AppColors.border,
              ),
            ),
          ),

          // Destination input
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.brandBlack,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDestination,
                  decoration: const InputDecoration(
                    labelText: 'Destination (গন্তব্য)',
                    labelStyle: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: KarimpurLocations.verifiedHubs.map((hub) {
                    return DropdownMenuItem<String>(
                      value: hub['name'] as String,
                      child: Text(
                        hub['name'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDestination = val);
                  },
                ),
              ),
            ],
          ),

          if (route != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.straighten, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    '${Formatters.formatDistance(route.distanceKm)} • ~${route.estimatedMinutes} mins drive',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRideTypeCard({
    required String title,
    required String bengali,
    required String priceText,
    required String subtitle,
    required BookingType type,
    required IconData icon,
  }) {
    final isSelected = _selectedBookingType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedBookingType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.brandBlack : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: isSelected ? AppColors.brandBlack : AppColors.textSecondary,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.brandLime : AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priceText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? AppColors.brandBlack : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCountCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Passengers (যাত্রী সংখ্যা)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                'Max 4 seats per TOTO',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          Row(
            children: [
              _buildStepperButton(
                icon: Icons.remove,
                onTap: _passengerCount > 1
                    ? () => setState(() => _passengerCount--)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  '$_passengerCount',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              _buildStepperButton(
                icon: Icons.add,
                onTap: _passengerCount < 4
                    ? () => setState(() => _passengerCount++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.surfaceSubtle : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppColors.textPrimary : AppColors.textLight,
        ),
      ),
    );
  }

  Widget _buildFareSummaryCard(FareCalculationResult fareResult) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Verified Fare',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    _selectedBookingType == BookingType.shared
                        ? '$_passengerCount × ₹10.00'
                        : 'Whole vehicle fare',
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                  ),
                ],
              ),
              Text(
                Formatters.formatCurrency(fareResult.totalFare),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          const Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: AppColors.statusAccepted),
              SizedBox(width: 6),
              Text(
                'Guaranteed standard fare. Zero surge pricing.',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
