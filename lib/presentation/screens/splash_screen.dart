import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = false;

  Future<void> _handleGetStarted() async {
    setState(() {
      _isLoading = true;
    });

    // Request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final size = MediaQuery.of(context).size;
    final double iconSize = size.width * 0.1; // Icons scale with screen width

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 0, 10, 17), // Light Blue
              Color(0xFF7E57C2), // Purple
            ],
          ),
        ),
        child: SafeArea(
          // LayoutBuilder + SingleChildScrollView makes it responsive
          // and crash-proof on small screens/landscape mode
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // Centers everything vertically
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- Weather Icons ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: iconSize,
                            color: Colors.white,
                          ),
                          SizedBox(width: size.width * 0.05),
                          Icon(
                            Icons.cloud_outlined,
                            size: iconSize,
                            color: Colors.white,
                          ),
                          SizedBox(width: size.width * 0.05),
                          Icon(
                            Icons.grain,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ],
                      ),

                      SizedBox(
                        height: size.height * 0.05,
                      ), // 5% of screen height gap
                      // --- Title ---
                      Text(
                        'WeatherPro',
                        style: TextStyle(
                          fontSize: size.width * 0.1, // Responsive font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // --- Subtitle ---
                      Text(
                        'Your personal weather companion',
                        style: TextStyle(
                          fontSize: size.width * 0.045, // Responsive font size
                          color: Colors.white70,
                        ),
                      ),

                      SizedBox(height: size.height * 0.08), // Gap before button
                      // --- Get Started Button (Centered) ---
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleGetStarted,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF5E81F4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Get Started',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
