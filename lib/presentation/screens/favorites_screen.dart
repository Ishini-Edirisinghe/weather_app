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
      extendBodyBehindAppBar: true, // Allows gradient to go behind AppBar
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
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
          child: Column(
            children: [
              // --- 2. Styled Filter Dropdown ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), // Glassmorphism
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.white70),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: vm.selectedFilter,
                          dropdownColor: const Color(
                            0xFF7E57C2,
                          ), // Purple background
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              vm.applyFilter(newValue);
                            }
                          },
                          items: vm.availableRegions
                              .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- 3. Favorites List (Swipe to Delete) ---
              Expanded(
                child: vm.filteredFavorites.isEmpty
                    ? _buildEmptyState() // Matches "No Favorites Yet" image
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.filteredFavorites.length,
                        itemBuilder: (context, index) {
                          final city = vm.filteredFavorites[index];
                          final locationSubtitle = city.country == 'LK'
                              ? city.state
                              : "International (${city.country})";

                          final uniqueKey = Key(city.city);

                          return Dismissible(
                            key: uniqueKey,
                            direction:
                                DismissDirection.endToStart, // Swipe Left
                            // Background behind the card when swiping
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),

                            // Action when dismissed
                            onDismissed: (direction) {
                              // Ensure this method exists in your ViewModel!
                              vm.removeFavorite(city);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("${city.city} removed"),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },

                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(
                                  0.15,
                                ), // Glassmorphism Card
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Image.network(
                                  'https://openweathermap.org/img/wn/${city.iconCode}.png',
                                  width: 50,
                                  height: 50,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.cloud,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  city.city,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  "$locationSubtitle • ${city.description}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                trailing: Text(
                                  '${city.temp.toStringAsFixed(1)}°',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                onTap: () async {
                                  await vm.loadWeatherForCity(city.city);
                                  vm.setTabIndex(0); // Switch to Home
                                },
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
    );
  }

  // --- 4. "No Favorites Yet" Empty State ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: 100,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Add cities to your favorites to see them here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
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

//     return Scaffold(
//       extendBodyBehindAppBar: true, // Allows gradient to go behind AppBar
//       appBar: AppBar(
//         title: const Text(
//           'Favorites',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         centerTitle: true,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Container(
//         // 1. Unified Gradient Background
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color.fromARGB(255, 2, 22, 38), // Light Blue
//               Color(0xFF7E57C2), // Purple
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // --- 2. Styled Filter Dropdown ---
//               Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 4,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2), // Glassmorphism effect
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: Colors.white.withOpacity(0.3)),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.filter_list, color: Colors.white70),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: DropdownButtonHideUnderline(
//                         child: DropdownButton<String>(
//                           isExpanded: true,
//                           value: vm.selectedFilter,
//                           dropdownColor: const Color(
//                             0xFF7E57C2,
//                           ), // Purple dropdown background
//                           icon: const Icon(
//                             Icons.arrow_drop_down,
//                             color: Colors.white,
//                           ),
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                           ),
//                           onChanged: (String? newValue) {
//                             if (newValue != null) {
//                               vm.applyFilter(newValue);
//                             }
//                           },
//                           items: vm.availableRegions
//                               .map<DropdownMenuItem<String>>((String value) {
//                                 return DropdownMenuItem<String>(
//                                   value: value,
//                                   child: Text(value),
//                                 );
//                               })
//                               .toList(),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // --- 3. Content Area ---
//               Expanded(
//                 child: vm.filteredFavorites.isEmpty
//                     ? _buildEmptyState() // Matches your "No Favorites Yet" image
//                     : ListView.builder(
//                         padding: const EdgeInsets.all(16),
//                         itemCount: vm.filteredFavorites.length,
//                         itemBuilder: (context, index) {
//                           final city = vm.filteredFavorites[index];
//                           final locationSubtitle = city.country == 'LK'
//                               ? city.state
//                               : "International (${city.country})";

//                           return Container(
//                             margin: const EdgeInsets.only(bottom: 12),
//                             decoration: BoxDecoration(
//                               color: Colors.white.withOpacity(
//                                 0.15,
//                               ), // Glassmorphism Card
//                               borderRadius: BorderRadius.circular(20),
//                               border: Border.all(
//                                 color: Colors.white.withOpacity(0.2),
//                               ),
//                             ),
//                             child: ListTile(
//                               contentPadding: const EdgeInsets.symmetric(
//                                 horizontal: 16,
//                                 vertical: 8,
//                               ),
//                               leading: Image.network(
//                                 'https://openweathermap.org/img/wn/${city.iconCode}.png',
//                                 width: 50,
//                                 height: 50,
//                                 errorBuilder: (_, __, ___) => const Icon(
//                                   Icons.cloud,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               title: Text(
//                                 city.city,
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                   fontSize: 18,
//                                 ),
//                               ),
//                               subtitle: Text(
//                                 "$locationSubtitle • ${city.description}",
//                                 style: const TextStyle(color: Colors.white70),
//                               ),
//                               trailing: Text(
//                                 '${city.temp.toStringAsFixed(1)}°',
//                                 style: const TextStyle(
//                                   fontSize: 22,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               onTap: () async {
//                                 await vm.loadWeatherForCity(city.city);
//                                 vm.setTabIndex(0); // Switch to Home
//                               },
//                             ),
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // --- 4. "No Favorites Yet" Empty State (Matches Image 3) ---
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Heart Icon
//             Icon(
//               Icons.favorite_border_rounded,
//               size: 100,
//               color: Colors.white.withOpacity(0.5),
//             ),
//             const SizedBox(height: 24),
//             // Title
//             const Text(
//               'No Favorites Yet',
//               style: TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 12),
//             // Subtitle
//             const Text(
//               'Add cities to your favorites to see them here',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 16,
//                 color: Colors.white70,
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(
//               height: 50,
//             ), // Spacing to push it up visually like the image
//           ],
//         ),
//       ),
//     );
//   }
// }
