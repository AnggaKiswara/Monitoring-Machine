import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/factory_list_screen.dart';
import 'screens/station_list_screen.dart';
import 'screens/submitted_data_screen.dart'; // <-- TAMBAHKAN

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CMMS App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2196F3),
        scaffoldBackgroundColor: Colors.grey[50],
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/factory_list': (context) => const FactoryListScreen(),
        '/station_list': (context) =>
            const StationListScreen(factoryName: 'PKS Sei Matim'),
        '/submitted_data': (context) =>
            const SubmittedDataScreen(), // <-- TAMBAHKAN
      },
    );
  }
}
