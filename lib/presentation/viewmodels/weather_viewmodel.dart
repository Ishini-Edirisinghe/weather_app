import 'package:flutter/material.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/weather_entity.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepositoryImpl repository;

  WeatherEntity? current;
  bool loading = false;
  String? error;

  List<WeatherEntity> _allFavorites = [];
  List<WeatherEntity> filteredFavorites = [];

  // Dropdown options
  List<String> availableRegions = ['All'];
  String selectedFilter = 'All';

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  WeatherViewModel({required this.repository});

  void setTabIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  Future<void> loadWeatherForCity(String city) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await repository.getCurrentWeatherByCity(city);
      current = result;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    try {
      _allFavorites = await repository.getFavorites();

      // 1. Generate Dropdown Options dynamically
      final Set<String> regions = {'All'};
      for (var city in _allFavorites) {
        if (city.country == 'LK') {
          // If Sri Lanka, use the specific Province/State
          if (city.state.isNotEmpty) {
            regions.add(city.state);
          } else {
            regions.add('Sri Lanka (Unknown Region)');
          }
        } else {
          // If not Sri Lanka, group as 'Other'
          regions.add('Other');
        }
      }
      // Convert to list and sort
      availableRegions = regions.toList();
      availableRegions.sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        if (a == 'Other') return 1; // Put 'Other' at bottom
        if (b == 'Other') return -1;
        return a.compareTo(b);
      });

      // 2. Apply current filter
      applyFilter(selectedFilter);
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  void applyFilter(String region) {
    selectedFilter = region;

    // Ensure selected filter still exists in the list (e.g. after deleting a city)
    if (!availableRegions.contains(selectedFilter)) {
      selectedFilter = 'All';
    }

    if (selectedFilter == 'All') {
      filteredFavorites = List.from(_allFavorites);
    } else if (selectedFilter == 'Other') {
      // Show cities that are NOT Sri Lanka
      filteredFavorites = _allFavorites
          .where((city) => city.country != 'LK')
          .toList();
    } else {
      // Show specific Sri Lankan Province
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
    );
    await loadFavorites();
    notifyListeners();
  }
}

// import 'package:flutter/material.dart';
// import '../../data/repositories/weather_repository_impl.dart';
// import '../../domain/entities/weather_entity.dart';

// class WeatherViewModel extends ChangeNotifier {
//   final WeatherRepositoryImpl repository;

//   WeatherEntity? current;
//   bool loading = false;
//   String? error;

//   List<WeatherEntity> _allFavorites = []; // Full list from DB
//   List<WeatherEntity> filteredFavorites = []; // List shown in UI

//   String selectedFilter = 'All'; // Current filter

//   int _currentIndex = 0;
//   int get currentIndex => _currentIndex;

//   WeatherViewModel({required this.repository});

//   void setTabIndex(int index) {
//     _currentIndex = index;
//     notifyListeners();
//   }

//   Future<void> loadWeatherForCity(String city) async {
//     loading = true;
//     error = null;
//     notifyListeners();
//     try {
//       final result = await repository.getCurrentWeatherByCity(city);
//       current = result;
//     } catch (e) {
//       error = e.toString();
//     }
//     loading = false;
//     notifyListeners();
//   }

//   Future<void> loadFavorites() async {
//     try {
//       _allFavorites = await repository.getFavorites();
//       applyFilter(selectedFilter); // Apply current filter
//     } catch (e) {
//       print("Error loading favorites: $e");
//     }
//   }

//   // Filter Logic
//   void applyFilter(String region) {
//     selectedFilter = region;
//     if (region == 'All') {
//       filteredFavorites = List.from(_allFavorites);
//     } else {
//       filteredFavorites = _allFavorites.where((city) {
//         return getRegionFromCountryCode(city.country) == region;
//       }).toList();
//     }
//     notifyListeners();
//   }

//   // Helper: Map Country Code to Region
//   String getRegionFromCountryCode(String code) {
//     // Add more codes here as needed
//     const asia = ['LK', 'IN', 'CN', 'JP', 'TH', 'SG', 'AE', 'KR', 'ID', 'VN'];
//     const europe = ['GB', 'FR', 'DE', 'IT', 'ES', 'RU', 'UA', 'NL', 'SE', 'NO'];
//     const northAmerica = ['US', 'CA', 'MX'];
//     const oceania = ['AU', 'NZ'];

//     if (asia.contains(code)) return 'Asia';
//     if (europe.contains(code)) return 'Europe';
//     if (northAmerica.contains(code)) return 'North America';
//     if (oceania.contains(code)) return 'Oceania';

//     return 'Other'; // Default if not found
//   }

//   Future<void> toggleFavorite() async {
//     if (current == null) return;
//     final newStatus = !current!.isFavorite;
//     await repository.toggleFavorite(current!.city, newStatus);

//     current = WeatherEntity(
//       city: current!.city,
//       lat: current!.lat,
//       lon: current!.lon,
//       country: current!.country,
//       temp: current!.temp,
//       description: current!.description,
//       iconCode: current!.iconCode,
//       forecastJson: current!.forecastJson,
//       humidity: current!.humidity,
//       windSpeed: current!.windSpeed,
//       sunrise: current!.sunrise,
//       sunset: current!.sunset,
//       isFavorite: newStatus,
//     );
//     await loadFavorites();
//     notifyListeners();
//   }
// }
