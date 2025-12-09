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

    // No need to look for a special function provider anymore!

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: vm.favorites.isEmpty
          ? const Center(child: Text('No favorites yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: vm.favorites.length,
              itemBuilder: (context, index) {
                final city = vm.favorites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Image.network(
                      'https://openweathermap.org/img/wn/${city.iconCode}.png',
                      errorBuilder: (_, __, ___) => const Icon(Icons.cloud),
                    ),
                    title: Text(
                      city.city,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(city.description),
                    trailing: Text(
                      '${city.temp.toStringAsFixed(1)}°C',
                      style: const TextStyle(fontSize: 18),
                    ),
                    onTap: () async {
                      await vm.loadWeatherForCity(city.city);

                      // FIX: Just use the ViewModel to switch the tab!
                      vm.setTabIndex(0);
                    },
                  ),
                );
              },
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
//     // Load favorites whenever this screen is initialized
//     Future.microtask(
//       () =>
//           Provider.of<WeatherViewModel>(context, listen: false).loadFavorites(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<WeatherViewModel>(context);

//     // This retrieves the tab switching function we provided in HomeScreen
//     final switchTab = Provider.of<void Function(int)>(context, listen: false);

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
//                       // 1. Load this city into the main view
//                       await vm.loadWeatherForCity(city.city);
//                       // 2. Switch back to the Home Tab (Index 0)
//                       switchTab(0);
//                     },
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }

// import 'package:flutter/material.dart';

// class FavoritesScreen extends StatelessWidget {
//   const FavoritesScreen({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Favorites')),
//       body: const Center(child: Text('Favorites list here')),
//     );
//   }
// }
