import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/weather_viewmodel.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  // Define available filters
  final List<String> filters = [
    'All',
    'Asia',
    'Europe',
    'North America',
    'Other',
  ];

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
          // Filter Chips Row
          SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = vm.selectedFilter == filter;
                return Center(
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        vm.applyFilter(filter);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Favorites List
          Expanded(
            child: vm.filteredFavorites.isEmpty
                ? const Center(
                    child: Text('No favorites found for this region'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: vm.filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final city = vm.filteredFavorites[index];
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
                            "${city.description} • ${city.country}",
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
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../viewmodels/weather_viewmodel.dart';

// class FavoritesScreen extends StatefulWidget {
//   const FavoritesScreen({super.key});

//   @override
//   State<FavoritesScreen> createState() => _FavoritesScreenState();
// }

// class _FavoritesScreenState extends State<FavoritesScreen> {
//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(
//       () =>
//           Provider.of<WeatherViewModel>(context, listen: false).loadFavorites(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<WeatherViewModel>(context);

//     // No need to look for a special function provider anymore!

//     return Scaffold(
//       appBar: AppBar(title: const Text('Favorites')),
//       body: vm.favorites.isEmpty
//           ? const Center(child: Text('No favorites yet'))
//           : ListView.builder(
//               padding: const EdgeInsets.all(12),
//               itemCount: vm.favorites.length,
//               itemBuilder: (context, index) {
//                 final city = vm.favorites[index];
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   child: ListTile(
//                     leading: Image.network(
//                       'https://openweathermap.org/img/wn/${city.iconCode}.png',
//                       errorBuilder: (_, __, ___) => const Icon(Icons.cloud),
//                     ),
//                     title: Text(
//                       city.city,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text(city.description),
//                     trailing: Text(
//                       '${city.temp.toStringAsFixed(1)}°C',
//                       style: const TextStyle(fontSize: 18),
//                     ),
//                     onTap: () async {
//                       await vm.loadWeatherForCity(city.city);

//                       // FIX: Just use the ViewModel to switch the tab!
//                       vm.setTabIndex(0);
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
