import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'core/routes/app_routes.dart';
import 'core/services/auth_service.dart';
import 'core/services/booking_service.dart';
import 'core/services/timetable_service.dart';
import 'core/theme/app_theme.dart';
import 'presentation/auth/driver_pending_screen.dart';
import 'presentation/auth/login_screen.dart';
import 'presentation/auth/register_screen.dart';
import 'presentation/driver/driver_home_screen.dart';
import 'presentation/passenger/booking_flow_screen.dart';
import 'presentation/passenger/passenger_home_screen.dart';
import 'presentation/passenger/passenger_trip_status_screen.dart';
import 'presentation/timetable/timetable_search_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const PothikSathiApp());
}

class PothikSathiApp extends StatelessWidget {
  const PothikSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BookingService()),
        ChangeNotifierProvider(create: (_) => TimetableService()),
      ],
      child: MaterialApp(
        title: 'PothikSathi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AuthGate(),
        routes: {
          AppRoutes.login: (_) => const LoginScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.passengerHome: (_) => const PassengerHomeScreen(),
          AppRoutes.passengerBooking: (_) => const BookingFlowScreen(),
          AppRoutes.passengerTripStatus: (_) => const PassengerTripStatusScreen(),
          AppRoutes.driverDashboard: (_) => const DriverHomeScreen(),
          AppRoutes.driverPending: (_) => const DriverPendingScreen(),
          AppRoutes.timetableSearch: (_) => const TimetableSearchScreen(),
        },
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    // 1. Loading Splash
    if (authService.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.electric_rickshaw,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PothikSathi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'করিমপুর স্থানীয় যাতায়াত সাথী',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Unauthenticated: Direct to Login
    if (!authService.isAuthenticated) {
      return const LoginScreen();
    }

    // 3. Driver Role: Check Approval Guard
    if (authService.isDriver) {
      if (authService.isDriverApproved) {
        return const DriverHomeScreen();
      } else {
        return const DriverPendingScreen();
      }
    }

    // 4. Default: Passenger Home
    return const PassengerHomeScreen();
  }
}
