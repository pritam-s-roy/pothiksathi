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
import '../widgets/status_badge.dart';
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
      _selectedDestination = widget.initialDestination!;
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
          perPassengerRate: 0,
          baseVehicleRate: 0,
          minimumFareThreshold: 20,
          finalTotalFare: 0,
          isTariffVerified: false,
          calculatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _submitBooking() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final bookingService = Provider.of<BookingService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a booking.')),
      );
      return;
    }

    final route = _findMatchingRoute();
    if (route == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected route has no verified tariff. Please select a verified Karimpur hub.')),
      );
      return;
    }

    final fareResult = _calculateCurrentFare();
    if (!fareResult.isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fareResult.unverifiedReason ?? 'Cannot verify fare.')),
      );
      return;
    }

    // Idempotency token generation: prevents double booking on rapid taps
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
      appBar: AppBar(
        title: const Text('Book TOTO (টোটো বুকিং)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Origin and Destination Selector Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pickup & Destination (যাত্রা শুরু ও গন্তব্য)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 14),

                    // Origin dropdown
                    Row(
                      children: [
                        const Icon(Icons.radio_button_checked, size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedOrigin,
                            decoration: const InputDecoration(
                              labelText: 'Pickup Location',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: KarimpurLocations.verifiedHubs.map((hub) {
                              return DropdownMenuItem<String>(
                                value: hub['name'] as String,
                                child: Text(hub['name'] as String, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedOrigin = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        height: 18,
                        child: VerticalDivider(thickness: 2, color: AppColors.border),
                      ),
                    ),

                    // Destination dropdown
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 18, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedDestination,
                            decoration: const InputDecoration(
                              labelText: 'Drop Location',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: KarimpurLocations.verifiedHubs.map((hub) {
                              return DropdownMenuItem<String>(
                                value: hub['name'] as String,
                                child: Text(hub['name'] as String, style: const TextStyle(fontSize: 13)),
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
                      Row(
                        children: [
                          const Icon(Icons.route, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Estimated distance: ${Formatters.formatDistance(route.distanceKm)} (~${route.estimatedMinutes} mins)',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Booking Type Toggle (Shared vs Private)
            const Text(
              'Select Ride Type (রাইডের ধরন)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBookingType = BookingType.shared),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedBookingType == BookingType.shared
                            ? AppColors.primaryTint
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedBookingType == BookingType.shared
                              ? AppColors.primary
                              : AppColors.border,
                          width: _selectedBookingType == BookingType.shared ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Shared TOTO',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _selectedBookingType == BookingType.shared
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const StatusBadge(status: '₹10/seat', label: '₹10'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pay per seat on designated local routes.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedBookingType = BookingType.private),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedBookingType == BookingType.private
                            ? AppColors.primaryTint
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedBookingType == BookingType.private
                              ? AppColors.primary
                              : AppColors.border,
                          width: _selectedBookingType == BookingType.private ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Private Reserve',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _selectedBookingType == BookingType.private
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const StatusBadge(status: 'Min ₹20', label: 'Min ₹20'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Entire vehicle price. Direct point-to-point drop.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Passenger Count Selector (Subject to vehicle capacity of 4)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Passengers (যাত্রী সংখ্যা)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          _selectedBookingType == BookingType.shared
                              ? '₹${fareResult.baseRate.toInt()}/passenger × $_passengerCount'
                              : 'Up to max 4 passengers in vehicle',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: _passengerCount > 1 ? AppColors.primary : Colors.grey,
                          onPressed: _passengerCount > 1
                              ? () => setState(() => _passengerCount--)
                              : null,
                        ),
                        Text(
                          '$_passengerCount',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          color: _passengerCount < 4 ? AppColors.primary : Colors.grey,
                          onPressed: _passengerCount < 4
                              ? () => setState(() => _passengerCount++)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. Fare Estimate & Snapshot Breakdown Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Agreed Fare',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        Formatters.formatCurrency(fareResult.totalFare),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedBookingType == BookingType.shared
                            ? 'Shared Fare (₹${fareResult.baseRate.toInt()} × $_passengerCount seat)'
                            : 'Private Vehicle Reserve Fare',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        Formatters.formatCurrency(fareResult.totalFare),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Surge / Traffic Charges', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('₹0 (Never applied)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment Mode', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      Text('Cash directly to Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Submit Booking Button
            CustomButton(
              text: 'Confirm & Request Driver (বুকিং নিশ্চিত করুন)',
              isLoading: bookingService.isSubmitting,
              icon: Icons.electric_rickshaw,
              onPressed: _submitBooking,
            ),
          ],
        ),
      ),
    );
  }
}
