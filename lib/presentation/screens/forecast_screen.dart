import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../viewmodels/weather_viewmodel.dart';
import '../../core/utils.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);
    if (vm.current == null)
      return const Scaffold(body: Center(child: Text('No forecast')));
    final payload =
        jsonDecode(vm.current!.forecastJson) as Map<String, dynamic>;
    final hourly = payload['forecast']['hourly'] as List;

    // take first 24
    final points = hourly.take(24).toList();

    final spots = points.asMap().entries.map((e) {
      final idx = e.key.toDouble();
      final temp = (e.value['temp'] as num).toDouble();
      return FlSpot(idx, temp);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Forecast — ${vm.current!.city}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: points.length,
                itemBuilder: (context, i) {
                  final item = points[i];
                  final ts = item['dt'] as int;
                  final temp = (item['temp'] as num).toDouble();
                  return ListTile(
                    title: Text(formatHourFromTimestamp(ts)),
                    subtitle: Text('${temp.toStringAsFixed(1)} °C'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
