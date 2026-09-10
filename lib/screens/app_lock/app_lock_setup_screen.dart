import 'package:flutter/material.dart';

import '../../services/app_lock_service.dart';

class AppLockSetupScreen extends StatefulWidget {
  const AppLockSetupScreen({super.key});

  @override
  State<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends State<AppLockSetupScreen> {
  final AppLockService _appLockService = AppLockService();

  String _pin = '';
  String _confirmPin = '';
  bool _confirming = false;
  String _errorMessage = '';

  void _addDigit(String digit) {
    if (_confirming) {
      if (_confirmPin.length >= 4) return;

      setState(() {
        _confirmPin += digit;
        _errorMessage = '';
      });

      if (_confirmPin.length == 4) {
        _finishSetup();
      }
    } else {
      if (_pin.length >= 4) return;

      setState(() {
        _pin += digit;
        _errorMessage = '';
      });

      if (_pin.length == 4) {
        setState(() {
          _confirming = true;
        });
      }
    }
  }

  void _removeDigit() {
    setState(() {
      if (_confirming) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin =
              _confirmPin.substring(0, _confirmPin.length - 1);
        }
      } else {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      }

      _errorMessage = '';
    });
  }

  Future<void> _finishSetup() async {
    if (_pin != _confirmPin) {
      setState(() {
        _confirmPin = '';
        _errorMessage = 'PINs do not match. Try again.';
      });
      return;
    }

    await _appLockService.setPin(_pin);
    await _appLockService.setEnabled(true);

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  void _goBackToFirstStep() {
    setState(() {
      _confirming = false;
      _confirmPin = '';
      _errorMessage = '';
    });
  }

  Widget _pinDot(int index) {
    final currentPin = _confirming ? _confirmPin : _pin;
    final filled = index < currentPin.length;

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

  static const Color _backgroundColor = Color(0xFF0F172A);
  static const Color _cardColor = Color(0xFF1E293B);
  static const Color _primaryColor = Color(0xFF34B7F1);

  @override
  Widget build(BuildContext context) {
    final title = _confirming ? 'Confirm Your PIN' : 'Create App PIN';

    final subtitle = _confirming
        ? 'Enter the same 4-digit PIN again'
        : 'Create a 4-digit PIN to protect SmartHomeX';

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
                Icons.lock_outline_rounded,
                color: _primaryColor,
                size: 36,
              ),
            ),

            const SizedBox(height: 22),

            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
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

                // Back button on confirmation step
                _confirming
                    ? _actionButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: _goBackToFirstStep,
                      )
                    : const SizedBox(),

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
                'SmartHomeX',
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