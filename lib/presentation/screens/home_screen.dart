import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // REQUIRED: Add intl: ^0.19.0 to pubspec.yaml
import 'dart:convert'; // REQUIRED: To decode the forecast JSON
import '../viewmodels/weather_viewmodel.dart';
import '../widgets/weather_card.dart';
import 'search_screen.dart';
import 'forecast_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _WeatherTab(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// UPDATED WEATHER TAB
// ==============================================================================
class _WeatherTab extends StatelessWidget {
  const _WeatherTab();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);

    // 1. Prepare the Hourly Data
    List hourlyList = [];
    if (vm.current != null && vm.current!.forecastJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(vm.current!.forecastJson);
        // Access ['forecast']['hourly'] based on your Repository structure
        hourlyList = decoded['forecast']['hourly'] ?? [];
      } catch (e) {
        print("Error parsing forecast JSON: $e");
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('WeatherNow'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        child: vm.loading
            ? const Center(child: CircularProgressIndicator())
            : vm.current == null
            ? Center(child: Text(vm.error ?? 'No data — search a city'))
            : RefreshIndicator(
                onRefresh: () async {
                  // Call your VM refresh logic here if available
                  // await vm.refreshWeather();
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 1. BIG CARD (Current Weather)
                    WeatherCard(
                      city: vm.current!.city,
                      temp: vm.current!.temp,
                      description: vm.current!.description,
                      iconCode: vm.current!.iconCode,
                    ),

                    const SizedBox(height: 24),

                    // 2. HOURLY FORECAST SUMMARY (REAL DATA)
                    _buildSectionTitle('Hourly Forecast'),
                    const SizedBox(height: 12),
                    // Pass the parsed list here
                    _buildHourlyForecastList(context, hourlyList),

                    const SizedBox(height: 24),

                    // 3. WEATHER DETAILS (REAL DATA)
                    _buildSectionTitle('Details'),
                    const SizedBox(height: 12),
                    _buildDetailsGrid(vm.current!),

                    const SizedBox(height: 24),

                    // 4. FULL FORECAST BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForecastScreen(),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('View 7-Day Forecast'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // UPDATED: Now accepts the list of hourly data
  Widget _buildHourlyForecastList(BuildContext context, List data) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("No forecast available")),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Limit to 8 items (24 hours)
        itemCount: data.length > 8 ? 8 : data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = data[index];

          // Parse Time
          // API returns "dt" (unix) or "dt_txt" depending on endpoint.
          // Since we used the free /forecast endpoint, 'dt' is a Unix timestamp.
          final DateTime time = DateTime.fromMillisecondsSinceEpoch(
            item['dt'] * 1000,
          );
          final String timeString = DateFormat(
            'h a',
          ).format(time); // e.g. "1 PM"

          // Parse Temp
          final double temp = (item['main']['temp'] as num).toDouble();

          // Parse Icon
          final String iconCode = item['weather'][0]['icon'];
          final iconUrl = "https://openweathermap.org/img/wn/$iconCode@2x.png";

          return Container(
            width: 80,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timeString,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                // Load actual icon image
                Image.network(
                  iconUrl,
                  width: 32,
                  height: 32,
                  errorBuilder: (c, o, s) => const Icon(Icons.error),
                ),
                const SizedBox(height: 8),
                Text(
                  "${temp.toStringAsFixed(0)}°",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsGrid(dynamic current) {
    // Access properties from WeatherEntity
    final humidity = current.humidity; // This is an int
    final windSpeed = current.windSpeed; // This is a double

    // FIX: Parse real Sunrise/Sunset
    // These are Unix timestamps (integers)
    final DateTime sunriseDate = DateTime.fromMillisecondsSinceEpoch(
      current.sunrise * 1000,
    );
    final DateTime sunsetDate = DateTime.fromMillisecondsSinceEpoch(
      current.sunset * 1000,
    );

    // Format them
    final String sunriseString = DateFormat.jm().format(
      sunriseDate,
    ); // "6:12 AM"
    final String sunsetString = DateFormat.jm().format(sunsetDate); // "6:45 PM"

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildDetailItem(Icons.water_drop, "Humidity", "$humidity%"),
        _buildDetailItem(Icons.air, "Wind", "$windSpeed m/s"),
        _buildDetailItem(Icons.wb_twilight, "Sunrise", sunriseString),
        _buildDetailItem(Icons.nights_stay, "Sunset", sunsetString),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
