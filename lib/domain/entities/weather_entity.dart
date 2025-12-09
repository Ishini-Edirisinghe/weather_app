class WeatherEntity {
  final String city;
  final double lat;
  final double lon;
  final String country; // e.g. "LK", "US"
  final String state; // e.g. "Western Province"
  final double temp;
  final String description;
  final String iconCode;
  final String forecastJson;
  final int humidity;
  final double windSpeed;
  final int sunrise;
  final int sunset;
  final bool isFavorite;

  WeatherEntity({
    required this.city,
    required this.lat,
    required this.lon,
    required this.country,
    required this.state,
    required this.temp,
    required this.description,
    required this.iconCode,
    required this.forecastJson,
    required this.humidity,
    required this.windSpeed,
    required this.sunrise,
    required this.sunset,
    this.isFavorite = false,
  });
}
