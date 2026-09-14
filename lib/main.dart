import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/smart_home_background.dart';
import 'core/smart_home_theme.dart';
import 'providers/device_provider.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =====================================================
  // SUPABASE
  // =====================================================

  await Supabase.initialize(
    url: 'https://qymotebxgxvowbkktgys.supabase.co',
    publishableKey:
        'sb_publishable_Yp9leAzUm8XpbzYZwk-mPA_9u0KgIO1',
  );

  // =====================================================
  // START APP
  // =====================================================

  runApp(
    const SmartHomeX(),
  );
}

// =======================================================
// SMART HOMEX
// =======================================================

class SmartHomeX extends StatelessWidget {
  const SmartHomeX({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DeviceProvider(),

      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        title: 'SmartHomeX',

        // ===============================================
        // GLOBAL THEME
        // ===============================================

        theme: SmartHomeTheme.darkTheme,

        // ===============================================
        // GLOBAL LIVE BACKGROUND
        //
        // This is the important change.
        // The background now sits behind the Navigator,
        // so it can remain visible across the whole app.
        // ===============================================

        builder: (context, child) {
          return SmartHomeBackground(
            child: child ?? const SizedBox.shrink(),
          );
        },

        home: const SplashScreen(),
      ),
    );
  }
}