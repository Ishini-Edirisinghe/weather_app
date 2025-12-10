import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/weather_viewmodel.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    // Load data to ensure we have the latest alerts from favorites
    Future.microtask(
      () =>
          Provider.of<WeatherViewModel>(context, listen: false).loadFavorites(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeatherViewModel>(context);

    return Scaffold(
      extendBodyBehindAppBar: true, // Allows gradient to extend behind AppBar
      appBar: AppBar(
        title: const Text(
          'Weather Alerts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
          child: vm.aggregatedAlerts.isEmpty
              ? _buildEmptyState() // Matches your "No Active Alerts" image
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.aggregatedAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = vm.aggregatedAlerts[index];

                    // Unique Key for Dismissible
                    final uniqueKey = Key(
                      "${alert.city}_${alert.event}_${alert.start.millisecondsSinceEpoch}",
                    );

                    return Dismissible(
                      key: uniqueKey,
                      direction: DismissDirection.endToStart,
                      // Swipe Background
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 16),
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
                      onDismissed: (direction) {
                        vm.removeAlert(alert);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Alert for ${alert.city} dismissed"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                            0.95,
                          ), // White card for readability
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border(
                            left: BorderSide(
                              color: Colors.red.shade400,
                              width: 6,
                            ), // Red indicator
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Icon + Event Name
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red.shade600,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          alert.event,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "for ${alert.city}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),

                              // Description
                              Text(
                                alert.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Footer: Time
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Ends: ${DateFormat('MMM d, h:mm a').format(alert.end)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  // --- "No Active Alerts" Empty State (Matches Image) ---
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Warning Icon
            Icon(
              Icons.warning_amber_rounded, // Triangle warning icon
              size: 100,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            // Title
            const Text(
              'No Active Alerts',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            // Subtitle
            const Text(
              'Add cities to favorites to see weather alerts',
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
// import 'package:intl/intl.dart';
// import '../viewmodels/weather_viewmodel.dart';

// class AlertsScreen extends StatefulWidget {
//   const AlertsScreen({super.key});

//   @override
//   State<AlertsScreen> createState() => _AlertsScreenState();
// }

// class _AlertsScreenState extends State<AlertsScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Load data to ensure we have the latest alerts from favorites
//     Future.microtask(
//       () =>
//           Provider.of<WeatherViewModel>(context, listen: false).loadFavorites(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final vm = Provider.of<WeatherViewModel>(context);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Weather Alerts')),
//       body: vm.aggregatedAlerts.isEmpty
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(
//                     Icons.check_circle_outline,
//                     size: 64,
//                     color: Colors.green,
//                   ),
//                   const SizedBox(height: 16),
//                   const Text('No active alerts in favorite cities.'),
//                   const SizedBox(height: 8),
//                   Text(
//                     '(Add more favorites or check back later)',
//                     style: TextStyle(color: Colors.grey[600]),
//                   ),
//                 ],
//               ),
//             )
//           : ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: vm.aggregatedAlerts.length,
//               itemBuilder: (context, index) {
//                 final alert = vm.aggregatedAlerts[index];

//                 return Card(
//                   color: Colors.red.shade50,
//                   margin: const EdgeInsets.only(bottom: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     side: BorderSide(color: Colors.red.shade200),
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // Header: Event & City
//                         Row(
//                           children: [
//                             const Icon(
//                               Icons.warning_amber_rounded,
//                               color: Colors.red,
//                               size: 30,
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     alert.event,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                       color: Colors.red,
//                                     ),
//                                   ),
//                                   Text(
//                                     "for ${alert.city}",
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.w600,
//                                       fontSize: 14,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                         const Divider(height: 24),

//                         // Description
//                         Text(
//                           alert.description,
//                           style: const TextStyle(fontSize: 14, height: 1.4),
//                         ),
//                         const SizedBox(height: 12),

//                         // Time
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.end,
//                           children: [
//                             Text(
//                               "Ends: ${DateFormat('MMM d, h:mm a').format(alert.end)}",
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.grey[700],
//                                 fontStyle: FontStyle.italic,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
