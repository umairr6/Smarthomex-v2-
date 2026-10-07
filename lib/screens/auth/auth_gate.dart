import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/colors.dart';
import '../../services/auth_service.dart';
import '../../services/app_lock_service.dart';
import '../app_lock/app_lock_screen.dart';
import '../home/home_dashboard_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final AppLockService _appLockService = AppLockService();

  bool _loadingUserData = true;
  bool _hasSession = false;
  bool _checkingAppLock = false;

  bool _appLockCheckedForSession = false;
  bool _appLockScreenOpen = false;

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();

    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        _handleAuthStateChange(data);
      },
    );

    _checkSession();
  }

  void _handleAuthStateChange(AuthState data) {
    if (data.session == null) {
      _appLockCheckedForSession = false;
      _appLockScreenOpen = false;
      _checkSession();
      return;
    }

    // Prevent duplicate Supabase startup events from opening
    // the App Lock screen a second time.
    if (_hasSession && (_loadingUserData || _checkingAppLock)) {
      return;
    }

    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      if (!mounted) return;

      setState(() {
        _hasSession = false;
        _loadingUserData = false;
        _checkingAppLock = false;
      });

      return;
    }

    if (_appLockCheckedForSession) {
      if (!mounted) return;

      setState(() {
        _hasSession = true;
        _loadingUserData = false;
        _checkingAppLock = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loadingUserData = true;
        _hasSession = true;
        _checkingAppLock = true;
      });
    }

    try {
      await _authService.ensureCurrentUserData();
    } catch (e) {
      debugPrint('User data setup error: $e');
    }

    if (!mounted) return;

    if (_appLockCheckedForSession) {
      setState(() {
        _loadingUserData = false;
        _checkingAppLock = false;
      });
      return;
    }

    await _checkAppLock();
  }

  Future<void> _checkAppLock() async {
    if (_appLockScreenOpen || _appLockCheckedForSession) {
      return;
    }

    try {
      final enabled = await _appLockService.isEnabled();

      if (!mounted) return;

      if (!enabled) {
        _appLockCheckedForSession = true;

        setState(() {
          _loadingUserData = false;
          _checkingAppLock = false;
        });

        return;
      }

      _appLockScreenOpen = true;

      final unlocked = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const AppLockScreen(),
        ),
      );

      _appLockScreenOpen = false;

      if (!mounted) return;

      if (unlocked == true) {
        _appLockCheckedForSession = true;

        setState(() {
          _loadingUserData = false;
          _checkingAppLock = false;
        });
      } else {
        setState(() {
          _loadingUserData = false;
          _checkingAppLock = false;
        });
      }
    } catch (e) {
      _appLockScreenOpen = false;

      debugPrint('App Lock status check error: $e');

      if (!mounted) return;

      setState(() {
        _loadingUserData = false;
        _checkingAppLock = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingUserData || _checkingAppLock) {
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
