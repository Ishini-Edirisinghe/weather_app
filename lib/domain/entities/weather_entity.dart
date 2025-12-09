class WeatherEntity {
  final String city;
  final double lat;
  final double lon;
  final String country;
  final double temp;
  final String description;
  final String iconCode;
  final String forecastJson; // raw cached payload

  // --- NEW FIELDS ---
  final int humidity;
  final double windSpeed;
  final int sunrise; // Unix timestamp
  final int sunset; // Unix timestamp
  final bool isFavorite;

  WeatherEntity({
    required this.city,
    required this.lat,
    required this.lon,
    required this.country,
    required this.temp,
    required this.description,
    required this.iconCode,
    required this.forecastJson,
    // Required in constructor
    required this.humidity,
    required this.windSpeed,
    required this.sunrise,
    required this.sunset,
    this.isFavorite = false,
  });
}
