import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/colors.dart';
import '../../services/auth_service.dart';
import '../home/home_dashboard_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();

  bool _loadingUserData = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();

    _checkSession();

    Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        _checkSession();
      },
    );
  }

  Future<void> _checkSession() async {
    final session =
        Supabase.instance.client.auth.currentSession;

    if (session == null) {
      if (!mounted) return;

      setState(() {
        _hasSession = false;
        _loadingUserData = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loadingUserData = true;
        _hasSession = true;
      });
    }

    try {
      await _authService.ensureCurrentUserData();
    } catch (e) {
      debugPrint(
        'User data setup error: $e',
      );
    }

    if (!mounted) return;

    setState(() {
      _hasSession = true;
      _loadingUserData = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUserData) {
      return const _LoadingScreen();
    }

    if (!_hasSession) {
      return const LoginScreen();
    }

    return const HomeDashboardScreen();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SmartHomeColors.background,

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // =================================================
            // GOLD LOADING ICON
            // =================================================

            Container(
              width: 64,
              height: 64,

              decoration: BoxDecoration(
                color: SmartHomeColors.gold.withOpacity(.10),
                shape: BoxShape.circle,

                border: Border.all(
                  color: SmartHomeColors.gold.withOpacity(.35),
                  width: 1,
                ),

                boxShadow: [
                  BoxShadow(
                    color: SmartHomeColors.gold.withOpacity(.12),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                ],
              ),

              child: const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: SmartHomeColors.gold,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // BRAND
            // =================================================

            const Text(
              'SmartHomeX',
              style: TextStyle(
                color: SmartHomeColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Initializing smart home...',
              style: TextStyle(
                color: SmartHomeColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}