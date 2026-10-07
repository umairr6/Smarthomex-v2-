import 'package:flutter/material.dart';

class SmartHomeResponsive {
  SmartHomeResponsive._();

  /// Screen width
  static double width(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// Screen height
  static double height(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  /// Small phones
  /// Examples: older/smaller Android phones
  static bool isSmallPhone(BuildContext context) {
    return width(context) < 360;
  }

  /// Normal phones
  static bool isPhone(BuildContext context) {
    return width(context) < 600;
  }

  /// Tablets
  static bool isTablet(BuildContext context) {
    return width(context) >= 600;
  }

  /// Large screens
  static bool isLargeScreen(BuildContext context) {
    return width(context) >= 900;
  }

  /// Responsive horizontal padding
  static double horizontalPadding(BuildContext context) {
    final w = width(context);

    if (w < 360) return 14;
    if (w < 600) return 18;
    if (w < 900) return 28;

    return 40;
  }

  /// Responsive card spacing
  static double cardSpacing(BuildContext context) {
    final w = width(context);

    if (w < 360) return 10;
    if (w < 600) return 12;
    if (w < 900) return 16;

    return 20;
  }

  /// Responsive title size
  static double titleSize(BuildContext context) {
    final w = width(context);

    if (w < 360) return 22;
    if (w < 600) return 25;
    if (w < 900) return 29;

    return 32;
  }

  /// Responsive body size
  static double bodySize(BuildContext context) {
    final w = width(context);

    if (w < 360) return 13;
    if (w < 600) return 14;
    if (w < 900) return 15;

    return 16;
  }

  /// Number of columns for grids
  static int gridColumns(BuildContext context) {
    final w = width(context);

    if (w < 400) return 1;
    if (w < 700) return 2;
    if (w < 1000) return 3;

    return 4;
  }

  /// Responsive maximum content width
  static double maxContentWidth(BuildContext context) {
    final w = width(context);

    if (w < 600) return w;
    if (w < 1000) return 900;

    return 1200;
  }
}
