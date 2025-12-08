import 'package:flutter/material.dart';
import '../../data/repositories/weather_repository_impl.dart';
import '../../domain/entities/weather_entity.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherRepositoryImpl repository;

  WeatherEntity? current;
  bool loading = false;
  String? error;

  WeatherViewModel({required this.repository});

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
    // use repository.getFavorites()
    notifyListeners();
  }
}
