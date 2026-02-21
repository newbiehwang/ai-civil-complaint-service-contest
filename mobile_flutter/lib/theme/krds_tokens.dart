import 'package:flutter/material.dart';

class KrdsTokens {
  const KrdsTokens._();

  // 8pt spacing system
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space24 = 24;
  static const double space32 = 32;

  // Standard style shape (2~12px)
  static const double radiusXs = 2;
  static const double radiusSm = 6;
  static const double radiusMd = 8;
  static const double radiusLg = 10;
  static const double radiusXl = 12;

  // Elevation (light mode) tuned for KRDS-like subtle hierarchy.
  static const List<BoxShadow> elevationPlus1 = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevationPlus2 = [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 14,
      offset: Offset(0, 4),
    ),
  ];
}

