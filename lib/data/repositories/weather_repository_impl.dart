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
      final geo = await remote.geocodeCity(city);

      final lat = (geo['lat'] as num).toDouble();
      final lon = (geo['lon'] as num).toDouble();
      // Fetch Country and State (Region)
      final country = geo['country'] as String? ?? '';
      final state = geo['state'] as String? ?? '';

      final forecast = await remote.fetchOneCall(lat, lon);

      final payload = jsonEncode({
        'current': {
          'dt': weatherModel.dt,
          'temp': weatherModel.temp,
          'feels_like': weatherModel.feelsLike,
          'humidity': weatherModel.humidity,
          'wind_speed': weatherModel.windSpeed,
          'description': weatherModel.description,
          'icon': weatherModel.icon,
          'sunrise': weatherModel.sunrise,
          'sunset': weatherModel.sunset,
        },
        'forecast': {'hourly': forecast.hourly, 'daily': forecast.daily},
      });

      // Save to Cache with Country/State
      await local.cacheCity(city, lat, lon, country, state, payload);

      final cached = await local.getCachedCity(city);
      final isFav = (cached?['is_favorite'] as int? ?? 0) == 1;

      return WeatherEntity(
        city: city,
        lat: lat,
        lon: lon,
        country: country,
        state: state,
        temp: weatherModel.temp,
        description: weatherModel.description,
        iconCode: weatherModel.icon,
        forecastJson: payload,
        humidity: weatherModel.humidity,
        windSpeed: weatherModel.windSpeed,
        sunrise: weatherModel.sunrise,
        sunset: weatherModel.sunset,
        isFavorite: isFav,
      );
    } catch (e) {
      // Fallback
      final cached = await local.getCachedCity(city);
      if (cached != null) {
        final data =
            jsonDecode(cached['json'] as String) as Map<String, dynamic>;
        final current = data['current'];
        final isFav = (cached['is_favorite'] as int? ?? 0) == 1;

        return WeatherEntity(
          city: city,
          lat: (cached['lat'] as num).toDouble(),
          lon: (cached['lon'] as num).toDouble(),
          country: cached['country'] as String? ?? '',
          state: cached['state'] as String? ?? '',
          temp: (current['temp'] as num).toDouble(),
          description: current['description'] as String,
          iconCode: current['icon'] as String,
          forecastJson: cached['json'] as String,
          humidity: current['humidity'] as int? ?? 0,
          windSpeed: (current['wind_speed'] as num?)?.toDouble() ?? 0.0,
          sunrise: current['sunrise'] as int? ?? 0,
          sunset: current['sunset'] as int? ?? 0,
          isFavorite: isFav,
        );
      }
      rethrow;
    }
  }

  Future<void> toggleFavorite(String city, bool isFavorite) async {
    await local.setFavorite(city, isFavorite);
  }

  Future<List<WeatherEntity>> getFavorites() async {
    final rows = await local.getFavorites();
    return rows.map((row) {
      final data = jsonDecode(row['json'] as String) as Map<String, dynamic>;
      final current = data['current'];

      return WeatherEntity(
        city: row['city'] as String,
        lat: (row['lat'] as num).toDouble(),
        lon: (row['lon'] as num).toDouble(),
        country: row['country'] as String? ?? '',
        state: row['state'] as String? ?? '',
        temp: (current['temp'] as num).toDouble(),
        description: current['description'] as String,
        iconCode: current['icon'] as String,
        forecastJson: row['json'] as String,
        humidity: current['humidity'] as int? ?? 0,
        windSpeed: (current['wind_speed'] as num?)?.toDouble() ?? 0.0,
        sunrise: current['sunrise'] as int? ?? 0,
        sunset: current['sunset'] as int? ?? 0,
        isFavorite: true,
      );
    }).toList();
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
//       final geo = await remote.geocodeCity(city);
//       final lat = (geo['lat'] as num).toDouble();
//       final lon = (geo['lon'] as num).toDouble();

//       // Get country code (e.g. US, GB, LK) from geocoding response
//       final country = geo['country'] as String? ?? 'Unknown';

//       final forecast = await remote.fetchOneCall(lat, lon);

//       final payload = jsonEncode({
//         'current': {
//           'dt': weatherModel.dt,
//           'temp': weatherModel.temp,
//           'feels_like': weatherModel.feelsLike,
//           'humidity': weatherModel.humidity,
//           'wind_speed': weatherModel.windSpeed,
//           'description': weatherModel.description,
//           'icon': weatherModel.icon,
//           'sunrise': weatherModel.sunrise,
//           'sunset': weatherModel.sunset,
//         },
//         'forecast': {'hourly': forecast.hourly, 'daily': forecast.daily},
//       });

//       // Pass 'country' to cache
//       await local.cacheCity(city, lat, lon, country, payload);

//       final cached = await local.getCachedCity(city);
//       final isFav = (cached?['is_favorite'] as int? ?? 0) == 1;

//       return WeatherEntity(
//         city: city,
//         lat: lat,
//         lon: lon,
//         country: country, // Set country
//         temp: weatherModel.temp,
//         description: weatherModel.description,
//         iconCode: weatherModel.icon,
//         forecastJson: payload,
//         humidity: weatherModel.humidity,
//         windSpeed: weatherModel.windSpeed,
//         sunrise: weatherModel.sunrise,
//         sunset: weatherModel.sunset,
//         isFavorite: isFav,
//       );
//     } catch (e) {
//       final cached = await local.getCachedCity(city);
//       if (cached != null) {
//         final data =
//             jsonDecode(cached['json'] as String) as Map<String, dynamic>;
//         final current = data['current'];
//         final isFav = (cached['is_favorite'] as int? ?? 0) == 1;

//         // Get country from cache
//         final country = cached['country'] as String? ?? 'Unknown';

//         return WeatherEntity(
//           city: city,
//           lat: (cached['lat'] as num).toDouble(),
//           lon: (cached['lon'] as num).toDouble(),
//           country: country,
//           temp: (current['temp'] as num).toDouble(),
//           description: current['description'] as String,
//           iconCode: current['icon'] as String,
//           forecastJson: cached['json'] as String,
//           humidity: current['humidity'] as int? ?? 0,
//           windSpeed: (current['wind_speed'] as num?)?.toDouble() ?? 0.0,
//           sunrise: current['sunrise'] as int? ?? 0,
//           sunset: current['sunset'] as int? ?? 0,
//           isFavorite: isFav,
//         );
//       }
//       rethrow;
//     }
//   }

//   Future<void> toggleFavorite(String city, bool isFavorite) async {
//     await local.setFavorite(city, isFavorite);
//   }

//   Future<List<WeatherEntity>> getFavorites() async {
//     final rows = await local.getFavorites();
//     return rows.map((row) {
//       final data = jsonDecode(row['json'] as String) as Map<String, dynamic>;
//       final current = data['current'];

//       return WeatherEntity(
//         city: row['city'] as String,
//         lat: (row['lat'] as num).toDouble(),
//         lon: (row['lon'] as num).toDouble(),
//         country: row['country'] as String? ?? 'Unknown', // Get from DB
//         temp: (current['temp'] as num).toDouble(),
//         description: current['description'] as String,
//         iconCode: current['icon'] as String,
//         forecastJson: row['json'] as String,
//         humidity: current['humidity'] as int? ?? 0,
//         windSpeed: (current['wind_speed'] as num?)?.toDouble() ?? 0.0,
//         sunrise: current['sunrise'] as int? ?? 0,
//         sunset: current['sunset'] as int? ?? 0,
//         isFavorite: true,
//       );
//     }).toList();
//   }
// }
