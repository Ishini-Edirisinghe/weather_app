import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/viewmodels/weather_viewmodel.dart';
import 'data/datasources/remote_datasource.dart';
import 'data/datasources/local_datasource.dart';
import 'data/repositories/weather_repository_impl.dart';
import 'package:dio/dio.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dio = Dio();
  final remote = RemoteDatasource(dio);
  final local = LocalDatasource();
  final repo = WeatherRepositoryImpl(remote: remote, local: local);

  runApp(MyApp(repository: repo));
}

class MyApp extends StatelessWidget {
  final WeatherRepositoryImpl repository;
  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WeatherViewModel(repository: repository),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WeatherNow',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const SplashScreen(),
      ),
    );
  }
}
