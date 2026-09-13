import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/device_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/mqtt_service.dart';

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
// SMART HOMEX APP
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

        theme: ThemeData(
          useMaterial3: true,

          brightness: Brightness.dark,

          scaffoldBackgroundColor:
              const Color(0xFF0F172A),

          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF34B7F1),

            brightness: Brightness.dark,
          ),
        ),

        home: const SplashScreen(),
      ),
    );
  }
}
