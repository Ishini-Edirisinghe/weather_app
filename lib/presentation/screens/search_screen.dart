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
    setState(() => _isSearching = true);

    final vm = Provider.of<WeatherViewModel>(context, listen: false);
    await vm.loadWeatherForCity(city);

    setState(() => _isSearching = false);

    if (vm.current != null && vm.error == null) {
      if (mounted) Navigator.pop(context);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Could not find weather for '$city'. Please check the name.",
            ),
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
      extendBodyBehindAppBar: true,
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF42A5F5), Color(0xFF7E57C2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
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

                // Recent Searches Header with Clear All
                if (vm.searchHistory.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(
                          "Recent Searches",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => vm.clearSearchHistory(),
                        child: const Text(
                          "Clear All",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // History List
                  Expanded(
                    child: ListView.builder(
                      itemCount: vm.searchHistory.length,
                      itemBuilder: (context, index) {
                        final city = vm.searchHistory[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
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
                            // Trailing: Delete specific item
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.white70,
                              ),
                              onPressed: () => vm.deleteSearchItem(city),
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
