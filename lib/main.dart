import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/device_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const SmartHomeX());
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

        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xff0F172A),
        ),

        home: const SplashScreen(),
      ),
    );
  }
}