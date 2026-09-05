import 'package:flutter/material.dart';

import 'database/v2/data_store_bootstrap.dart';
import 'screens/home_screen.dart';
import 'services/app_runtime.dart';
import 'services/auto_capture/auto_capture_coordinator.dart';

DataStoreBootstrapResult? v2DataStore;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    v2DataStore = await DataStoreBootstrap.initialize();
    AppRuntime.v2Database = v2DataStore?.database.db;
  } catch (error, stackTrace) {
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
      home: const AutoCaptureAwareHome(),
    );
  }
}

class AutoCaptureAwareHome extends StatefulWidget {
  const AutoCaptureAwareHome({super.key});

  @override
  State<AutoCaptureAwareHome> createState() => _AutoCaptureAwareHomeState();
}

class _AutoCaptureAwareHomeState extends State<AutoCaptureAwareHome>
    with WidgetsBindingObserver {
  int _revision = 0;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _processCaptures());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _processCaptures();
    }
  }

  Future<void> _processCaptures() async {
    if (_processing) return;
    _processing = true;
    try {
      final posted = await AutoCaptureCoordinator(
        pendingDatabase: AppRuntime.v2Database,
      ).processPendingNativeCaptures();
      if (posted > 0 && mounted) {
        setState(() => _revision++);
      }
    } finally {
      _processing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(key: ValueKey(_revision));
  }
}
