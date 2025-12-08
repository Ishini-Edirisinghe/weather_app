import '../../domain/entities/weather_entity.dart';
import '../datasources/remote_datasource.dart';
import '../datasources/local_datasource.dart';
import 'dart:convert';

class WeatherRepositoryImpl {
  final RemoteDatasource remote;
  final LocalDatasource local;

  WeatherRepositoryImpl({required this.remote, required this.local});

  Future<WeatherEntity> getCurrentWeatherByCity(String city) async {
    try {
      final weatherModel = await remote.fetchCurrentByCity(city);
      // geocode to get coords
      final geo = await remote.geocodeCity(city);
      final lat = (geo['lat'] as num).toDouble();
      final lon = (geo['lon'] as num).toDouble();

      // fetch forecast
      final forecast = await remote.fetchOneCall(lat, lon);

      // cache combined payload
      // UPDATED: Added sunrise and sunset to the cache
      final payload = jsonEncode({
        'current': {
          'dt': weatherModel.dt,
          'temp': weatherModel.temp,
          'feels_like': weatherModel.feelsLike,
          'humidity': weatherModel.humidity,
          'wind_speed': weatherModel.windSpeed,
          'description': weatherModel.description,
          'icon': weatherModel.icon,
          'sunrise': weatherModel.sunrise, // <--- New
          'sunset': weatherModel.sunset, // <--- New
        },
        'forecast': {'hourly': forecast.hourly, 'daily': forecast.daily},
      });

      await local.cacheCity(city, lat, lon, payload);

      // UPDATED: Pass new fields to Entity
      return WeatherEntity(
        city: city,
        lat: lat,
        lon: lon,
        temp: weatherModel.temp,
        description: weatherModel.description,
        iconCode: weatherModel.icon,
        forecastJson: payload,
        // --- New Fields ---
        humidity: weatherModel.humidity,
        windSpeed: weatherModel.windSpeed,
        sunrise: weatherModel.sunrise,
        sunset: weatherModel.sunset,
      );
    } catch (e) {
      // fallback to cache
      final cached = await local.getCachedCity(city);
      if (cached != null) {
        final data =
            jsonDecode(cached['json'] as String) as Map<String, dynamic>;
        final current = data['current'];

        // UPDATED: Retrieve new fields from cache (with safety defaults)
        return WeatherEntity(
          city: city,
          lat: (cached['lat'] as num).toDouble(),
          lon: (cached['lon'] as num).toDouble(),
          temp: (current['temp'] as num).toDouble(),
          description: current['description'] as String,
          iconCode: current['icon'] as String,
          forecastJson: cached['json'] as String,
          // --- New Fields from Cache ---
          humidity: current['humidity'] as int? ?? 0,
          windSpeed: (current['wind_speed'] as num?)?.toDouble() ?? 0.0,
          sunrise: current['sunrise'] as int? ?? 0,
          sunset: current['sunset'] as int? ?? 0,
        );
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFavorites() async {
    return local.getAllFavorites();
  }
}
// import '../../domain/entities/weather_entity.dart';
// import '../datasources/remote_datasource.dart';
// import '../datasources/local_datasource.dart';
// import 'dart:convert';

// class WeatherRepositoryImpl {
//   final RemoteDatasource remote;
//   final LocalDatasource local;

//   WeatherRepositoryImpl({required this.remote, required this.local});

//   Future<WeatherEntity> getCurrentWeatherByCity(String city) async {
//     try {
//       final weatherModel = await remote.fetchCurrentByCity(city);
//       // geocode to get coords
//       final geo = await remote.geocodeCity(city);
//       final lat = (geo['lat'] as num).toDouble();
//       final lon = (geo['lon'] as num).toDouble();

//       // fetch forecast
//       final forecast = await remote.fetchOneCall(lat, lon);

//       // cache combined payload
//       final payload = jsonEncode({
//         'current': {
//           'dt': weatherModel.dt,
//           'temp': weatherModel.temp,
//           'feels_like': weatherModel.feelsLike,
//           'humidity': weatherModel.humidity,
//           'wind_speed': weatherModel.windSpeed,
//           'description': weatherModel.description,
//           'icon': weatherModel.icon,
//         },
//         'forecast': {'hourly': forecast.hourly, 'daily': forecast.daily},
//       });

//       await local.cacheCity(city, lat, lon, payload);

//       return WeatherEntity(
//         city: city,
//         lat: lat,
//         lon: lon,
//         temp: weatherModel.temp,
//         description: weatherModel.description,
//         iconCode: weatherModel.icon,
//         forecastJson: payload,
//       );
//     } catch (e) {
//       // fallback to cache
//       final cached = await local.getCachedCity(city);
//       if (cached != null) {
//         final data =
//             jsonDecode(cached['json'] as String) as Map<String, dynamic>;
//         final current = data['current'];
//         return WeatherEntity(
//           city: city,
//           lat: (cached['lat'] as num).toDouble(),
//           lon: (cached['lon'] as num).toDouble(),
//           temp: (current['temp'] as num).toDouble(),
//           description: current['description'] as String,
//           iconCode: current['icon'] as String,
//           forecastJson: cached['json'] as String,
//         );
//       }
//       rethrow;
//     }
//   }

//   Future<List<Map<String, dynamic>>> getFavorites() async {
//     return local.getAllFavorites();
//   }
// }
