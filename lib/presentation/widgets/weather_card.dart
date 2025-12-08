import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final String city;
  final double temp;
  final String description;
  final String iconCode;

  const WeatherCard({
    super.key,
    required this.city,
    required this.temp,
    required this.description,
    required this.iconCode,
  });

  @override
  Widget build(BuildContext context) {
    final iconUrl = 'https://openweathermap.org/img/wn/$iconCode@2x.png';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Image.network(iconUrl, width: 64, height: 64),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city, style: Theme.of(context).textTheme.titleLarge),
                Text(
                  '${temp.toStringAsFixed(1)} °C',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(description),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
