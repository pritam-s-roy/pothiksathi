import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final String? label;

  const StatusBadge({
    super.key,
    required this.status,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(status);
    final text = label ?? config.label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: config.textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: config.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getConfig(String rawStatus) {
    switch (rawStatus.toLowerCase()) {
      case 'pending':
      case 'pending_assignment':
        return _BadgeConfig(
          label: 'Finding Driver',
          textColor: AppColors.statusPending,
          backgroundColor: const Color(0xFFFEF3C7),
          borderColor: const Color(0xFFFDE68A),
        );
      case 'driver_assigned':
      case 'assigned':
        return _BadgeConfig(
          label: 'Driver Assigned',
          textColor: AppColors.statusAssigned,
          backgroundColor: const Color(0xFFDBEAFE),
          borderColor: const Color(0xFFBFDBFE),
        );
      case 'driver_accepted':
      case 'accepted':
        return _BadgeConfig(
          label: 'Accepted / On Way',
          textColor: AppColors.statusAccepted,
          backgroundColor: const Color(0xFFD1FAE5),
          borderColor: const Color(0xFFA7F3D0),
        );
      case 'driver_arrived':
      case 'arrived':
        return _BadgeConfig(
          label: 'Driver Arrived',
          textColor: AppColors.statusArrived,
          backgroundColor: const Color(0xFFECFDF5),
          borderColor: const Color(0xFFA7F3D0),
        );
      case 'in_progress':
      case 'picked_up':
        return _BadgeConfig(
          label: 'Trip In Progress',
          textColor: AppColors.textPrimary,
          backgroundColor: AppColors.surfaceSubtle,
          borderColor: AppColors.border,
        );
      case 'completed':
        return _BadgeConfig(
          label: 'Completed',
          textColor: AppColors.statusCompleted,
          backgroundColor: const Color(0xFFD1FAE5),
          borderColor: const Color(0xFFA7F3D0),
        );
      case 'cancelled':
      case 'cancelled_by_passenger':
      case 'cancelled_by_admin':
      case 'rejected':
      case 'driver_rejected':
        return _BadgeConfig(
          label: 'Cancelled',
          textColor: AppColors.statusCancelled,
          backgroundColor: const Color(0xFFFEE2E2),
          borderColor: const Color(0xFFFECACA),
        );
      case 'approved':
        return _BadgeConfig(
          label: 'Approved',
          textColor: AppColors.statusCompleted,
          backgroundColor: const Color(0xFFD1FAE5),
          borderColor: const Color(0xFFA7F3D0),
        );
      case 'online':
        return _BadgeConfig(
          label: 'Online',
          textColor: AppColors.brandBlack,
          backgroundColor: AppColors.brandLime,
          borderColor: AppColors.brandLimeDark,
        );
      case 'offline':
        return _BadgeConfig(
          label: 'Offline',
          textColor: AppColors.textSecondary,
          backgroundColor: AppColors.surfaceSubtle,
          borderColor: AppColors.border,
        );
      default:
        return _BadgeConfig(
          label: rawStatus,
          textColor: AppColors.textPrimary,
          backgroundColor: AppColors.surfaceSubtle,
          borderColor: AppColors.border,
        );
    }
  }
}

class _BadgeConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  _BadgeConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
