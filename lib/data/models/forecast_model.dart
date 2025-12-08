class ForecastModel {
  final List hourly;
  final List daily;

  ForecastModel({required this.hourly, required this.daily});

  // This is the "Magic Adapter"
  // It takes the Free API data and converts it into 'hourly' and 'daily' lists
  factory ForecastModel.fromForecastJson(Map<String, dynamic> json) {
    final rawList = json['list'] as List;

    // 1. "Hourly": We use the raw 3-hour intervals from the free API
    final hourlyData = rawList;

    // 2. "Daily": We filter the list to find only the data for 12:00 PM
    // This simulates a "Daily Forecast" by taking the noon weather for each day.
    final dailyData = rawList.where((item) {
      final dateString =
          item['dt_txt'] as String; // format: "2022-08-30 12:00:00"
      return dateString.contains('12:00:00');
    }).toList();

    return ForecastModel(hourly: hourlyData, daily: dailyData);
  }

  // Keeping your old constructor just in case, though it won't be used now
  factory ForecastModel.fromOneCall(Map<String, dynamic> json) {
    return ForecastModel(
      hourly: json['hourly'] as List,
      daily: json['daily'] as List,
    );
  }
}
