import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/status_badge.dart';

class DriverPendingScreen extends StatelessWidget {
  const DriverPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final driver = authService.driverProfile;
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Driver Verification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Sign Out',
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
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
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      size: 34,
                      color: AppColors.brandBlack,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Application Under Review',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBlack,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'চালক অনুমোদন প্রক্রিয়াধীন রয়েছে',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detail Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Verification Status',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            StatusBadge(
                              status: driver?.approvalStatus.toDbString() ?? 'pending',
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildDetailRow('Captain Name', user?.name ?? 'Unknown'),
                        _buildDetailRow('Phone Number', user?.phoneNumber ?? '-'),
                        _buildDetailRow('Vehicle Number', driver?.vehicleNumber ?? 'Pending Submission'),
                        _buildDetailRow('Service Hub', 'Karimpur, Nadia (741152)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Refresh Status Button
                  CustomButton(
                    text: 'Refresh Approval Status',
                    isLime: true,
                    isLoading: authService.isLoading,
                    onPressed: () => authService.checkCurrentUser(),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    onPressed: () => authService.signOut(),
                    child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
