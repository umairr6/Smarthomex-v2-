import 'dart:math' as math;

import 'package:flutter/material.dart';

class SmartHomeBackground extends StatefulWidget {
  final Widget child;

  const SmartHomeBackground({
    super.key,
    required this.child,
  });

  @override
  State<SmartHomeBackground> createState() =>
      _SmartHomeBackgroundState();
}

class _SmartHomeBackgroundState
    extends State<SmartHomeBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        seconds: 24,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,

      builder: (context, child) {
        final t = _controller.value;
        final angle = t * math.pi * 2;

        return Stack(
          fit: StackFit.expand,

          children: [
            // ==========================================
            // DEEP SPACE BASE
            // ==========================================

            const ColoredBox(
              color: Color(0xFF050816),
            ),

            // ==========================================
            // BLUE NEON AURORA
            // ==========================================

            Positioned(
              left: -180 + math.sin(angle) * 100,
              top: -150 + math.cos(angle) * 90,

              child: _orb(
                size: 440,
                color: const Color(0xFF0066FF),
                opacity: 0.20,
              ),
            ),

            // ==========================================
            // VIOLET AURORA
            // ==========================================

            Positioned(
              right: -190 + math.cos(angle) * 120,
              top: 40 + math.sin(angle) * 120,

              child: _orb(
                size: 450,
                color: const Color(0xFF7C3AED),
                opacity: 0.17,
              ),
            ),

            // ==========================================
            // CYAN AURORA
            // ==========================================

            Positioned(
              left: 30 + math.cos(angle) * 130,
              bottom: -220 + math.sin(angle) * 100,

              child: _orb(
                size: 480,
                color: const Color(0xFF00E5FF),
                opacity: 0.13,
              ),
            ),

            // ==========================================
            // SMALL MOVING GLOW
            // ==========================================

            Positioned(
              right: 100 + math.sin(angle * 1.5) * 130,
              bottom: 80 + math.cos(angle * 1.5) * 100,

              child: _orb(
                size: 230,
                color: const Color(0xFF3B82F6),
                opacity: 0.12,
              ),
            ),

            // ==========================================
            // DARK GLASS OVERLAY
            // ==========================================

            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,

                  colors: [
                    Colors.black.withOpacity(0.10),
                    Colors.transparent,
                    Colors.black.withOpacity(0.20),
                  ],
                ),
              ),
            ),

            // ==========================================
            // APPLICATION
            // ==========================================

            widget.child,
          ],
        );
      },
    );
  }

  Widget _orb({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(opacity * 0.35),
              Colors.transparent,
            ],

            stops: const [
              0.0,
              0.42,
              1.0,
            ],
          ),
        ),
      ),
    );
  }
}