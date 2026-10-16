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
      appBar: AppBar(
        title: const Text('Driver Verification Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFB74D), width: 2),
                    ),
                    child: const Icon(
                      Icons.hourglass_empty_rounded,
                      size: 42,
                      color: Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Application Under Review',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'চালক অনুমোদন প্রক্রিয়াধীন রয়েছে',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Detail Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Verification Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              StatusBadge(
                                status: driver?.approvalStatus.toDbString() ?? 'pending',
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow('Driver Name', user?.name ?? 'Unknown'),
                          _buildDetailRow('Phone Number', user?.phoneNumber ?? '-'),
                          _buildDetailRow('Vehicle Number', driver?.vehicleNumber ?? 'Pending Submission'),
                          _buildDetailRow('ID Proof', driver?.licenseOrId ?? 'Aadhaar / Voter ID'),
                          _buildDetailRow('Service Town', 'Karimpur, Nadia (741152)'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Security notice box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'To protect passengers and ensure fair fare standards, our local Karimpur administrator verifies your vehicle registration before granting active ride dispatch access.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Developer / Demonstration convenience button
                  CustomButton(
                    text: 'Simulate Admin Approval (Test Gate)',
                    isOutlined: true,
                    icon: Icons.check_circle_outline,
                    onPressed: () async {
                      await authService.simulateAdminApproval(true);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Driver approved! Unlocking Captain Dashboard.'),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Status Again'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Checking latest verification records...')),
                      );
                    },
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
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
