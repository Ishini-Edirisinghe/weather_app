import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/weather_viewmodel.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          Provider.of<WeatherViewModel>(context, listen: false).loadFavorites(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Column(
        children: [
          // --- Dropdown Filter ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Row(
              children: [
                const Text(
                  "Filter by Region: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: vm.selectedFilter,
                    icon: const Icon(Icons.filter_list),
                    underline: Container(height: 2, color: Colors.blue),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        vm.applyFilter(newValue);
                      }
                    },
                    items: vm.availableRegions.map<DropdownMenuItem<String>>((
                      String value,
                    ) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // --- Favorites List ---
          Expanded(
            child: vm.filteredFavorites.isEmpty
                ? const Center(child: Text('No favorites found.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: vm.filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final city = vm.filteredFavorites[index];
                      // Subtitle shows region if Sri Lanka, or Country Name if Other
                      final locationSubtitle = city.country == 'LK'
                          ? city.state
                          : "International (${city.country})";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Image.network(
                            'https://openweathermap.org/img/wn/${city.iconCode}.png',
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.cloud),
                          ),
                          title: Text(
                            city.city,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "$locationSubtitle • ${city.description}",
                          ),
                          trailing: Text(
                            '${city.temp.toStringAsFixed(1)}°C',
                            style: const TextStyle(fontSize: 18),
                          ),
                          onTap: () async {
                            await vm.loadWeatherForCity(city.city);
                            vm.setTabIndex(0);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
