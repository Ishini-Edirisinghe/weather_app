class WeatherEntity {
  final String city;
  final double lat;
  final double lon;
  final double temp;
  final String description;
  final String iconCode;
  final String forecastJson; // raw cached payload

  WeatherEntity({
    required this.city,
    required this.lat,
    required this.lon,
    required this.temp,
    required this.description,
    required this.iconCode,
    required this.forecastJson,
  });
}
