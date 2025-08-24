import 'package:flutter/material.dart';
import 'tokens.dart';

/// Color schemes for light and dark themes
class AppColorSchemes {
  AppColorSchemes._();

  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: AppTokens.lightPrimary,
    onPrimary: Colors.white,
    primaryContainer: AppTokens.lightPrimarySoft,
    onPrimaryContainer: AppTokens.lightText,
    secondary: AppTokens.lightAccent,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFFEF3C7),
    onSecondaryContainer: AppTokens.lightText,
    tertiary: AppTokens.lightPositive,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFDCFCE7),
    onTertiaryContainer: AppTokens.lightText,
    error: AppTokens.lightNegative,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: AppTokens.lightText,
    background: AppTokens.lightBg,
    onBackground: AppTokens.lightText,
    surface: AppTokens.lightSurface,
    onSurface: AppTokens.lightText,
    surfaceVariant: AppTokens.lightSubtle,
    onSurfaceVariant: AppTokens.lightMuted,
    outline: AppTokens.lightBorder,
    outlineVariant: Color(0x0A0F172A),
    shadow: Colors.black26,
    scrim: Colors.black54,
    inverseSurface: AppTokens.lightText,
    onInverseSurface: AppTokens.lightSurface,
    inversePrimary: AppTokens.lightPrimarySoft,
    surfaceTint: AppTokens.lightPrimary,
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppTokens.darkPrimary,
    onPrimary: AppTokens.darkText,
    primaryContainer: AppTokens.darkPrimarySoft,
    onPrimaryContainer: AppTokens.darkText,
    secondary: AppTokens.darkAccent,
    onSecondary: AppTokens.darkText,
    secondaryContainer: Color(0xFF92400E),
    onSecondaryContainer: AppTokens.darkText,
    tertiary: AppTokens.darkPositive,
    onTertiary: AppTokens.darkText,
    tertiaryContainer: Color(0xFF166534),
    onTertiaryContainer: AppTokens.darkText,
    error: AppTokens.darkNegative,
    onError: AppTokens.darkText,
    errorContainer: Color(0xFF991B1B),
    onErrorContainer: AppTokens.darkText,
    background: AppTokens.darkBg,
    onBackground: AppTokens.darkText,
    surface: AppTokens.darkSurface,
    onSurface: AppTokens.darkText,
    surfaceVariant: AppTokens.darkSubtle,
    onSurfaceVariant: AppTokens.darkMuted,
    outline: AppTokens.darkBorder,
    outlineVariant: Color(0x1494A3B8),
    shadow: Colors.black54,
    scrim: Colors.black87,
    inverseSurface: AppTokens.darkText,
    onInverseSurface: AppTokens.darkSurface,
    inversePrimary: AppTokens.darkPrimarySoft,
    surfaceTint: AppTokens.darkPrimary,
  );

  /// Custom colors for specific use cases
  static const Color warningLight = AppTokens.lightWarning;
  static const Color warningDark = AppTokens.darkWarning;
  
  static const Color positiveLight = AppTokens.lightPositive;
  static const Color positiveDark = AppTokens.darkPositive;
  
  static const Color negativeLight = AppTokens.lightNegative;
  static const Color negativeDark = AppTokens.darkNegative;
  
  static const Color mutedLight = AppTokens.lightMuted;
  static const Color mutedDark = AppTokens.darkMuted;
  
  static const Color ringLight = AppTokens.lightRing;
  static const Color ringDark = AppTokens.darkRing;

  /// Get custom color based on theme brightness
  static Color getWarning(Brightness brightness) =>
      brightness == Brightness.light ? warningLight : warningDark;
      
  static Color getPositive(Brightness brightness) =>
      brightness == Brightness.light ? positiveLight : positiveDark;
      
  static Color getNegative(Brightness brightness) =>
      brightness == Brightness.light ? negativeLight : negativeDark;
      
  static Color getMuted(Brightness brightness) =>
      brightness == Brightness.light ? mutedLight : mutedDark;
      
  static Color getRing(Brightness brightness) =>
      brightness == Brightness.light ? ringLight : ringDark;
}
