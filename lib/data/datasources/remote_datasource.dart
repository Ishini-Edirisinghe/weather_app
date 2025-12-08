import 'package:dio/dio.dart';
import '../../core/constants.dart';
import '../../core/secrets.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';

class RemoteDatasource {
  final Dio dio;
  RemoteDatasource(this.dio);

  Future<WeatherModel> fetchCurrentByCity(String city) async {
    final url = '${AppConstants.openWeatherBase}/weather';
    final resp = await dio.get(
      url,
      queryParameters: {
        'q': city,
        'appid': kOpenWeatherApiKey,
        'units': 'metric',
      },
    );
    return WeatherModel.fromCurrentJson(resp.data);
  }

  // --- CHANGED METHOD ---
  // We keep the name 'fetchOneCall' so weather_repository_impl.dart stays happy.
  // BUT internally, we use the FREE '/forecast' logic.
  Future<ForecastModel> fetchOneCall(double lat, double lon) async {
    // 1. Use the FREE endpoint
    final url = '${AppConstants.openWeatherBase}/forecast';

    final resp = await dio.get(
      url,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'appid': kOpenWeatherApiKey,
        'units': 'metric',
        // 'exclude' is removed because the free API doesn't support it
      },
    );

    // 2. Use the new adapter we created in the model
    return ForecastModel.fromForecastJson(resp.data);
  }
  // ---------------------

  Future<Map<String, dynamic>> geocodeCity(String city) async {
    final url = '${AppConstants.geocodingBase}/direct';
    final resp = await dio.get(
      url,
      queryParameters: {'q': city, 'limit': 1, 'appid': kOpenWeatherApiKey},
    );
    if ((resp.data as List).isEmpty) throw Exception('City not found');
    return (resp.data as List).first as Map<String, dynamic>;
  }
}
