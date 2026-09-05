import 'package:flutter/material.dart';

import 'database/v2/data_store_bootstrap.dart';
import 'screens/home_screen.dart';

DataStoreBootstrapResult? v2DataStore;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    v2DataStore = await DataStoreBootstrap.initialize();
  } catch (error, stackTrace) {
    // V2 migration is additive during Phase 1. If it fails, the current JSON
    // backed UI remains usable and the original JSON file is left untouched.
    debugPrint('V2 datastore initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '记账本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2196F3),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
