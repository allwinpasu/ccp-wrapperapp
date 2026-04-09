import 'package:flutter/material.dart';

class AppFonts {
  // Using default system fonts
  static const String primaryFont = 'Roboto'; // Android default
  static const String secondaryFont = 'San Francisco'; // iOS default

  // Font Sizes
  static const double heading1 = 32.0;
  static const double heading2 = 24.0;
  static const double heading3 = 20.0;
  static const double heading4 = 18.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double caption = 10.0;

  // Text Styles - Remove fontFamily to use system default
  static const TextStyle h1 = TextStyle(
    fontSize: heading1,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: heading2,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: heading3,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: heading4,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLargeStyle = TextStyle(
    fontSize: bodyLarge,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodyMediumStyle = TextStyle(
    fontSize: bodyMedium,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle bodySmallStyle = TextStyle(
    fontSize: bodySmall,
    fontWeight: FontWeight.normal,
  );
}
