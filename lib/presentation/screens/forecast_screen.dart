import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Ensure you have intl package
import '../viewmodels/weather_viewmodel.dart';
// import '../../core/utils.dart'; // You can keep this if you have custom utils

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  // Helper to safely extract temperature
  double _getTemp(Map<String, dynamic> item) {
    // 1. Try accessing standard OpenWeatherMap structure: item['main']['temp']
    if (item['main'] != null && item['main']['temp'] != null) {
      return (item['main']['temp'] as num).toDouble();
    }
    // 2. Try accessing flat structure (if cached differently): item['temp']
    if (item['temp'] != null) {
      return (item['temp'] as num).toDouble();
    }
    // 3. Default fallback
    return 0.0;
  }

  // Helper to format timestamp
  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('E, h a').format(date); // e.g. "Mon, 3 PM"
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);

    if (vm.current == null || vm.current!.forecastJson.isEmpty) {
      return const Scaffold(body: Center(child: Text('No forecast data')));
    }

    List points = [];
    try {
      final payload =
          jsonDecode(vm.current!.forecastJson) as Map<String, dynamic>;
      // Safely access the list, defaulting to empty if null
      points =
          (payload['forecast']['hourly'] as List?)?.take(24).toList() ?? [];
    } catch (e) {
      return const Scaffold(
        body: Center(child: Text('Error parsing forecast data')),
      );
    }

    // 1. Prepare Chart Data (Spots)
    final spots = points.asMap().entries.map((e) {
      final index = e.key.toDouble();
      final temp = _getTemp(e.value as Map<String, dynamic>);
      return FlSpot(index, temp);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Forecast — ${vm.current!.city}')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // --- CHART SECTION ---
            SizedBox(
              height: 220,
              child: points.isEmpty
                  ? const Center(child: Text("Not enough data for chart"))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          show: false,
                        ), // Hide messy axis labels
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            const Divider(),

            // --- LIST SECTION ---
            Expanded(
              child: ListView.builder(
                itemCount: points.length,
                itemBuilder: (context, i) {
                  final item = points[i] as Map<String, dynamic>;
                  final ts = item['dt'] as int? ?? 0;
                  final temp = _getTemp(item);
                  final description = (item['weather'] as List).isNotEmpty
                      ? item['weather'][0]['description']
                      : '';
                  final iconCode = (item['weather'] as List).isNotEmpty
                      ? item['weather'][0]['icon']
                      : '';

                  return ListTile(
                    leading: Image.network(
                      'https://openweathermap.org/img/wn/$iconCode.png',
                      errorBuilder: (_, __, ___) => const Icon(Icons.cloud),
                    ),
                    title: Text(_formatTime(ts)),
                    subtitle: Text(description),
                    trailing: Text(
                      '${temp.toStringAsFixed(1)} °C',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../viewmodels/weather_viewmodel.dart';
// import '../../core/utils.dart';

// class ForecastScreen extends StatelessWidget {
//   const ForecastScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<WeatherViewModel>(context);
//     if (vm.current == null) {
//       return const Scaffold(body: Center(child: Text('No forecast')));
//     }
//     final payload =
//         jsonDecode(vm.current!.forecastJson) as Map<String, dynamic>;
//     final hourly = payload['forecast']['hourly'] as List;

//     // take first 24
//     final points = hourly.take(24).toList();

//     final spots = points.asMap().entries.map((e) {
//       final idx = e.key.toDouble();
//       final temp = (e.value['temp'] as num).toDouble();
//       return FlSpot(idx, temp);
//     }).toList();

//     return Scaffold(
//       appBar: AppBar(title: Text('Forecast — ${vm.current!.city}')),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             SizedBox(
//               height: 220,
//               child: LineChart(
//                 LineChartData(
//                   lineBarsData: [
//                     LineChartBarData(
//                       spots: spots,
//                       isCurved: true,
//                       dotData: FlDotData(show: false),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: points.length,
//                 itemBuilder: (context, i) {
//                   final item = points[i];
//                   final ts = item['dt'] as int;
//                   final temp = (item['temp'] as num).toDouble();
//                   return ListTile(
//                     title: Text(formatHourFromTimestamp(ts)),
//                     subtitle: Text('${temp.toStringAsFixed(1)} °C'),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
