import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final AppLockService _appLockService = AppLockService();

  static const Color _backgroundColor = Color(0xFF0F172A);
  static const Color _cardColor = Color(0xFF1E293B);
  static const Color _primaryColor = Color(0xFF34B7F1);

  String _pin = '';
  String _errorMessage = '';
  bool _isChecking = false;

  void _addDigit(String digit) {
    if (_pin.length >= 4 || _isChecking) return;

    setState(() {
      _pin += digit;
      _errorMessage = '';
    });

    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _removeDigit() {
    if (_pin.isEmpty || _isChecking) return;

    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = '';
    });
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isChecking = true;
    });

    final correct = await _appLockService.verifyPin(_pin);

    if (!mounted) return;

    if (correct) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _pin = '';
      _errorMessage = 'Incorrect PIN. Try again.';
      _isChecking = false;
    });
  }

  Widget _pinDot(int index) {
    final filled = index < _pin.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 14,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? _primaryColor : Colors.white24,
        border: Border.all(
          color: filled ? _primaryColor : Colors.white38,
        ),
      ),
    );
  }

  Widget _numberButton(String value) {
    return GestureDetector(
      onTap: () => _addDigit(value),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _cardColor,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Center(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        height: 70,
        child: Center(
          child: Icon(
            icon,
            color: Colors.white60,
            size: 25,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Lock icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryColor.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: _primaryColor,
                size: 36,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'SmartHomeX Locked',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Enter your 4-digit PIN to continue',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 30),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => _pinDot(index),
              ),
            ),

            const SizedBox(height: 14),

            // Error message
            SizedBox(
              height: 22,
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Number keypad
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 18,
              padding: const EdgeInsets.symmetric(horizontal: 45),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _numberButton('1'),
                _numberButton('2'),
                _numberButton('3'),
                _numberButton('4'),
                _numberButton('5'),
                _numberButton('6'),
                _numberButton('7'),
                _numberButton('8'),
                _numberButton('9'),
                const SizedBox(),
                _numberButton('0'),
                _actionButton(
                  icon: Icons.backspace_outlined,
                  onTap: _removeDigit,
                ),
              ],
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: Text(
                _isChecking ? 'Checking...' : 'SmartHomeX',
                style: const TextStyle(
                  color: Colors.white24,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}