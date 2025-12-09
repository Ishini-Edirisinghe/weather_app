import 'package:flutter/material.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/weather_entity.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepositoryImpl repository;

  WeatherEntity? current;
  bool loading = false;
  String? error;
  List<WeatherEntity> favorites = [];

  // 1. ADD THIS: Track the current tab index here
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  WeatherViewModel({required this.repository});

  // 2. ADD THIS: Method to change tabs
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
      favorites = await repository.getFavorites();
      notifyListeners();
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  Future<void> toggleFavorite() async {
    if (current == null) return;
    final newStatus = !current!.isFavorite;
    await repository.toggleFavorite(current!.city, newStatus);

    // Update local state
    current = WeatherEntity(
      city: current!.city,
      lat: current!.lat,
      lon: current!.lon,
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

//   // New: List to store favorite cities
//   List<WeatherEntity> favorites = [];

//   WeatherViewModel({required this.repository});

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

//   // --- NEW: Load Favorites List ---
//   Future<void> loadFavorites() async {
//     try {
//       favorites = await repository.getFavorites();
//       notifyListeners();
//     } catch (e) {
//       print("Error loading favorites: $e");
//     }
//   }

//   // --- NEW: Toggle Favorite Status ---
//   Future<void> toggleFavorite() async {
//     if (current == null) return;

//     // 1. Calculate new status
//     final newStatus = !current!.isFavorite;

//     // 2. Persist to Database
//     await repository.toggleFavorite(current!.city, newStatus);

//     // 3. Update the Current Entity instantly (so the UI heart changes color)
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
//       isFavorite: newStatus, // <--- Key Update
//     );

//     // 4. Reload the favorites list to keep the "Favorites" tab in sync
//     await loadFavorites();

//     notifyListeners();
//   }
// }

// import 'package:flutter/material.dart';
// import '../../data/repositories/weather_repository_impl.dart';
// import '../../domain/entities/weather_entity.dart';

// class WeatherViewModel extends ChangeNotifier {
//   final WeatherRepositoryImpl repository;

//   WeatherEntity? current;
//   bool loading = false;
//   String? error;

//   WeatherViewModel({required this.repository});

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
//     // use repository.getFavorites()
//     notifyListeners();
//   }
// }
