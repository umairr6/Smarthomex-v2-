import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';
import 'app_lock_screen.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({
    super.key,
    required this.child,
  });

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate>
    with WidgetsBindingObserver {
  final AppLockService _appLockService = AppLockService();

  bool _checking = true;
  bool _locked = false;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  Future<void> _checkLock() async {
    final enabled = await _appLockService.isEnabled();

    if (!mounted) return;

    setState(() {
      _locked = enabled;
      _checking = false;
    });

    if (enabled) {
      _showLockScreen();
    }
  }

  Future<void> _showLockScreen() async {
    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const AppLockScreen(),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        _unlocked = true;
        _locked = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_unlocked) {
        _showLockScreen();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF34B7F1),
          ),
        ),
      );
    }

    if (_locked && !_unlocked) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
      );
    }

    return widget.child;
  }
}