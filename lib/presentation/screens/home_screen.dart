import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  // Define your screens here.
  // Index 0 is your Weather UI (defined below as _WeatherTab)
  final List<Widget> _screens = [
    const _WeatherTab(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack preserves the state of the tabs (keeps weather loaded)
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // Use fixed for 3 or more items
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
// This is your ORIGINAL Home Screen Logic, moved into a separate widget
// so it can be used as one of the tabs.
// ==============================================================================
class _WeatherTab extends StatelessWidget {
  const _WeatherTab();

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WeatherNow'),
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
            : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  WeatherCard(
                    city: vm.current!.city,
                    temp: vm.current!.temp,
                    description: vm.current!.description,
                    iconCode: vm.current!.iconCode,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ForecastScreen()),
                    ),
                    child: const Text('View Forecast'),
                  ),
                ],
              ),
      ),
    );
  }
}
