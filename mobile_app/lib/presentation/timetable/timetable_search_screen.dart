import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/timetable_service.dart';
import '../../core/utils/formatters.dart';
import '../../models/bus_timetable_model.dart';
import '../widgets/status_badge.dart';

class TimetableSearchScreen extends StatefulWidget {
  const TimetableSearchScreen({super.key});

  @override
  State<TimetableSearchScreen> createState() => _TimetableSearchScreenState();
}

class _TimetableSearchScreenState extends State<TimetableSearchScreen> {
  final _searchController = TextEditingController();

  final List<String> _destinations = [
    'All',
    'Krishnanagar',
    'Kolkata',
    'Berhampore',
    'Malda',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timetableService = context.watch<TimetableService>();
    final timetables = timetableService.timetables;
    final isOffline = timetableService.isOffline;
    final cacheTime = timetableService.lastCacheTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Karimpur Bus Schedules'),
        actions: [
          IconButton(
            icon: Icon(isOffline ? Icons.wifi_off : Icons.wifi, size: 20),
            tooltip: isOffline ? 'Offline Mode Active' : 'Online Mode',
            onPressed: () {
              timetableService.setOfflineMode(!isOffline);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isOffline ? 'Switched to Online mode.' : 'Switched to Offline mode (Testing cache).'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Schedules',
            onPressed: () => timetableService.loadTimetables(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Offline Banner Notification (Requirement from Section 4)
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFFFF3E0),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 20, color: Color(0xFFE65100)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Viewing Offline Cached Timetable',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                        Text(
                          cacheTime != null
                              ? 'Cached on ${Formatters.formatDateTime(cacheTime)}. Data may be outdated.'
                              : 'No internet connection. Showing locally saved schedules.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFBF360C)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 2. Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search destination, via stop, or operator...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              timetableService.updateSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  onChanged: (val) => timetableService.updateSearchQuery(val),
                ),
                const SizedBox(height: 10),

                // Destination filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _destinations.map((dest) {
                      final isSelected = timetableService.selectedDestinationFilter == dest;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(dest),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              timetableService.setDestinationFilter(dest);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 3. Timetable Results List
          Expanded(
            child: timetables.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.directions_bus_outlined, size: 48, color: AppColors.textLight),
                          const SizedBox(height: 12),
                          const Text(
                            'No bus schedules found',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Try adjusting your search query or select "All" destinations.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: timetables.length,
                    itemBuilder: (context, index) {
                      final bus = timetables[index];
                      return _buildBusCard(bus);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusTimetableModel bus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Type badge & Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${bus.busType} • ${bus.serviceDays}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (bus.isVerified)
                      const StatusBadge(status: 'approved', label: 'Verified'),
                  ],
                ),
                Text(
                  bus.departureTime,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Route Name & Expected Arrival
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  bus.routeName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Arrives ~${bus.arrivalTime}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Via Stops
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Via: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                Expanded(
                  child: Text(
                    bus.viaStops.join(' → '),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Operator & Fare Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_bus, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      bus.operatorName,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Text(
                  'Est. Fare: ${Formatters.formatCurrency(bus.fareEstimate)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            if (bus.lastVerifiedAt != null) ...[
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last verified: ${Formatters.formatDate(bus.lastVerifiedAt!)}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                  const Text(
                    'Karimpur Station Authority',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
