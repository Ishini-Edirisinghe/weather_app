import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../viewmodels/weather_viewmodel.dart';
import '../widgets/weather_card.dart';
import 'search_screen.dart';
import 'forecast_screen.dart';
import 'favorites_screen.dart';
import 'alerts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);

    final List<Widget> screens = [
      const _WeatherTab(),
      const FavoritesScreen(),
      const AlertsScreen(),
    ];

    return Scaffold(
      extendBody: true, // Allows content to go behind the bottom bar
      body: IndexedStack(index: vm.currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: vm.currentIndex,
          onTap: (index) => vm.setTabIndex(index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF7E57C2), // Purple accent
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.warning_amber_rounded),
              label: 'Alerts',
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================================================
// UPDATED WEATHER TAB (With Gradient & Modern UI)
// ==============================================================================
class _WeatherTab extends StatelessWidget {
  const _WeatherTab();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);

    // Prepare Hourly Data
    List hourlyList = [];
    if (vm.current != null && vm.current!.forecastJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(vm.current!.forecastJson);
        hourlyList = decoded['forecast']['hourly'] ?? [];
      } catch (e) {
        print("Error parsing forecast JSON: $e");
      }
    }

    return Scaffold(
      // Gradient Background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF42A5F5), // Light Blue
              Color(0xFF7E57C2), // Purple
            ],
          ),
        ),
        child: SafeArea(
          child: vm.loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : vm.current == null
              ? _buildEmptyState(context) // DESIGN FROM IMAGE 2
              : RefreshIndicator(
                  color: const Color(0xFF7E57C2),
                  backgroundColor: Colors.white,
                  onRefresh: () async {
                    await vm.loadWeatherForCity(vm.current!.city);
                  },
                  child: Column(
                    children: [
                      // Custom App Bar
                      _buildCustomAppBar(context, vm),

                      // Scrollable Content
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          children: [
                            // 1. BIG CARD (Current Weather)
                            // Assuming WeatherCard handles its own styling, otherwise wrap it
                            WeatherCard(
                              city: vm.current!.city,
                              temp: vm.current!.temp,
                              description: vm.current!.description,
                              iconCode: vm.current!.iconCode,
                            ),

                            const SizedBox(height: 24),

                            // 2. HOURLY FORECAST
                            _buildSectionTitle('Hourly Forecast'),
                            const SizedBox(height: 12),
                            _buildHourlyForecastList(context, hourlyList),

                            const SizedBox(height: 24),

                            // 3. WEATHER DETAILS
                            _buildSectionTitle('Details'),
                            const SizedBox(height: 12),
                            _buildDetailsGrid(vm.current!),

                            const SizedBox(height: 24),

                            // 4. FULL FORECAST BUTTON
                            Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ForecastScreen(),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF7E57C2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'View 5-Day Forecast',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // --- 1. NEW: Custom App Bar for Gradient Background ---
  Widget _buildCustomAppBar(BuildContext context, WeatherViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'WeatherPro',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  vm.current!.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: vm.current!.isFavorite
                      ? Colors.redAccent
                      : Colors.white,
                ),
                onPressed: () => vm.toggleFavorite(),
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
                icon: const Icon(Icons.search, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 2. NEW: Empty State (Matches Image 2) ---
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_rounded, size: 100, color: Colors.white70),
            const SizedBox(height: 24),
            const Text(
              'Search for a City',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Get real-time weather updates',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5E81F4), // Blue text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Search Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGETS (Updated Styling) ---

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white, // Changed to White
      ),
    );
  }

  Widget _buildHourlyForecastList(BuildContext context, List data) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            "No forecast available",
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.length > 8 ? 8 : data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = data[index];
          final DateTime time = DateTime.fromMillisecondsSinceEpoch(
            item['dt'] * 1000,
          );
          final String timeString = DateFormat('h a').format(time);
          final double temp = (item['main']['temp'] as num).toDouble();
          final String iconCode = item['weather'][0]['icon'];
          final iconUrl = "https://openweathermap.org/img/wn/$iconCode@2x.png";

          return Container(
            width: 80,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), // Glassmorphism
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timeString,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Image.network(
                  iconUrl,
                  width: 32,
                  height: 32,
                  errorBuilder: (c, o, s) =>
                      const Icon(Icons.error, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "${temp.toStringAsFixed(0)}°",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsGrid(dynamic current) {
    final humidity = current.humidity;
    final windSpeed = current.windSpeed;
    final sunriseString = DateFormat.jm().format(
      DateTime.fromMillisecondsSinceEpoch(current.sunrise * 1000),
    );
    final sunsetString = DateFormat.jm().format(
      DateTime.fromMillisecondsSinceEpoch(current.sunset * 1000),
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildDetailItem(Icons.water_drop_outlined, "Humidity", "$humidity%"),
        _buildDetailItem(Icons.air_outlined, "Wind", "$windSpeed m/s"),
        _buildDetailItem(Icons.wb_twilight_rounded, "Sunrise", sunriseString),
        _buildDetailItem(Icons.nights_stay_outlined, "Sunset", sunsetString),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), // Glassmorphism
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
