import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<double> _scaleAnimation;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(
        0.05,
        0.55,
        curve: Curves.easeOut,
      ),
    );

    _textFade = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(
        0.30,
        0.85,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _startSplash();
  }

  Future<void> _startSplash() async {
    _animationController.forward();

    await Future.delayed(
      const Duration(milliseconds: 2400),
    );

    _goToAuth();
  }

  void _goToAuth() {
    if (!mounted || _navigated) return;

    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (_, animation, __) {
          return const AuthGate();
        },
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ==========================================================
          // BACKGROUND
          // ==========================================================

          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Color(0xFF191919),
                    Color(0xFF0A0A0A),
                    Colors.black,
                  ],
                  stops: [
                    0.0,
                    0.55,
                    1.0,
                  ],
                ),
              ),
            ),
          ),

          // ==========================================================
          // SUBTLE GOLD GLOW
          // ==========================================================

          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD6B36A).withOpacity(0.08),
                        blurRadius: 100,
                        spreadRadius: 25,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==========================================================
          // MAIN BRANDING
          // ==========================================================

          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ==================================================
                        // LOGO
                        // ==================================================

                        FadeTransition(
                          opacity: _logoFade,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF111111),
                              border: Border.all(
                                color: const Color(0xFFD6B36A),
                                width: 1.3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD6B36A)
                                      .withOpacity(0.22),
                                  blurRadius: 35,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.home_rounded,
                              size: 46,
                              color: Color(0xFFF2D18B),
                            ),
                          ),
                        ),

                        const SizedBox(height: 26),

                        // ==================================================
                        // APP NAME
                        // ==================================================

                        FadeTransition(
                          opacity: _textFade,
                          child: const Text(
                            'SmartHomeX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 9),

                        // ==================================================
                        // TAGLINE
                        // ==================================================

                        FadeTransition(
                          opacity: _textFade,
                          child: const Text(
                            'Smart living. Simple control.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // ==========================================================
          // BOTTOM BRANDING
          // ==========================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 38,
            child: FadeTransition(
              opacity: _textFade,
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 1,
                    color: const Color(0xFFD6B36A),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'INTELLIGENT HOME AUTOMATION',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}