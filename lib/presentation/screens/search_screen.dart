import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/weather_viewmodel.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load search history when screen opens
    Future.microtask(
      () => Provider.of<WeatherViewModel>(
        context,
        listen: false,
      ).loadSearchHistory(),
    );
  }

  void _performSearch(String city) async {
    if (city.isEmpty) return;
    final vm = Provider.of<WeatherViewModel>(context, listen: false);
    await vm.loadWeatherForCity(city);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Watch VM to update UI when history changes
    final vm = Provider.of<WeatherViewModel>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Search City')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Input
            TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                labelText: 'City name',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(_ctrl.text.trim()),
                ),
              ),
              onSubmitted: (val) => _performSearch(val.trim()),
            ),
            const SizedBox(height: 24),

            // History Section
            if (vm.searchHistory.isNotEmpty) ...[
              const Text(
                "Recent Searches",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),

              // History List
              Expanded(
                child: ListView.builder(
                  itemCount: vm.searchHistory.length,
                  itemBuilder: (context, index) {
                    final city = vm.searchHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.history, color: Colors.grey),
                      title: Text(city),
                      trailing: const Icon(
                        Icons.north_west,
                        size: 16,
                        color: Colors.grey,
                      ),
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        // Fill text field and search immediately
                        _ctrl.text = city;
                        _performSearch(city);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../viewmodels/weather_viewmodel.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});
//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   final _ctrl = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<WeatherViewModel>(context, listen: false);
//     return Scaffold(
//       appBar: AppBar(title: const Text('Search City')),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _ctrl,
//               decoration: const InputDecoration(
//                 labelText: 'City name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             ElevatedButton(
//               onPressed: () async {
//                 final city = _ctrl.text.trim();
//                 if (city.isEmpty) return;
//                 await vm.loadWeatherForCity(city);
//                 Navigator.pop(context);
//               },
//               child: const Text('Search'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
