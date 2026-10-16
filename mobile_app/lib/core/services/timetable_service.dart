import 'package:flutter/foundation.dart';
import '../../models/bus_timetable_model.dart';
import 'storage_service.dart';

class TimetableService extends ChangeNotifier {
  List<BusTimetableModel> _timetables = [];
  bool _isLoading = false;
  bool _isOffline = false;
  DateTime? _lastCacheTime;
  String _searchQuery = '';
  String _selectedDestinationFilter = 'All';

  List<BusTimetableModel> get timetables => _filteredTimetables();
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  DateTime? get lastCacheTime => _lastCacheTime;
  String get searchQuery => _searchQuery;
  String get selectedDestinationFilter => _selectedDestinationFilter;

  TimetableService() {
    loadTimetables();
  }

  /// Initial verified schedules from Karimpur Bus Stand
  static final List<BusTimetableModel> defaultKarimpurSchedules = [
    BusTimetableModel(
      id: 'bus_krm_knr_01',
      routeName: 'Karimpur – Krishnanagar',
      origin: 'Karimpur Bus Stand',
      destination: 'Krishnanagar Bus Stand',
      viaStops: ['Tehatta', 'Chapra', 'Dhubulia'],
      departureTime: '05:45',
      arrivalTime: '07:30',
      operatorName: 'SBSTC Ordinary Express',
      busType: 'Express',
      serviceDays: 'Daily',
      fareEstimate: 55,
      isVerified: true,
      lastVerifiedAt: DateTime(2026, 3, 10, 9, 0),
    ),
    BusTimetableModel(
      id: 'bus_krm_knr_02',
      routeName: 'Karimpur – Krishnanagar',
      origin: 'Karimpur Bus Stand',
      destination: 'Krishnanagar Bus Stand',
      viaStops: ['Tehatta', 'Chapra'],
      departureTime: '06:30',
      arrivalTime: '08:15',
      operatorName: 'Nadia Bus Syndicate',
      busType: 'Ordinary',
      serviceDays: 'Daily',
      fareEstimate: 55,
      isVerified: true,
      lastVerifiedAt: DateTime(2026, 3, 10, 9, 0),
    ),
    BusTimetableModel(
      id: 'bus_krm_kol_01',
      routeName: 'Karimpur – Kolkata (Esplanade)',
      origin: 'Karimpur Bus Stand',
      destination: 'Kolkata (Esplanade)',
      viaStops: ['Tehatta', 'Krishnanagar', 'Ranaghat', 'Barasat'],
      departureTime: '05:00',
      arrivalTime: '10:15',
      operatorName: 'NBSTC Rocket Service',
      busType: 'Fast Express',
      serviceDays: 'Daily',
      fareEstimate: 165,
      isVerified: true,
      lastVerifiedAt: DateTime(2026, 3, 10, 9, 0),
    ),
    BusTimetableModel(
      id: 'bus_krm_kol_02',
      routeName: 'Karimpur – Kolkata (Esplanade)',
      origin: 'Karimpur Bus Stand',
      destination: 'Kolkata (Esplanade)',
      viaStops: ['Tehatta', 'Krishnanagar', 'Santipur Bypass', 'Airport 1 No'],
      departureTime: '06:00',
      arrivalTime: '11:30',
      operatorName: 'SBSTC Non-AC Express',
      busType: 'Express',
      serviceDays: 'Daily',
      fareEstimate: 170,
      isVerified: true,
      lastVerifiedAt: DateTime(2026, 3, 10, 9, 0),
    ),
    BusTimetableModel(
      id: 'bus_krm_bpc_01',
      routeName: 'Karimpur – Berhampore (Mohona)',
      origin: 'Karimpur Bus Stand',
      destination: 'Berhampore Bus Stand (Mohona)',
      viaStops: ['Shikarpur', 'Jalangi', 'Domkal', 'Hariharpara'],
      departureTime: '06:15',
      arrivalTime: '08:30',
      operatorName: 'Murshidabad-Nadia Joint Syndicate',
      busType: 'Ordinary',
      serviceDays: 'Daily',
      fareEstimate: 60,
      isVerified: true,
      lastVerifiedAt: DateTime(2026, 3, 10, 9, 0),
    ),
    BusTimetableModel(
      id: 'bus_krm_mld_01',
      routeName: 'Karimpur – Malda Town',
      origin: 'Karimpur Bus Stand',
      destination: 'Malda Rathbari',
      viaStops: ['Berhampore', 'Morgram', 'Farakka'],
      departureTime: '19:00',
      arrivalTime: '01:30',
      operatorName: 'NBSTC Night Service',
      busType: 'Night Express',
      serviceDays: 'Daily',
      fareEstimate: 240,
      isVerified: true,
      lastVerifiedAt: DateTime(2026, 3, 10, 9, 0),
    ),
  ];

  /// Fetch timetables with offline-cache fallback
  Future<void> loadTimetables({bool forceRefresh = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Try reading from persistent local cache
      final cached = await StorageService.getCachedTimetables();
      _lastCacheTime = await StorageService.getTimetableCachedAt();

      if (cached != null && cached.isNotEmpty && !forceRefresh) {
        _timetables = cached.map((e) => BusTimetableModel.fromMap(e)).toList();
        _isOffline = false;
      } else {
        // Fallback to verified local schedules and write to cache
        _timetables = defaultKarimpurSchedules;
        _lastCacheTime = DateTime.now();
        await StorageService.cacheTimetables(
          _timetables.map((e) => e.toMap()).toList(),
        );
        _isOffline = false;
      }
    } catch (e) {
      debugPrint('Network error loading timetable, falling back to offline cache: $e');
      _isOffline = true;
      if (_timetables.isEmpty) {
        _timetables = defaultKarimpurSchedules;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simulate offline toggle for testing offline cache behavior
  void setOfflineMode(bool offline) {
    _isOffline = offline;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setDestinationFilter(String dest) {
    _selectedDestinationFilter = dest;
    notifyListeners();
  }

  List<BusTimetableModel> _filteredTimetables() {
    return _timetables.where((item) {
      if (!item.isActive) return false;

      // Destination filter
      if (_selectedDestinationFilter != 'All') {
        if (!item.destination.toLowerCase().contains(_selectedDestinationFilter.toLowerCase())) {
          return false;
        }
      }

      // Query text match
      return item.matchesQuery(_searchQuery);
    }).toList();
  }
}
