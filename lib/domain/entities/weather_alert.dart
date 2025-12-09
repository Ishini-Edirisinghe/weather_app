class WeatherAlert {
  final String city; // The city this alert belongs to
  final String sender; // e.g. "Met Dept" or "App System"
  final String event; // e.g. "High Wind Warning"
  final String description; // Full details
  final DateTime start;
  final DateTime end;

  WeatherAlert({
    required this.city,
    required this.sender,
    required this.event,
    required this.description,
    required this.start,
    required this.end,
  });
}
