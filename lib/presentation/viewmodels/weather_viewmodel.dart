import 'package:flutter/material.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/weather_entity.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepositoryImpl repository;

  WeatherEntity? current;
  bool loading = false;
  String? error;

  List<WeatherEntity> _allFavorites = []; // Full list from DB
  List<WeatherEntity> filteredFavorites = []; // List shown in UI

  String selectedFilter = 'All'; // Current filter

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
      applyFilter(selectedFilter); // Apply current filter
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  // Filter Logic
  void applyFilter(String region) {
    selectedFilter = region;
    if (region == 'All') {
      filteredFavorites = List.from(_allFavorites);
    } else {
      filteredFavorites = _allFavorites.where((city) {
        return getRegionFromCountryCode(city.country) == region;
      }).toList();
    }
    notifyListeners();
  }

  // Helper: Map Country Code to Region
  String getRegionFromCountryCode(String code) {
    // Add more codes here as needed
    const asia = ['LK', 'IN', 'CN', 'JP', 'TH', 'SG', 'AE', 'KR', 'ID', 'VN'];
    const europe = ['GB', 'FR', 'DE', 'IT', 'ES', 'RU', 'UA', 'NL', 'SE', 'NO'];
    const northAmerica = ['US', 'CA', 'MX'];
    const oceania = ['AU', 'NZ'];

    if (asia.contains(code)) return 'Asia';
    if (europe.contains(code)) return 'Europe';
    if (northAmerica.contains(code)) return 'North America';
    if (oceania.contains(code)) return 'Oceania';

    return 'Other'; // Default if not found
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
//   List<WeatherEntity> favorites = [];

//   // 1. ADD THIS: Track the current tab index here
//   int _currentIndex = 0;
//   int get currentIndex => _currentIndex;

//   WeatherViewModel({required this.repository});

//   // 2. ADD THIS: Method to change tabs
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
//       favorites = await repository.getFavorites();
//       notifyListeners();
//     } catch (e) {
//       print("Error loading favorites: $e");
//     }
//   }

//   Future<void> toggleFavorite() async {
//     if (current == null) return;
//     final newStatus = !current!.isFavorite;
//     await repository.toggleFavorite(current!.city, newStatus);

//     // Update local state
//     current = WeatherEntity(
//       city: current!.city,
//       lat: current!.lat,
//       lon: current!.lon,
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
