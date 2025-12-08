import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/weather_viewmodel.dart';
import '../widgets/weather_card.dart';
import 'search_screen.dart';
import 'forecast_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
