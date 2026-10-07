import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:media_kit/media_kit.dart';

import 'core/smart_home_theme.dart';
import 'providers/device_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/schedule_manager.dart';
import 'services/timer_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  MediaKit.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qymotebxgxvowbkktgys.supabase.co',
    publishableKey: 'sb_publishable_Yp9leAzUm8XpbzYZwk-mPA_9u0KgIO1',
  );

  // Start background automation engines without blocking app startup.
  unawaited(_initializeAutomationSafely());

  runApp(const SmartHomeX());
}

Future<void> _initializeAutomationSafely() async {
  try {
    await ScheduleManager.instance.initialize();
  } catch (e, stackTrace) {
    debugPrint(
      'SmartHomeX schedule scheduler initialization failed: $e',
    );
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await TimerManager.instance.initialize();
  } catch (e, stackTrace) {
    debugPrint(
      'SmartHomeX timer scheduler initialization failed: $e',
    );
    debugPrintStack(stackTrace: stackTrace);
  }
}

class SmartHomeX extends StatelessWidget {
  const SmartHomeX({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeviceProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SmartHomeX',
        theme: SmartHomeTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}