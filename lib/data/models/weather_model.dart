class WeatherModel {
  final int dt;
  final double temp;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String description;
  final String icon;

  WeatherModel({
    required this.dt,
    required this.temp,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.icon,
  });

  factory WeatherModel.fromCurrentJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).first;
    return WeatherModel(
      dt: json['dt'],
      temp: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      humidity: json['main']['humidity'],
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      description: weather['description'],
      icon: weather['icon'],
    );
  }
}
