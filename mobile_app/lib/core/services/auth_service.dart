import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import '../../models/driver_profile_model.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  DriverProfileModel? _driverProfile;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  DriverProfileModel? get driverProfile => _driverProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  bool get isPassenger => _currentUser?.role == UserRole.passenger;
  bool get isDriver => _currentUser?.role == UserRole.driver;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  bool get isDriverApproved =>
      _driverProfile?.approvalStatus == DriverApprovalStatus.approved;

  AuthService() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userMap = await StorageService.getUser();
      if (userMap != null) {
        _currentUser = UserModel.fromMap(userMap);
        if (_currentUser?.role == UserRole.driver) {
          final profileMap = await StorageService.getDriverProfile();
          if (profileMap != null) {
            _driverProfile = DriverProfileModel.fromMap(profileMap);
          } else {
            // Default pending profile for local storage safety
            _driverProfile = DriverProfileModel(
              driverId: _currentUser!.id,
              vehicleNumber: 'WB-52-TOTO-SAMPLE',
              approvalStatus: DriverApprovalStatus.pending,
              isOnline: false,
              updatedAt: DateTime.now(),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with phone/email and role
  Future<bool> signIn({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate fast network verification / Firebase Auth
      await Future.delayed(const Duration(milliseconds: 300));

      final cleanId = identifier.trim().toLowerCase();

      // Demo/pre-configured profiles for local MVP testing
      if (cleanId.contains('driver') || cleanId.startsWith('98000')) {
        // Driver account
        final user = UserModel(
          id: 'driver_karimpur_01',
          name: 'Bapi Mondal (বাপ্পি মণ্ডল)',
          phoneNumber: identifier.trim(),
          email: 'bapi.driver@pothiksathi.local',
          role: UserRole.driver,
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        );

        final driver = DriverProfileModel(
          driverId: user.id,
          vehicleNumber: 'WB-52-TOTO-8812',
          licenseOrId: 'AADHAAR-8921-XXXX',
          approvalStatus: DriverApprovalStatus.approved,
          isOnline: true,
          totalTrips: 42,
          rating: 4.9,
          approvedBy: 'admin_karimpur',
          approvedAt: DateTime.now().subtract(const Duration(days: 25)),
          updatedAt: DateTime.now(),
        );

        _currentUser = user;
        _driverProfile = driver;
        await StorageService.saveUser(user.toMap());
        await StorageService.saveDriverProfile(driver.toMap());
      } else if (cleanId.contains('pending')) {
        // Unapproved driver for testing security guard
        final user = UserModel(
          id: 'driver_pending_02',
          name: 'Ratan Das (রতন দাস)',
          phoneNumber: identifier.trim(),
          email: 'ratan.driver@pothiksathi.local',
          role: UserRole.driver,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final driver = DriverProfileModel(
          driverId: user.id,
          vehicleNumber: 'WB-52-TOTO-4120',
          licenseOrId: 'AADHAAR-3112-XXXX',
          approvalStatus: DriverApprovalStatus.pending,
          isOnline: false,
          totalTrips: 0,
          rating: 5.0,
          updatedAt: DateTime.now(),
        );

        _currentUser = user;
        _driverProfile = driver;
        await StorageService.saveUser(user.toMap());
        await StorageService.saveDriverProfile(driver.toMap());
      } else {
        // Default Passenger account
        final user = UserModel(
          id: 'passenger_karimpur_01',
          name: 'Sourav Biswas (সৌরভ বিশ্বাস)',
          phoneNumber: identifier.trim().isNotEmpty ? identifier.trim() : '9876543210',
          email: cleanId.contains('@') ? cleanId : null,
          role: UserRole.passenger,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        _currentUser = user;
        _driverProfile = null;
        await StorageService.saveUser(user.toMap());
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user with specific role
  Future<bool> register({
    required String name,
    required String phoneNumber,
    String? email,
    required UserRole role,
    String? vehicleNumber,
    String? licenseOrId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final newUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final user = UserModel(
        id: newUserId,
        name: name.trim(),
        phoneNumber: phoneNumber.trim(),
        email: email?.trim(),
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _currentUser = user;
      await StorageService.saveUser(user.toMap());

      if (role == UserRole.driver) {
        // IMPORTANT SECURITY RULE: A driver CANNOT self-approve.
        // All newly registered drivers MUST start in 'pending' status.
        final driver = DriverProfileModel(
          driverId: newUserId,
          vehicleNumber: vehicleNumber?.trim() ?? 'PENDING-REGISTRATION',
          licenseOrId: licenseOrId?.trim(),
          approvalStatus: DriverApprovalStatus.pending,
          isOnline: false,
          totalTrips: 0,
          rating: 5.0,
          updatedAt: DateTime.now(),
        );
        _driverProfile = driver;
        await StorageService.saveDriverProfile(driver.toMap());
      } else {
        _driverProfile = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Registration failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle Driver Online / Offline status (only if approved)
  Future<bool> toggleDriverOnline(bool online) async {
    if (_driverProfile == null || !_driverProfile!.isApproved) {
      _errorMessage = 'Only approved drivers can go online';
      notifyListeners();
      return false;
    }

    try {
      _driverProfile = _driverProfile!.copyWith(
        isOnline: online,
        updatedAt: DateTime.now(),
      );
      await StorageService.saveDriverProfile(_driverProfile!.toMap());
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not update status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Admin approval simulator for local verification testing
  Future<void> simulateAdminApproval(bool approved) async {
    if (_driverProfile == null) return;
    _driverProfile = _driverProfile!.copyWith(
      approvalStatus: approved ? DriverApprovalStatus.approved : DriverApprovalStatus.rejected,
      approvedBy: approved ? 'admin_test' : null,
      approvedAt: approved ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
    await StorageService.saveDriverProfile(_driverProfile!.toMap());
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    _driverProfile = null;
    await StorageService.clearSession();
    notifyListeners();
  }
}
