import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../viewmodels/weather_viewmodel.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<WeatherViewModel>(
        context,
        listen: false,
      ).loadSearchHistory(),
    );
  }

  void _performSearch(String city) async {
    if (city.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSearching = true;
    });

    final vm = Provider.of<WeatherViewModel>(context, listen: false);

    // Attempt to load weather
    await vm.loadWeatherForCity(city);

    setState(() {
      _isSearching = false;
    });

    // Check success
    if (vm.current != null && vm.error == null) {
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not find weather for '$city'."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true, // Gradient goes behind AppBar
      appBar: AppBar(
        title: const Text(
          'Search City',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // 1. Unified Gradient Background
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
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Modern Rounded Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _ctrl,
                    style: const TextStyle(color: Colors.black87),
                    // Validation: Letters & Spaces only
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter city name...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.search,
                                color: Color(0xFF7E57C2),
                              ),
                              onPressed: () =>
                                  _performSearch(_ctrl.text.trim()),
                            ),
                    ),
                    onSubmitted: (val) => _performSearch(val.trim()),
                  ),
                ),

                const SizedBox(height: 30),

                // 3. Recent Searches Section
                if (vm.searchHistory.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 10),
                    child: Text(
                      "Recent Searches",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Glassmorphic List
                  Expanded(
                    child: ListView.builder(
                      itemCount: vm.searchHistory.length,
                      itemBuilder: (context, index) {
                        final city = vm.searchHistory[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.15,
                            ), // Glass effect
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.history,
                              color: Colors.white70,
                            ),
                            title: Text(
                              city,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.north_west_rounded,
                              size: 18,
                              color: Colors.white70,
                            ),
                            onTap: () {
                              _ctrl.text = city;
                              _performSearch(city);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Required for FilteringTextInputFormatter
// import 'package:provider/provider.dart';
// import '../viewmodels/weather_viewmodel.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});
//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   final _ctrl = TextEditingController();
//   bool _isSearching = false; // To show loading indicator

//   @override
//   void initState() {
//     super.initState();
//     // Load search history when screen opens
//     Future.microtask(
//       () => Provider.of<WeatherViewModel>(
//         context,
//         listen: false,
//       ).loadSearchHistory(),
//     );
//   }

//   void _performSearch(String city) async {
//     if (city.isEmpty) return;

//     // Dismiss keyboard
//     FocusScope.of(context).unfocus();

//     setState(() {
//       _isSearching = true;
//     });

//     final vm = Provider.of<WeatherViewModel>(context, listen: false);

//     // Attempt to load weather
//     await vm.loadWeatherForCity(city);

//     setState(() {
//       _isSearching = false;
//     });

//     // Check if the search was successful (vm.current should not be null)
//     // You might want to check vm.error instead depending on your VM implementation
//     if (vm.current != null && vm.error == null) {
//       // Success: Navigate back
//       if (mounted) Navigator.pop(context);
//     } else {
//       // Failure: Show error message
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               "Could not find weather for '$city'. Please check the name.",
//             ),
//             backgroundColor: Colors.redAccent,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Watch VM to update UI when history changes
//     final vm = Provider.of<WeatherViewModel>(context);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Search City')),
//       body: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Search Input
//             TextField(
//               controller: _ctrl,
//               // 1. VALIDATION: Allow only letters and spaces
//               inputFormatters: [
//                 FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
//               ],
//               decoration: InputDecoration(
//                 labelText: 'City name',
//                 hintText: 'e.g. London, New York',
//                 border: const OutlineInputBorder(),
//                 // Show loading spinner or search icon
//                 suffixIcon: _isSearching
//                     ? const Padding(
//                         padding: EdgeInsets.all(12.0),
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : IconButton(
//                         icon: const Icon(Icons.search),
//                         onPressed: () => _performSearch(_ctrl.text.trim()),
//                       ),
//               ),
//               onSubmitted: (val) => _performSearch(val.trim()),
//             ),
//             const SizedBox(height: 24),

//             // History Section
//             if (vm.searchHistory.isNotEmpty) ...[
//               const Text(
//                 "Recent Searches",
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 8),

//               // History List
//               Expanded(
//                 child: ListView.builder(
//                   itemCount: vm.searchHistory.length,
//                   itemBuilder: (context, index) {
//                     final city = vm.searchHistory[index];
//                     return ListTile(
//                       leading: const Icon(Icons.history, color: Colors.grey),
//                       title: Text(city),
//                       trailing: const Icon(
//                         Icons.north_west,
//                         size: 16,
//                         color: Colors.grey,
//                       ),
//                       contentPadding: EdgeInsets.zero,
//                       onTap: () {
//                         // Fill text field and search immediately
//                         _ctrl.text = city;
//                         _performSearch(city);
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
