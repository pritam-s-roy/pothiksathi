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
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: config.textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: config.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
          backgroundColor: const Color(0xFFFFF3E0),
          borderColor: const Color(0xFFFFCC80),
        );
      case 'driver_assigned':
      case 'assigned':
        return _BadgeConfig(
          label: 'Driver Assigned',
          textColor: AppColors.statusAssigned,
          backgroundColor: const Color(0xFFE1F5FE),
          borderColor: const Color(0xFF81D4FA),
        );
      case 'driver_accepted':
      case 'accepted':
        return _BadgeConfig(
          label: 'Accepted / On Way',
          textColor: AppColors.statusAccepted,
          backgroundColor: const Color(0xFFE8F5E9),
          borderColor: const Color(0xFFA5D6A7),
        );
      case 'driver_arrived':
      case 'arrived':
        return _BadgeConfig(
          label: 'Driver Arrived',
          textColor: AppColors.statusArrived,
          backgroundColor: const Color(0xFFF1F8E9),
          borderColor: const Color(0xFFC5E1A5),
        );
      case 'in_progress':
      case 'picked_up':
        return _BadgeConfig(
          label: 'Trip In Progress',
          textColor: AppColors.statusActive,
          backgroundColor: const Color(0xFFE0F2F1),
          borderColor: const Color(0xFF80CBC4),
        );
      case 'completed':
        return _BadgeConfig(
          label: 'Completed',
          textColor: AppColors.statusCompleted,
          backgroundColor: const Color(0xFFE8F5E9),
          borderColor: const Color(0xFFA5D6A7),
        );
      case 'cancelled':
      case 'cancelled_by_passenger':
      case 'cancelled_by_admin':
      case 'rejected':
      case 'driver_rejected':
        return _BadgeConfig(
          label: 'Cancelled',
          textColor: AppColors.statusCancelled,
          backgroundColor: const Color(0xFFFFEBEE),
          borderColor: const Color(0xFFEF9A9A),
        );
      case 'approved':
        return _BadgeConfig(
          label: 'Approved',
          textColor: AppColors.statusCompleted,
          backgroundColor: const Color(0xFFE8F5E9),
          borderColor: const Color(0xFFA5D6A7),
        );
      case 'online':
        return _BadgeConfig(
          label: 'Online',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primaryTint,
          borderColor: AppColors.primaryLight,
        );
      case 'offline':
        return _BadgeConfig(
          label: 'Offline',
          textColor: AppColors.textSecondary,
          backgroundColor: const Color(0xFFEEEEEE),
          borderColor: const Color(0xFFBDBDBD),
        );
      default:
        return _BadgeConfig(
          label: rawStatus,
          textColor: AppColors.textSecondary,
          backgroundColor: const Color(0xFFF5F5F5),
          borderColor: const Color(0xFFE0E0E0),
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
