import 'dart:convert';
import '../../domain/entities/weather_entity.dart';
import '../../domain/entities/weather_alert.dart';
import '../datasources/remote_datasource.dart';
import '../datasources/local_datasource.dart';

class WeatherRepositoryImpl {
  final RemoteDatasource remote;
  final LocalDatasource local;

  WeatherRepositoryImpl({required this.remote, required this.local});

  // --- SEARCH HISTORY METHODS ---
  Future<void> saveSearch(String query) async {
    await local.saveSearchHistory(query);
  }

  Future<List<String>> getSearchHistory() async {
    return local.getSearchHistory();
  }

  // NEW: Clear All
  Future<void> clearSearchHistory() async {
    await local.clearSearchHistory();
  }

  // NEW: Delete Item
  Future<void> deleteSearchItem(String query) async {
    await local.deleteSearchItem(query);
  }

  // --- WEATHER DATA METHODS ---
  Future<WeatherEntity> getCurrentWeatherByCity(String city) async {
    try {
      // 1. Fetch Remote Data
      final weatherModel = await remote.fetchCurrentByCity(city);
      final geo = await remote.geocodeCity(city);

      final lat = (geo['lat'] as num).toDouble();
      final lon = (geo['lon'] as num).toDouble();
      final country = geo['country'] as String? ?? '';
      final state = geo['state'] as String? ?? '';

      final forecast = await remote.fetchOneCall(lat, lon);

      // 2. Generate Synthetic Alerts (since free API lacks them)
      final List<Map<String, dynamic>> generatedAlerts = [];

      // TEST ALERT (Delete this block when done testing)
      generatedAlerts.add({
        'sender_name': 'Test System',
        'event': 'TEST ALERT: Heat Wave',
        'description': 'This is a test alert to verify the UI. Please ignore.',
        'start': DateTime.now().millisecondsSinceEpoch,
        'end': DateTime.now()
            .add(const Duration(hours: 48))
            .millisecondsSinceEpoch,
      });

      if (weatherModel.windSpeed > 10.0) {
        generatedAlerts.add({
          'sender_name': 'System',
          'event': 'High Wind Warning',
          'description':
              'Wind speeds are exceeding 10 m/s. Secure loose objects.',
          'start': DateTime.now().millisecondsSinceEpoch,
          'end': DateTime.now()
              .add(const Duration(hours: 6))
              .millisecondsSinceEpoch,
        });
      }

      if (weatherModel.description.toLowerCase().contains('rain')) {
        generatedAlerts.add({
          'sender_name': 'System',
          'event': 'Rain Alert',
          'description': 'Rain detected in $city. Drive carefully.',
          'start': DateTime.now().millisecondsSinceEpoch,
          'end': DateTime.now()
              .add(const Duration(hours: 4))
              .millisecondsSinceEpoch,
        });
      }

      // 3. Create JSON Payload
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
        'alerts': generatedAlerts,
      });

      // 4. Cache Data
      await local.cacheCity(city, lat, lon, country, state, payload);

      // 5. Check Favorite Status
      final cached = await local.getCachedCity(city);
      final isFav = (cached?['is_favorite'] as int? ?? 0) == 1;

      // 6. Map to Entity
      final alertEntities = generatedAlerts
          .map(
            (a) => WeatherAlert(
              city: city,
              sender: a['sender_name'],
              event: a['event'],
              description: a['description'],
              start: DateTime.fromMillisecondsSinceEpoch(a['start']),
              end: DateTime.fromMillisecondsSinceEpoch(a['end']),
            ),
          )
          .toList();

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
        alerts: alertEntities,
      );
    } catch (e) {
      // Fallback to Cache
      final cached = await local.getCachedCity(city);
      if (cached != null) {
        final data =
            jsonDecode(cached['json'] as String) as Map<String, dynamic>;
        final current = data['current'];
        final isFav = (cached['is_favorite'] as int? ?? 0) == 1;

        final rawAlerts = (data['alerts'] as List?) ?? [];
        final alertEntities = rawAlerts
            .map(
              (a) => WeatherAlert(
                city: city,
                sender: a['sender_name'] ?? 'System',
                event: a['event'] ?? 'Alert',
                description: a['description'] ?? '',
                start: DateTime.fromMillisecondsSinceEpoch(a['start'] ?? 0),
                end: DateTime.fromMillisecondsSinceEpoch(a['end'] ?? 0),
              ),
            )
            .toList();

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
          alerts: alertEntities,
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
      final city = row['city'] as String;

      final rawAlerts = (data['alerts'] as List?) ?? [];
      final alertEntities = rawAlerts
          .map(
            (a) => WeatherAlert(
              city: city,
              sender: a['sender_name'] ?? 'System',
              event: a['event'] ?? 'Alert',
              description: a['description'] ?? '',
              start: DateTime.fromMillisecondsSinceEpoch(a['start'] ?? 0),
              end: DateTime.fromMillisecondsSinceEpoch(a['end'] ?? 0),
            ),
          )
          .toList();

      return WeatherEntity(
        city: city,
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
        alerts: alertEntities,
      );
    }).toList();
  }

  Future<void> deleteAlert(String city, WeatherAlert alertToRemove) async {
    final cached = await local.getCachedCity(city);
    if (cached == null) return;

    final data = jsonDecode(cached['json'] as String) as Map<String, dynamic>;
    List<dynamic> alertsJson = (data['alerts'] as List?) ?? [];

    alertsJson.removeWhere(
      (a) =>
          a['event'] == alertToRemove.event &&
          a['description'] == alertToRemove.description,
    );

    data['alerts'] = alertsJson;
    final newPayload = jsonEncode(data);

    await local.cacheCity(
      city,
      (cached['lat'] as num).toDouble(),
      (cached['lon'] as num).toDouble(),
      cached['country'] as String? ?? '',
      cached['state'] as String? ?? '',
      newPayload,
    );
  }
}

// import 'dart:convert';
// import '../../domain/entities/weather_entity.dart';
// import '../../domain/entities/weather_alert.dart';
// import '../datasources/remote_datasource.dart';
// import '../datasources/local_datasource.dart';

// class WeatherRepositoryImpl {
//   final RemoteDatasource remote;
//   final LocalDatasource local;

//   WeatherRepositoryImpl({required this.remote, required this.local});

//   // --- SEARCH HISTORY METHODS ---
//   Future<void> saveSearch(String query) async {
//     await local.saveSearchHistory(query);
//   }

//   Future<List<String>> getSearchHistory() async {
//     return local.getSearchHistory();
//   }

//   // --- WEATHER DATA METHODS ---
//   Future<WeatherEntity> getCurrentWeatherByCity(String city) async {
//     try {
//       // 1. Fetch Remote Data
//       final weatherModel = await remote.fetchCurrentByCity(city);
//       final geo = await remote.geocodeCity(city);

//       final lat = (geo['lat'] as num).toDouble();
//       final lon = (geo['lon'] as num).toDouble();
//       final country = geo['country'] as String? ?? '';
//       final state = geo['state'] as String? ?? '';

//       final forecast = await remote.fetchOneCall(lat, lon);

//       // 2. Generate Synthetic Alerts (since free API lacks them)
//       final List<Map<String, dynamic>> generatedAlerts = [];

//       if (weatherModel.windSpeed > 10.0) {
//         generatedAlerts.add({
//           'sender_name': 'System',
//           'event': 'High Wind Warning',
//           'description':
//               'Wind speeds are exceeding 10 m/s. Secure loose objects.',
//           'start': DateTime.now().millisecondsSinceEpoch,
//           'end': DateTime.now()
//               .add(const Duration(hours: 6))
//               .millisecondsSinceEpoch,
//         });
//       }

//       if (weatherModel.description.toLowerCase().contains('rain')) {
//         generatedAlerts.add({
//           'sender_name': 'System',
//           'event': 'Rain Alert',
//           'description': 'Rain detected in $city. Drive carefully.',
//           'start': DateTime.now().millisecondsSinceEpoch,
//           'end': DateTime.now()
//               .add(const Duration(hours: 4))
//               .millisecondsSinceEpoch,
//         });
//       }

//       // 3. Create JSON Payload
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
//         'alerts': generatedAlerts,
//       });

//       // 4. Cache Data
//       await local.cacheCity(city, lat, lon, country, state, payload);

//       // 5. Check Favorite Status
//       final cached = await local.getCachedCity(city);
//       final isFav = (cached?['is_favorite'] as int? ?? 0) == 1;

//       // 6. Map to Entity
//       final alertEntities = generatedAlerts
//           .map(
//             (a) => WeatherAlert(
//               city: city,
//               sender: a['sender_name'],
//               event: a['event'],
//               description: a['description'],
//               start: DateTime.fromMillisecondsSinceEpoch(a['start']),
//               end: DateTime.fromMillisecondsSinceEpoch(a['end']),
//             ),
//           )
//           .toList();

//       return WeatherEntity(
//         city: city,
//         lat: lat,
//         lon: lon,
//         country: country,
//         state: state,
//         temp: weatherModel.temp,
//         description: weatherModel.description,
//         iconCode: weatherModel.icon,
//         forecastJson: payload,
//         humidity: weatherModel.humidity,
//         windSpeed: weatherModel.windSpeed,
//         sunrise: weatherModel.sunrise,
//         sunset: weatherModel.sunset,
//         isFavorite: isFav,
//         alerts: alertEntities,
//       );
//     } catch (e) {
//       // Fallback to Cache
//       final cached = await local.getCachedCity(city);
//       if (cached != null) {
//         final data =
//             jsonDecode(cached['json'] as String) as Map<String, dynamic>;
//         final current = data['current'];
//         final isFav = (cached['is_favorite'] as int? ?? 0) == 1;

//         final rawAlerts = (data['alerts'] as List?) ?? [];
//         final alertEntities = rawAlerts
//             .map(
//               (a) => WeatherAlert(
//                 city: city,
//                 sender: a['sender_name'] ?? 'System',
//                 event: a['event'] ?? 'Alert',
//                 description: a['description'] ?? '',
//                 start: DateTime.fromMillisecondsSinceEpoch(a['start'] ?? 0),
//                 end: DateTime.fromMillisecondsSinceEpoch(a['end'] ?? 0),
//               ),
//             )
//             .toList();

//         return WeatherEntity(
//           city: city,
//           lat: (cached['lat'] as num).toDouble(),
//           lon: (cached['lon'] as num).toDouble(),
//           country: cached['country'] as String? ?? '',
//           state: cached['state'] as String? ?? '',
//           temp: (current['temp'] as num).toDouble(),
//           description: current['description'] as String,
//           iconCode: current['icon'] as String,
//           forecastJson: cached['json'] as String,
//           humidity: current['humidity'] as int? ?? 0,
//           windSpeed: (current['wind_speed'] as num?)?.toDouble() ?? 0.0,
//           sunrise: current['sunrise'] as int? ?? 0,
//           sunset: current['sunset'] as int? ?? 0,
//           isFavorite: isFav,
//           alerts: alertEntities,
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
//       final city = row['city'] as String;

//       final rawAlerts = (data['alerts'] as List?) ?? [];
//       final alertEntities = rawAlerts
//           .map(
//             (a) => WeatherAlert(
//               city: city,
//               sender: a['sender_name'] ?? 'System',
//               event: a['event'] ?? 'Alert',
//               description: a['description'] ?? '',
//               start: DateTime.fromMillisecondsSinceEpoch(a['start'] ?? 0),
//               end: DateTime.fromMillisecondsSinceEpoch(a['end'] ?? 0),
//             ),
//           )
//           .toList();

//       return WeatherEntity(
//         city: city,
//         lat: (row['lat'] as num).toDouble(),
//         lon: (row['lon'] as num).toDouble(),
//         country: row['country'] as String? ?? '',
//         state: row['state'] as String? ?? '',
//         temp: (current['temp'] as num).toDouble(),
//         description: current['description'] as String,
//         iconCode: current['icon'] as String,
//         forecastJson: row['json'] as String,
//         humidity: current['humidity'] as int? ?? 0,
//         windSpeed: (current['wind_speed'] as num?)?.toDouble() ?? 0.0,
//         sunrise: current['sunrise'] as int? ?? 0,
//         sunset: current['sunset'] as int? ?? 0,
//         isFavorite: true,
//         alerts: alertEntities,
//       );
//     }).toList();
//   }

//   Future<void> deleteAlert(String city, WeatherAlert alertToRemove) async {
//     final cached = await local.getCachedCity(city);
//     if (cached == null) return;

//     final data = jsonDecode(cached['json'] as String) as Map<String, dynamic>;
//     List<dynamic> alertsJson = (data['alerts'] as List?) ?? [];

//     alertsJson.removeWhere(
//       (a) =>
//           a['event'] == alertToRemove.event &&
//           a['description'] == alertToRemove.description,
//     );

//     data['alerts'] = alertsJson;
//     final newPayload = jsonEncode(data);

//     await local.cacheCity(
//       city,
//       (cached['lat'] as num).toDouble(),
//       (cached['lon'] as num).toDouble(),
//       cached['country'] as String? ?? '',
//       cached['state'] as String? ?? '',
//       newPayload,
//     );
//   }
// }
