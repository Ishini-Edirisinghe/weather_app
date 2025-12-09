class WeatherModel {
  final int dt;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;
  // --- NEW FIELDS ---
  final int sunrise;
  final int sunset;

  WeatherModel({
    required this.dt,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
    required this.sunrise,
    required this.sunset,
  });

  factory WeatherModel.fromCurrentJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first;
    return WeatherModel(
      dt: json['dt'],
      temp: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'], // Already existed
      windSpeed: (json['wind']['speed'] as num).toDouble(), // Already existed
      description: weather['description'],
      icon: weather['icon'],
      // --- Parse Sunrise/Sunset from 'sys' object ---
      sunrise: json['sys']['sunrise'] ?? 0,
      sunset: json['sys']['sunset'] ?? 0,
    );
  }
}
