import 'package:flutter/material.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/entities/weather_alert.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepositoryImpl repository;

  WeatherEntity? current;
  bool loading = false;
  String? error;

  // Favorites & Filtering
  List<WeatherEntity> _allFavorites = [];
  List<WeatherEntity> filteredFavorites = [];
  List<String> availableRegions = ['All'];
  String selectedFilter = 'All';

  // Alerts
  List<WeatherAlert> aggregatedAlerts = [];

  // Search History
  List<String> searchHistory = [];

  // Tab State
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  WeatherViewModel({required this.repository});

  void setTabIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // --- SEARCH HISTORY ---
  Future<void> loadSearchHistory() async {
    searchHistory = await repository.getSearchHistory();
    notifyListeners();
  }

  // NEW: Clear All History
  Future<void> clearSearchHistory() async {
    await repository.clearSearchHistory();
    await loadSearchHistory();
  }

  // NEW: Delete Single Item
  Future<void> deleteSearchItem(String query) async {
    await repository.deleteSearchItem(query);
    await loadSearchHistory();
  }

  // --- MAIN LOAD FUNCTION ---
  Future<void> loadWeatherForCity(String city) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await repository.getCurrentWeatherByCity(city);
      current = result;

      // Save to History
      await repository.saveSearch(city);
      await loadSearchHistory();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  // --- FAVORITES & ALERTS ---
  Future<void> loadFavorites() async {
    try {
      _allFavorites = await repository.getFavorites();

      // 1. Generate Dropdown Options
      final Set<String> regions = {'All'};
      for (var city in _allFavorites) {
        if (city.country == 'LK') {
          if (city.state.isNotEmpty) {
            regions.add(city.state);
          } else {
            regions.add('Sri Lanka (Unknown Region)');
          }
        } else {
          regions.add('Other');
        }
      }
      availableRegions = regions.toList();
      availableRegions.sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        if (a == 'Other') return 1;
        if (b == 'Other') return -1;
        return a.compareTo(b);
      });

      // 2. Aggregate Alerts
      aggregatedAlerts = [];
      for (var city in _allFavorites) {
        aggregatedAlerts.addAll(city.alerts);
      }

      // 3. Apply Filter
      applyFilter(selectedFilter);

      // 4. SYNC CURRENT CITY STATUS
      _syncCurrentStatus();
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  // --- Helper to Sync Home Screen Heart Icon ---
  void _syncCurrentStatus() {
    if (current == null) return;

    final isActuallyFavorite = _allFavorites.any(
      (item) => item.city == current!.city,
    );

    if (current!.isFavorite != isActuallyFavorite) {
      current = WeatherEntity(
        city: current!.city,
        lat: current!.lat,
        lon: current!.lon,
        country: current!.country,
        state: current!.state,
        temp: current!.temp,
        description: current!.description,
        iconCode: current!.iconCode,
        forecastJson: current!.forecastJson,
        humidity: current!.humidity,
        windSpeed: current!.windSpeed,
        sunrise: current!.sunrise,
        sunset: current!.sunset,
        isFavorite: isActuallyFavorite,
        alerts: current!.alerts,
      );
      notifyListeners();
    }
  }

  void applyFilter(String region) {
    selectedFilter = region;
    if (!availableRegions.contains(selectedFilter)) {
      selectedFilter = 'All';
    }

    if (selectedFilter == 'All') {
      filteredFavorites = List.from(_allFavorites);
    } else if (selectedFilter == 'Other') {
      filteredFavorites = _allFavorites
          .where((city) => city.country != 'LK')
          .toList();
    } else {
      filteredFavorites = _allFavorites
          .where((city) => city.state == selectedFilter)
          .toList();
    }
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    if (current == null) return;
    final newStatus = !current!.isFavorite;
    await repository.toggleFavorite(current!.city, newStatus);

    current = WeatherEntity(
      city: current!.city,
      lat: current!.lat,
      lon: current!.lon,
      country: current!.country,
      state: current!.state,
      temp: current!.temp,
      description: current!.description,
      iconCode: current!.iconCode,
      forecastJson: current!.forecastJson,
      humidity: current!.humidity,
      windSpeed: current!.windSpeed,
      sunrise: current!.sunrise,
      sunset: current!.sunset,
      isFavorite: newStatus,
      alerts: current!.alerts,
    );
    await loadFavorites();
    notifyListeners();
  }

  // Used by Swipe-to-Delete in Favorites Screen
  Future<void> removeFavorite(WeatherEntity city) async {
    _allFavorites.removeWhere((item) => item.city == city.city);
    applyFilter(selectedFilter);
    await repository.toggleFavorite(city.city, false);
    await loadFavorites();
  }

  Future<void> removeAlert(WeatherAlert alert) async {
    await repository.deleteAlert(alert.city, alert);

    if (current != null && current!.city == alert.city) {
      final updatedAlerts = List<WeatherAlert>.from(current!.alerts);
      updatedAlerts.removeWhere(
        (a) => a.event == alert.event && a.description == alert.description,
      );

      current = WeatherEntity(
        city: current!.city,
        lat: current!.lat,
        lon: current!.lon,
        country: current!.country,
        state: current!.state,
        temp: current!.temp,
        description: current!.description,
        iconCode: current!.iconCode,
        forecastJson: current!.forecastJson,
        humidity: current!.humidity,
        windSpeed: current!.windSpeed,
        sunrise: current!.sunrise,
        sunset: current!.sunset,
        isFavorite: current!.isFavorite,
        alerts: updatedAlerts,
      );
    }
    await loadFavorites();
    notifyListeners();
  }
}

// import 'package:flutter/material.dart';
// import '../../data/repositories/weather_repository_impl.dart';
// import '../../domain/entities/weather_entity.dart';
// import '../../domain/entities/weather_alert.dart';

// class WeatherViewModel extends ChangeNotifier {
//   final WeatherRepositoryImpl repository;

//   WeatherEntity? current;
//   bool loading = false;
//   String? error;

//   // Favorites & Filtering
//   List<WeatherEntity> _allFavorites = [];
//   List<WeatherEntity> filteredFavorites = [];
//   List<String> availableRegions = ['All'];
//   String selectedFilter = 'All';

//   // Alerts
//   List<WeatherAlert> aggregatedAlerts = [];

//   // Search History
//   List<String> searchHistory = [];

//   // Tab State
//   int _currentIndex = 0;
//   int get currentIndex => _currentIndex;

//   WeatherViewModel({required this.repository});

//   void setTabIndex(int index) {
//     _currentIndex = index;
//     notifyListeners();
//   }

//   // --- SEARCH HISTORY ---
//   Future<void> loadSearchHistory() async {
//     searchHistory = await repository.getSearchHistory();
//     notifyListeners();
//   }

//   // --- MAIN LOAD FUNCTION ---
//   Future<void> loadWeatherForCity(String city) async {
//     loading = true;
//     error = null;
//     notifyListeners();
//     try {
//       final result = await repository.getCurrentWeatherByCity(city);
//       current = result;

//       // Save to History
//       await repository.saveSearch(city);
//       await loadSearchHistory();
//     } catch (e) {
//       error = e.toString();
//     }
//     loading = false;
//     notifyListeners();
//   }

//   // --- FAVORITES & ALERTS ---
//   Future<void> loadFavorites() async {
//     try {
//       _allFavorites = await repository.getFavorites();

//       // 1. Generate Dropdown Options
//       final Set<String> regions = {'All'};
//       for (var city in _allFavorites) {
//         if (city.country == 'LK') {
//           if (city.state.isNotEmpty) {
//             regions.add(city.state);
//           } else {
//             regions.add('Sri Lanka (Unknown Region)');
//           }
//         } else {
//           regions.add('Other');
//         }
//       }
//       availableRegions = regions.toList();
//       availableRegions.sort((a, b) {
//         if (a == 'All') return -1;
//         if (b == 'All') return 1;
//         if (a == 'Other') return 1;
//         if (b == 'Other') return -1;
//         return a.compareTo(b);
//       });

//       // 2. Aggregate Alerts
//       aggregatedAlerts = [];
//       for (var city in _allFavorites) {
//         aggregatedAlerts.addAll(city.alerts);
//       }

//       // 3. Apply Filter
//       applyFilter(selectedFilter);

//       // 4. SYNC CURRENT CITY STATUS (The Fix)
//       // This checks if the city on the Home Screen is still in the favorites list
//       _syncCurrentStatus();
//     } catch (e) {
//       print("Error loading favorites: $e");
//     }
//   }

//   // --- Helper to Sync Home Screen Heart Icon ---
//   void _syncCurrentStatus() {
//     if (current == null) return;

//     // Check if the current city exists in the updated favorites list
//     final isActuallyFavorite = _allFavorites.any(
//       (item) => item.city == current!.city,
//     );

//     // If the status has changed (e.g., removed from favorites screen), update 'current'
//     if (current!.isFavorite != isActuallyFavorite) {
//       current = WeatherEntity(
//         city: current!.city,
//         lat: current!.lat,
//         lon: current!.lon,
//         country: current!.country,
//         state: current!.state,
//         temp: current!.temp,
//         description: current!.description,
//         iconCode: current!.iconCode,
//         forecastJson: current!.forecastJson,
//         humidity: current!.humidity,
//         windSpeed: current!.windSpeed,
//         sunrise: current!.sunrise,
//         sunset: current!.sunset,
//         isFavorite: isActuallyFavorite, // <--- UPDATE STATUS HERE
//         alerts: current!.alerts,
//       );
//       notifyListeners();
//     }
//   }

//   void applyFilter(String region) {
//     selectedFilter = region;
//     if (!availableRegions.contains(selectedFilter)) {
//       selectedFilter = 'All';
//     }

//     if (selectedFilter == 'All') {
//       filteredFavorites = List.from(_allFavorites);
//     } else if (selectedFilter == 'Other') {
//       filteredFavorites = _allFavorites
//           .where((city) => city.country != 'LK')
//           .toList();
//     } else {
//       filteredFavorites = _allFavorites
//           .where((city) => city.state == selectedFilter)
//           .toList();
//     }
//     notifyListeners();
//   }

//   Future<void> toggleFavorite() async {
//     if (current == null) return;
//     final newStatus = !current!.isFavorite;
//     await repository.toggleFavorite(current!.city, newStatus);

//     // Update local current state instantly
//     current = WeatherEntity(
//       city: current!.city,
//       lat: current!.lat,
//       lon: current!.lon,
//       country: current!.country,
//       state: current!.state,
//       temp: current!.temp,
//       description: current!.description,
//       iconCode: current!.iconCode,
//       forecastJson: current!.forecastJson,
//       humidity: current!.humidity,
//       windSpeed: current!.windSpeed,
//       sunrise: current!.sunrise,
//       sunset: current!.sunset,
//       isFavorite: newStatus,
//       alerts: current!.alerts,
//     );
//     await loadFavorites();
//     notifyListeners();
//   }

//   // Used by Swipe-to-Delete in Favorites Screen
//   Future<void> removeFavorite(WeatherEntity city) async {
//     // 1. Remove from local list instantly to prevent UI crash
//     _allFavorites.removeWhere((item) => item.city == city.city);
//     applyFilter(selectedFilter);

//     // 2. Sync with DB in background
//     await repository.toggleFavorite(city.city, false);

//     // 3. Reload to ensure everything is in sync (including Home screen heart)
//     await loadFavorites();
//   }

//   Future<void> removeAlert(WeatherAlert alert) async {
//     await repository.deleteAlert(alert.city, alert);

//     if (current != null && current!.city == alert.city) {
//       final updatedAlerts = List<WeatherAlert>.from(current!.alerts);
//       updatedAlerts.removeWhere(
//         (a) => a.event == alert.event && a.description == alert.description,
//       );

//       current = WeatherEntity(
//         city: current!.city,
//         lat: current!.lat,
//         lon: current!.lon,
//         country: current!.country,
//         state: current!.state,
//         temp: current!.temp,
//         description: current!.description,
//         iconCode: current!.iconCode,
//         forecastJson: current!.forecastJson,
//         humidity: current!.humidity,
//         windSpeed: current!.windSpeed,
//         sunrise: current!.sunrise,
//         sunset: current!.sunset,
//         isFavorite: current!.isFavorite,
//         alerts: updatedAlerts,
//       );
//     }
//     await loadFavorites();
//     notifyListeners();
//   }
// }
