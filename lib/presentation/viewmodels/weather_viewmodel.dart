import 'package:flutter/material.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/weather_entity.dart';
import '../../domain/entities/weather_alert.dart'; // Import

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepositoryImpl repository;

  WeatherEntity? current;
  bool loading = false;
  String? error;

  List<WeatherEntity> _allFavorites = [];
  List<WeatherEntity> filteredFavorites = [];

  // NEW: Master list of alerts
  List<WeatherAlert> aggregatedAlerts = [];

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

      // 1. Dropdown Logic
      final Set<String> regions = {'All'};
      for (var city in _allFavorites) {
        if (city.country == 'LK') {
          if (city.state.isNotEmpty)
            regions.add(city.state);
          else
            regions.add('Sri Lanka (Unknown Region)');
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

      // 2. Aggregate Alerts from ALL favorites
      aggregatedAlerts = [];
      for (var city in _allFavorites) {
        aggregatedAlerts.addAll(city.alerts);
      }

      // 3. Apply Filter
      applyFilter(selectedFilter);
    } catch (e) {
      print("Error loading favorites: $e");
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

  // ... (toggleFavorite stays same) ...
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
}
