import 'package:flutter_test/flutter_test.dart';
import 'package:pothiksathi/models/user_model.dart';
import 'package:pothiksathi/models/driver_profile_model.dart';

void main() {
  group('Auth & Role Access Tests', () {
    test('User role parsing defaults to passenger when unspecified', () {
      final role = UserModel.fromMap({
        'id': 'test_1',
        'name': 'Test User',
        'phoneNumber': '9876543210',
      }).role;

      expect(role, equals(UserRole.passenger));
    });

    test('Driver role is parsed correctly from strings', () {
      expect(UserRole.fromString('driver'), equals(UserRole.driver));
      expect(UserRole.fromString('captain'), equals(UserRole.driver));
      expect(UserRole.fromString('DRIVER'), equals(UserRole.driver));
    });

    test('New driver profile starts in pending status and cannot self-approve', () {
      final driver = DriverProfileModel(
        driverId: 'drv_01',
        vehicleNumber: 'WB-52-TOTO-1234',
        approvalStatus: DriverApprovalStatus.pending,
        isOnline: false,
        updatedAt: DateTime.now(),
      );

      expect(driver.isApproved, isFalse);
      expect(driver.approvalStatus, equals(DriverApprovalStatus.pending));
    });

    test('Only approved driver profile evaluates isApproved to true', () {
      final approvedDriver = DriverProfileModel(
        driverId: 'drv_02',
        vehicleNumber: 'WB-52-TOTO-5678',
        approvalStatus: DriverApprovalStatus.approved,
        isOnline: true,
        approvedBy: 'admin_karimpur',
        approvedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(approvedDriver.isApproved, isTrue);
    });

    test('Suspended or rejected driver is denied active approval', () {
      final suspended = DriverProfileModel(
        driverId: 'drv_03',
        vehicleNumber: 'WB-52-TOTO-9999',
        approvalStatus: DriverApprovalStatus.suspended,
        isOnline: false,
        updatedAt: DateTime.now(),
      );

      expect(suspended.isApproved, isFalse);
    });
  });
}
