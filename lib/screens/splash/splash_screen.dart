import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/device_provider.dart';
import '../../services/storage_service.dart';
import '../home/home_screen.dart';
import '../setup/setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    // Show splash screen for 3 seconds
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Check for saved ESP32 device
    final savedDevice = await _storageService.loadDevice();

    if (!mounted) return;

    if (savedDevice != null) {
      // Restore saved device into provider
      context.read<DeviceProvider>().setDevice(savedDevice);

      // Go directly to dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        ),
      );
    } else {
      // No saved device → setup screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SetupScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xff1E293B),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.home_rounded,
                size: 55,
                color: Color(0xff34B7F1),
              ),
            ),

            const SizedBox(height: 28),

            // App name
            const Text(
              'SmartHomeX',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            // Tagline
            const Text(
              'Smart Control. Simplified.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 40),

            // Loading indicator
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xff34B7F1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}