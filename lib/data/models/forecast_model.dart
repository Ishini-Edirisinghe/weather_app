class ForecastModel {
  final List hourly; // raw hourly list
  final List daily; // raw daily list

  ForecastModel({required this.hourly, required this.daily});

  factory ForecastModel.fromOneCall(Map<String, dynamic> json) {
    return ForecastModel(
      hourly: json['hourly'] as List,
      daily: json['daily'] as List,
    );
  }
}
