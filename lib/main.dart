import 'package:flutter/material.dart';

import 'database/v2/data_store_bootstrap.dart';
import 'screens/home_screen.dart';
import 'services/app_runtime.dart';
import 'services/auto_capture/auto_capture_coordinator.dart';
import 'services/auto_capture/native_capture_bridge.dart';

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
  bool _permissionPromptShown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _processCaptures();
      await _ensureNotificationAccess();
    });
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

  Future<void> _ensureNotificationAccess() async {
    if (_permissionPromptShown || !mounted) return;
    bool enabled;
    try {
      enabled = await const NativeCaptureBridge().isNotificationAccessEnabled();
    } catch (_) {
      return;
    }
    if (enabled || !mounted) return;
    _permissionPromptShown = true;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('开启自动记账'),
        content: const Text(
          '开启“通知使用权”后，记账本才能在微信、支付宝等产生支付通知时自动识别金额。'
          '只保存结构化账单信息，不保存完整通知内容。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await const NativeCaptureBridge().openNotificationAccessSettings();
            },
            child: const Text('去开启'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(key: ValueKey(_revision));
  }
}
