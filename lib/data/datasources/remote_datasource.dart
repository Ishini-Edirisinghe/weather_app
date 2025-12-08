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

  Future<ForecastModel> fetchOneCall(double lat, double lon) async {
    final url = '${AppConstants.openWeatherBase}/onecall';
    final resp = await dio.get(
      url,
      queryParameters: {
        'lat': lat,
        'lon': lon,
        'exclude': 'minutely',
        'appid': kOpenWeatherApiKey,
        'units': 'metric',
      },
    );
    return ForecastModel.fromOneCall(resp.data);
  }

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
