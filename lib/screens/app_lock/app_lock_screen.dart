import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/responsive.dart';
import '../../services/app_lock_service.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final AppLockService _appLockService = AppLockService();

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

  Widget _pinDot(int index, double size) {
    final filled = index < _pin.length;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      margin: EdgeInsets.symmetric(horizontal: size < 13 ? 5 : 7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? SmartHomeColors.gold : Colors.white24,
        border: Border.all(
          color: filled ? SmartHomeColors.gold : Colors.white38,
        ),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: SmartHomeColors.gold.withValues(alpha: 0.28),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _numberButton(
    BuildContext context,
    String value, {
    required double size,
    required double fontSize,
  }) {
    return Semantics(
      button: true,
      label: 'Digit $value',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _isChecking ? null : () => _addDigit(value),
          customBorder: const CircleBorder(),
          splashColor: SmartHomeColors.gold.withValues(alpha: 0.16),
          highlightColor: SmartHomeColors.gold.withValues(alpha: 0.06),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SmartHomeColors.surfaceElevated,
              border: Border.all(
                color: SmartHomeColors.border,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  color: SmartHomeColors.textPrimary,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
  }) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: _isChecking ? null : onTap,
          customBorder: const CircleBorder(),
          splashColor: SmartHomeColors.gold.withValues(alpha: 0.14),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(
                icon,
                color: _isChecking
                    ? SmartHomeColors.textDisabled
                    : SmartHomeColors.textSecondary,
                size: size * 0.34,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad({
    required double buttonSize,
    required double fontSize,
    required double horizontalPadding,
    required double spacing,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 3,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1,
        children: [
          _numberButton(
            context,
            '1',
            size: buttonSize,
            fontSize: fontSize,
          ),
          _numberButton(
            context,
            '2',
            size: buttonSize,
            fontSize: fontSize,
          ),
          _numberButton(
            context,
            '3',
            size: buttonSize,
            fontSize: fontSize,
          ),
          _numberButton(
            context,
            '4',
            size: buttonSize,
            fontSize: fontSize,
          ),
          _numberButton(
            context,
            '5',
            size: buttonSize,
            fontSize: fontSize,
          ),
          _numberButton(
            context,
            '6',
            size: buttonSize,
            fontSize: fontSize,
          ),
          _numberButton(
            context,
            '7',
            size: buttonSize,
            fontSize: fontSize,
          ),
          _numberButton(
            context,
            '8',
            size: buttonSize,
            fontSize: fontSize,
          ),
          _numberButton(
            context,
            '9',
            size: buttonSize,
            fontSize: fontSize,
          ),
          const SizedBox.shrink(),
          _numberButton(
            context,
            '0',
            size: buttonSize,
            fontSize: fontSize,
          ),
          _actionButton(
            icon: Icons.backspace_outlined,
            onTap: _removeDigit,
            size: buttonSize,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallPhone = SmartHomeResponsive.isSmallPhone(context);
    final isPhone = SmartHomeResponsive.isPhone(context);
    final width = SmartHomeResponsive.width(context);

    final iconSize = isSmallPhone ? 60.0 : isPhone ? 68.0 : 76.0;
    final keypadButtonSize = isSmallPhone ? 62.0 : isPhone ? 70.0 : 76.0;
    final keypadSpacing = isSmallPhone ? 10.0 : isPhone ? 14.0 : 18.0;
    final pagePadding = SmartHomeResponsive.horizontalPadding(context);
    final titleSize = isSmallPhone ? 22.0 : isPhone ? 24.0 : 28.0;
    final dotSize = isSmallPhone ? 11.0 : 14.0;

    return Scaffold(
      backgroundColor: SmartHomeColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.25),
            radius: 1.15,
            colors: [
              Color(0xFF17120A),
              SmartHomeColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactHeight = constraints.maxHeight < 700;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: pagePadding,
                      vertical: compactHeight ? 14 : 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: SmartHomeResponsive.maxContentWidth(context),
                          child: Column(
                            children: [
                              Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: SmartHomeColors.gold.withValues(
                                    alpha: 0.10,
                                  ),
                                  border: Border.all(
                                    color: SmartHomeColors.gold.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: SmartHomeColors.gold.withValues(
                                        alpha: 0.16,
                                      ),
                                      blurRadius: 28,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.lock_rounded,
                                  color: SmartHomeColors.goldLight,
                                  size: iconSize * 0.48,
                                ),
                              ),
                              SizedBox(height: compactHeight ? 14 : 20),
                              Text(
                                'SmartHomeX Locked',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: SmartHomeColors.textPrimary,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enter your 4-digit PIN to continue',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: SmartHomeColors.textSecondary,
                                  fontSize: SmartHomeResponsive.bodySize(
                                    context,
                                  ),
                                  height: 1.45,
                                ),
                              ),
                              SizedBox(height: compactHeight ? 22 : 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  4,
                                  (index) => _pinDot(index, dotSize),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 24,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _isChecking
                                      ? const SizedBox(
                                          key: ValueKey('checking'),
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: SmartHomeColors.gold,
                                          ),
                                        )
                                      : Text(
                                          _errorMessage,
                                          key: ValueKey(_errorMessage),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: SmartHomeColors.offline,
                                            fontSize: 13,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: compactHeight ? 12 : 18),
                              _buildKeypad(
                                buttonSize: keypadButtonSize,
                                fontSize: isSmallPhone ? 22 : 25,
                                horizontalPadding: isSmallPhone ? 12 : 22,
                                spacing: keypadSpacing,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: compactHeight ? 20 : 28),
                        Text(
                          _isChecking ? 'VERIFYING PIN' : 'SmartHomeX',
                          style: TextStyle(
                            color: _isChecking
                                ? SmartHomeColors.goldDark
                                : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'SECURE SMART LIVING',
                          style: TextStyle(
                            color: SmartHomeColors.goldDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
