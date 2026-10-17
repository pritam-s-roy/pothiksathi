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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bus Schedules'),
        actions: [
          IconButton(
            icon: Icon(isOffline ? Icons.wifi_off : Icons.wifi, size: 18),
            tooltip: isOffline ? 'Offline Mode Active' : 'Online Mode',
            onPressed: () {
              timetableService.setOfflineMode(!isOffline);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isOffline ? 'Online mode active' : 'Offline cache active'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: () => timetableService.loadTimetables(forceRefresh: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFFEF3C7),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cacheTime != null
                          ? 'Offline Cache: ${Formatters.formatDateTime(cacheTime)}'
                          : 'Showing local cached schedules.',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),

          // Search and Destination Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search destination or stop...',
                    prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _destinations.map((dest) {
                      final isSelected = timetableService.selectedDestinationFilter == dest;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () => timetableService.setDestinationFilter(dest),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.brandBlack : AppColors.surfaceSubtle,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              dest,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Bus List
          Expanded(
            child: timetables.isEmpty
                ? const Center(
                    child: Text(
                      'No bus schedules found',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bus.busType,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              Text(
                bus.departureTime,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bus.routeName,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Via: ${bus.viaStops.join(" → ")}',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bus.operatorName,
                style: const TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.w600),
              ),
              Text(
                Formatters.formatCurrency(bus.fareEstimate),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
