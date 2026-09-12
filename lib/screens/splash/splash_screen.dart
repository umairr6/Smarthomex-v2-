import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startSplash();
  }

  Future<void> _startSplash() async {
    await Future.delayed(
      const Duration(seconds: 3),
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const AuthGate(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF0F172A);
    const primary = Color(0xFF34B7F1);

    return Scaffold(
      backgroundColor: background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primary.withOpacity(.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary.withOpacity(.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.home_rounded,
                size: 52,
                color: primary,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'SmartHomeX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Smart living. Simple control.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 40),

            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}