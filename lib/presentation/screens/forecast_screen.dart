import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../viewmodels/weather_viewmodel.dart';

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key});

  // Helper: Extract Temperature safely
  double _getTemp(Map<String, dynamic> item) {
    if (item['main'] != null && item['main']['temp'] != null) {
      return (item['main']['temp'] as num).toDouble();
    }
    if (item['temp'] != null) {
      return (item['temp'] as num).toDouble();
    }
    return 0.0;
  }

  // --- UPDATED HELPER: Get Real 5-Day Forecast ---
  List<Map<String, dynamic>> _getDailyForecast(List<dynamic> rawHourly) {
    final Map<String, Map<String, dynamic>> dailyMap = {};

    for (var item in rawHourly) {
      final dt = item['dt'] as int;
      final date = DateTime.fromMillisecondsSinceEpoch(dt * 1000);
      final dayKey = DateFormat('yyyy-MM-dd').format(date);

      // Simple logic: Take the first available data point for each unique day.
      // (Ideally, you'd target 12:00 PM, but this works for a general overview)
      if (!dailyMap.containsKey(dayKey)) {
        dailyMap[dayKey] = item as Map<String, dynamic>;
      }
    }

    // Return only the days provided by the API (usually 5)
    return dailyMap.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);

    if (vm.current == null || vm.current!.forecastJson.isEmpty) {
      return _buildNoDataState(context);
    }

    List<Map<String, dynamic>> dailyPoints = [];
    try {
      final payload =
          jsonDecode(vm.current!.forecastJson) as Map<String, dynamic>;
      final rawList = payload['forecast']['hourly'] as List;
      dailyPoints = _getDailyForecast(rawList);
    } catch (e) {
      print("Error parsing forecast: $e");
    }

    // Chart Data Spots
    final spots = dailyPoints.asMap().entries.map((e) {
      final index = e.key.toDouble();
      final temp = _getTemp(e.value);
      return FlSpot(index, temp);
    }).toList();

    // Min/Max for auto-scaling the chart Y-axis
    double minTemp = spots.isEmpty
        ? 0
        : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    double maxTemp = spots.isEmpty
        ? 30
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          '5-Day Forecast', // Updated Title
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF42A5F5), Color(0xFF7E57C2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // --- CHART SECTION ---
                Container(
                  height: 280, // Height for chart
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Temperature Trend",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: dailyPoints.isEmpty
                            ? const Center(
                                child: Text(
                                  "Not enough data",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(
                                      color: Colors.white.withOpacity(0.1),
                                      strokeWidth: 1,
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    // Bottom Axis: Dates
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 35,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          final index = value.toInt();
                                          if (index >= 0 &&
                                              index < dailyPoints.length) {
                                            final dt =
                                                dailyPoints[index]['dt'] as int;
                                            final date =
                                                DateTime.fromMillisecondsSinceEpoch(
                                                  dt * 1000,
                                                );
                                            // Format: "12 Oct"
                                            final dateStr = DateFormat(
                                              'd MMM',
                                            ).format(date);
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                              ),
                                              child: Text(
                                                dateStr,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                      ),
                                    ),
                                    // Left Axis: Temperature
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: 5,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          return Text(
                                            '${value.toInt()}°',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  minX: 0,
                                  maxX: (dailyPoints.length - 1).toDouble(),
                                  minY: minTemp - 5,
                                  maxY: maxTemp + 5,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: true,
                                      color: Colors.white,
                                      barWidth: 3,
                                      isStrokeCapRound: true,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter:
                                            (spot, percent, barData, index) =>
                                                FlDotCirclePainter(
                                                  radius: 4,
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                  strokeColor: const Color(
                                                    0xFF7E57C2,
                                                  ),
                                                ),
                                      ),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.3),
                                            Colors.white.withOpacity(0.0),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  "Daily Forecast",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // --- LIST SECTION ---
                Expanded(
                  child: ListView.builder(
                    itemCount: dailyPoints.length,
                    itemBuilder: (context, i) {
                      final item = dailyPoints[i];
                      final ts = item['dt'] as int? ?? 0;
                      final date = DateTime.fromMillisecondsSinceEpoch(
                        ts * 1000,
                      );

                      final temp = _getTemp(item);
                      final description = (item['weather'] as List).isNotEmpty
                          ? item['weather'][0]['description']
                          : '';
                      final iconCode = (item['weather'] as List).isNotEmpty
                          ? item['weather'][0]['icon']
                          : '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          // Leading: "Mon, 12 Oct"
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('E').format(date),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                DateFormat('d MMM').format(date),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          title: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(
                                  'https://openweathermap.org/img/wn/$iconCode.png',
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.cloud,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    description,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Text(
                            '${temp.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7E57C2), Color(0xFF7E57C2)],
          ),
        ),
        child: const Center(
          child: Text(
            'No forecast data available',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart';
// import '../viewmodels/weather_viewmodel.dart';

// class ForecastScreen extends StatelessWidget {
//   const ForecastScreen({super.key});

//   // Helper: Extract Temperature
//   double _getTemp(Map<String, dynamic> item) {
//     if (item['main'] != null && item['main']['temp'] != null) {
//       return (item['main']['temp'] as num).toDouble();
//     }
//     if (item['temp'] != null) {
//       return (item['temp'] as num).toDouble();
//     }
//     return 0.0;
//   }

//   // Helper: Get Daily Data (One entry per day, e.g., at 12:00 PM)
//   List<Map<String, dynamic>> _getDailyForecast(List<dynamic> rawHourly) {
//     final Map<String, Map<String, dynamic>> dailyMap = {};

//     for (var item in rawHourly) {
//       final dt = item['dt'] as int;
//       final date = DateTime.fromMillisecondsSinceEpoch(dt * 1000);
//       final dayKey = DateFormat('yyyy-MM-dd').format(date);

//       // Prefer the entry closest to 12:00 PM
//       // For simplicity, we just take the first entry for each day if not set,
//       // or update it if this entry is closer to noon.
//       if (!dailyMap.containsKey(dayKey)) {
//         dailyMap[dayKey] = item as Map<String, dynamic>;
//       } else {
//         // Optional: Logic to find noon could go here.
//         // For now, first entry is sufficient for the chart trend.
//       }
//     }
//     return dailyMap.values.toList().take(7).toList(); // Return 7 days
//   }

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<WeatherViewModel>(context);

//     if (vm.current == null || vm.current!.forecastJson.isEmpty) {
//       return Scaffold(
//         extendBodyBehindAppBar: true,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           iconTheme: const IconThemeData(color: Colors.white),
//         ),
//         body: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [Color(0xFF7E57C2), Color(0xFF7E57C2)],
//             ),
//           ),
//           child: const Center(
//             child: Text(
//               'No forecast data available',
//               style: TextStyle(color: Colors.white, fontSize: 18),
//             ),
//           ),
//         ),
//       );
//     }

//     List<Map<String, dynamic>> dailyPoints = [];
//     try {
//       final payload =
//           jsonDecode(vm.current!.forecastJson) as Map<String, dynamic>;
//       final rawList = payload['forecast']['hourly'] as List;
//       dailyPoints = _getDailyForecast(rawList);
//     } catch (e) {
//       print("Error parsing forecast: $e");
//     }

//     // Chart Data
//     final spots = dailyPoints.asMap().entries.map((e) {
//       final index = e.key.toDouble();
//       final temp = _getTemp(e.value);
//       return FlSpot(index, temp);
//     }).toList();

//     // Min/Max for Chart Scaling
//     double minTemp = spots.isEmpty
//         ? 0
//         : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
//     double maxTemp = spots.isEmpty
//         ? 30
//         : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);

//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         title: const Text(
//           '7-Day Forecast',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF7E57C2), Color(0xFF7E57C2)],
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const SizedBox(height: 10),

//                 // --- CHART SECTION ---
//                 Container(
//                   height: 250,
//                   padding: const EdgeInsets.all(16),
//                   decoration: BoxDecoration(
//                     color: Colors.white.withOpacity(0.15),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(color: Colors.white.withOpacity(0.2)),
//                   ),
//                   child: Column(
//                     children: [
//                       const Text(
//                         "Temperature Trend",
//                         style: TextStyle(color: Colors.white70, fontSize: 14),
//                       ),
//                       const SizedBox(height: 20),
//                       Expanded(
//                         child: dailyPoints.isEmpty
//                             ? const Center(
//                                 child: Text(
//                                   "Not enough data",
//                                   style: TextStyle(color: Colors.white),
//                                 ),
//                               )
//                             : LineChart(
//                                 LineChartData(
//                                   gridData: FlGridData(
//                                     show: true,
//                                     drawVerticalLine: false,
//                                     getDrawingHorizontalLine: (value) {
//                                       return FlLine(
//                                         color: Colors.white.withOpacity(0.1),
//                                         strokeWidth: 1,
//                                       );
//                                     },
//                                   ),
//                                   titlesData: FlTitlesData(
//                                     show: true,
//                                     rightTitles: const AxisTitles(
//                                       sideTitles: SideTitles(showTitles: false),
//                                     ),
//                                     topTitles: const AxisTitles(
//                                       sideTitles: SideTitles(showTitles: false),
//                                     ),
//                                     bottomTitles: AxisTitles(
//                                       sideTitles: SideTitles(
//                                         showTitles: true,
//                                         reservedSize: 30,
//                                         interval: 1,
//                                         getTitlesWidget: (value, meta) {
//                                           final index = value.toInt();
//                                           if (index >= 0 &&
//                                               index < dailyPoints.length) {
//                                             final dt =
//                                                 dailyPoints[index]['dt'] as int;
//                                             final date =
//                                                 DateTime.fromMillisecondsSinceEpoch(
//                                                   dt * 1000,
//                                                 );
//                                             return Padding(
//                                               padding: const EdgeInsets.only(
//                                                 top: 8.0,
//                                               ),
//                                               child: Text(
//                                                 DateFormat(
//                                                   'E',
//                                                 ).format(date), // Mon, Tue
//                                                 style: const TextStyle(
//                                                   color: Colors.white70,
//                                                   fontSize: 12,
//                                                 ),
//                                               ),
//                                             );
//                                           }
//                                           return const Text('');
//                                         },
//                                       ),
//                                     ),
//                                     leftTitles: AxisTitles(
//                                       sideTitles: SideTitles(
//                                         showTitles: true,
//                                         interval:
//                                             5, // Show label every 5 degrees
//                                         reservedSize: 40,
//                                         getTitlesWidget: (value, meta) {
//                                           return Text(
//                                             '${value.toInt()}°',
//                                             style: const TextStyle(
//                                               color: Colors.white70,
//                                               fontSize: 12,
//                                             ),
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                   ),
//                                   borderData: FlBorderData(show: false),
//                                   minX: 0,
//                                   maxX: (dailyPoints.length - 1).toDouble(),
//                                   minY: minTemp - 5, // Add padding
//                                   maxY: maxTemp + 5,
//                                   lineBarsData: [
//                                     LineChartBarData(
//                                       spots: spots,
//                                       isCurved: true,
//                                       color: Colors.white, // White line
//                                       barWidth: 3,
//                                       isStrokeCapRound: true,
//                                       dotData: FlDotData(
//                                         show: true,
//                                         getDotPainter:
//                                             (spot, percent, barData, index) {
//                                               return FlDotCirclePainter(
//                                                 radius: 4,
//                                                 color: Colors.white,
//                                                 strokeWidth: 2,
//                                                 strokeColor: const Color(
//                                                   0xFF7E57C2,
//                                                 ),
//                                               );
//                                             },
//                                       ),
//                                       belowBarData: BarAreaData(
//                                         show: true,
//                                         gradient: LinearGradient(
//                                           colors: [
//                                             Colors.white.withOpacity(0.3),
//                                             Colors.white.withOpacity(0.0),
//                                           ],
//                                           begin: Alignment.topCenter,
//                                           end: Alignment.bottomCenter,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 24),
//                 const Text(
//                   "Daily Forecast",
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 12),

//                 // --- LIST SECTION ---
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: dailyPoints.length,
//                     itemBuilder: (context, i) {
//                       final item = dailyPoints[i];
//                       final ts = item['dt'] as int? ?? 0;
//                       final date = DateTime.fromMillisecondsSinceEpoch(
//                         ts * 1000,
//                       );

//                       final temp = _getTemp(item);
//                       final description = (item['weather'] as List).isNotEmpty
//                           ? item['weather'][0]['description']
//                           : '';
//                       final iconCode = (item['weather'] as List).isNotEmpty
//                           ? item['weather'][0]['icon']
//                           : '';

//                       return Container(
//                         margin: const EdgeInsets.only(bottom: 12),
//                         decoration: BoxDecoration(
//                           color: Colors.white.withOpacity(0.15),
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(
//                             color: Colors.white.withOpacity(0.1),
//                           ),
//                         ),
//                         child: ListTile(
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                             vertical: 8,
//                           ),
//                           leading: Text(
//                             DateFormat(
//                               'EEEE',
//                             ).format(date), // Full Day Name (Monday)
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                             ),
//                           ),
//                           title: Center(
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Image.network(
//                                   'https://openweathermap.org/img/wn/$iconCode.png',
//                                   width: 40,
//                                   height: 40,
//                                   errorBuilder: (_, __, ___) => const Icon(
//                                     Icons.cloud,
//                                     color: Colors.white,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   description,
//                                   style: const TextStyle(
//                                     color: Colors.white70,
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           trailing: Text(
//                             '${temp.toStringAsFixed(0)}°',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:intl/intl.dart'; // Ensure you have intl package
// import '../viewmodels/weather_viewmodel.dart';
// // import '../../core/utils.dart'; // You can keep this if you have custom utils

// class ForecastScreen extends StatelessWidget {
//   const ForecastScreen({super.key});

//   // Helper to safely extract temperature
//   double _getTemp(Map<String, dynamic> item) {
//     // 1. Try accessing standard OpenWeatherMap structure: item['main']['temp']
//     if (item['main'] != null && item['main']['temp'] != null) {
//       return (item['main']['temp'] as num).toDouble();
//     }
//     // 2. Try accessing flat structure (if cached differently): item['temp']
//     if (item['temp'] != null) {
//       return (item['temp'] as num).toDouble();
//     }
//     // 3. Default fallback
//     return 0.0;
//   }

//   // Helper to format timestamp
//   String _formatTime(int timestamp) {
//     final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
//     return DateFormat('E, h a').format(date); // e.g. "Mon, 3 PM"
//   }

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<WeatherViewModel>(context);

//     if (vm.current == null || vm.current!.forecastJson.isEmpty) {
//       return const Scaffold(body: Center(child: Text('No forecast data')));
//     }

//     List points = [];
//     try {
//       final payload =
//           jsonDecode(vm.current!.forecastJson) as Map<String, dynamic>;
//       // Safely access the list, defaulting to empty if null
//       points =
//           (payload['forecast']['hourly'] as List?)?.take(24).toList() ?? [];
//     } catch (e) {
//       return const Scaffold(
//         body: Center(child: Text('Error parsing forecast data')),
//       );
//     }

//     // 1. Prepare Chart Data (Spots)
//     final spots = points.asMap().entries.map((e) {
//       final index = e.key.toDouble();
//       final temp = _getTemp(e.value as Map<String, dynamic>);
//       return FlSpot(index, temp);
//     }).toList();

//     return Scaffold(
//       appBar: AppBar(title: Text('Forecast — ${vm.current!.city}')),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             // --- CHART SECTION ---
//             SizedBox(
//               height: 220,
//               child: points.isEmpty
//                   ? const Center(child: Text("Not enough data for chart"))
//                   : LineChart(
//                       LineChartData(
//                         gridData: FlGridData(show: false),
//                         titlesData: FlTitlesData(
//                           show: false,
//                         ), // Hide messy axis labels
//                         borderData: FlBorderData(show: false),
//                         lineBarsData: [
//                           LineChartBarData(
//                             spots: spots,
//                             isCurved: true,
//                             color: Colors.blue,
//                             barWidth: 3,
//                             dotData: FlDotData(show: false),
//                             belowBarData: BarAreaData(
//                               show: true,
//                               color: Colors.blue.withOpacity(0.2),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//             ),
//             const SizedBox(height: 20),
//             const Divider(),

//             // --- LIST SECTION ---
//             Expanded(
//               child: ListView.builder(
//                 itemCount: points.length,
//                 itemBuilder: (context, i) {
//                   final item = points[i] as Map<String, dynamic>;
//                   final ts = item['dt'] as int? ?? 0;
//                   final temp = _getTemp(item);
//                   final description = (item['weather'] as List).isNotEmpty
//                       ? item['weather'][0]['description']
//                       : '';
//                   final iconCode = (item['weather'] as List).isNotEmpty
//                       ? item['weather'][0]['icon']
//                       : '';

//                   return ListTile(
//                     leading: Image.network(
//                       'https://openweathermap.org/img/wn/$iconCode.png',
//                       errorBuilder: (_, __, ___) => const Icon(Icons.cloud),
//                     ),
//                     title: Text(_formatTime(ts)),
//                     subtitle: Text(description),
//                     trailing: Text(
//                       '${temp.toStringAsFixed(1)} °C',
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
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
