import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'color_schemes.dart';
import 'tokens.dart';

/// App theme configuration
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorSchemes.light,
      fontFamily: AppTokens.fontFamily,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorSchemes.light.surface,
        foregroundColor: AppColorSchemes.light.onSurface,
        elevation: 0,
        scrolledUnderElevation: AppTokens.elevation1,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTokens.lightText,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppColorSchemes.light.surface,
        elevation: AppTokens.elevation1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        ),
        margin: const EdgeInsets.all(AppTokens.space2),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorSchemes.light.primary,
          foregroundColor: AppColorSchemes.light.onPrimary,
          elevation: AppTokens.elevation2,
          padding: AppTokens.buttonPaddingMd,
          minimumSize: const Size(0, AppTokens.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorSchemes.light.primary,
          padding: AppTokens.buttonPaddingMd,
          minimumSize: const Size(0, AppTokens.buttonHeightMd),
          side: BorderSide(color: AppColorSchemes.light.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorSchemes.light.primary,
          padding: AppTokens.buttonPaddingMd,
          minimumSize: const Size(0, AppTokens.buttonHeightMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorSchemes.light.surface,
        contentPadding: AppTokens.inputPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          borderSide: BorderSide(color: AppColorSchemes.light.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          borderSide: BorderSide(color: AppColorSchemes.light.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          borderSide: BorderSide(color: AppColorSchemes.light.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          borderSide: BorderSide(color: AppColorSchemes.light.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
          borderSide: BorderSide(color: AppColorSchemes.light.error, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 16,
          color: AppTokens.lightMuted,
        ),
        hintStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 16,
          color: AppTokens.lightMuted,
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColorSchemes.light.surfaceVariant,
        selectedColor: AppColorSchemes.light.primaryContainer,
        disabledColor: AppColorSchemes.light.surfaceVariant.withOpacity(0.5),
        padding: AppTokens.chipPadding,
        labelStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        ),
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: AppTokens.listItemPadding,
        titleTextStyle: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTokens.lightText,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 14,
          color: AppTokens.lightMuted,
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorSchemes.light.surface,
        selectedItemColor: AppColorSchemes.light.primary,
        unselectedItemColor: AppColorSchemes.light.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: AppTokens.elevation3,
        selectedLabelStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColorSchemes.light.primary,
        foregroundColor: AppColorSchemes.light.onPrimary,
        elevation: AppTokens.elevation3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColorSchemes.light.surface,
        elevation: AppTokens.elevation4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXl),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTokens.lightText,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 16,
          color: AppTokens.lightText,
        ),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColorSchemes.light.surface,
        elevation: AppTokens.elevation4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusXl),
          ),
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorSchemes.light.inverseSurface,
        contentTextStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 14,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppTokens.lightText,
        ),
        displayMedium: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTokens.lightText,
        ),
        displaySmall: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppTokens.lightText,
        ),
        headlineLarge: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppTokens.lightText,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTokens.lightText,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTokens.lightText,
        ),
        titleLarge: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTokens.lightText,
        ),
        titleMedium: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTokens.lightText,
        ),
        titleSmall: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTokens.lightText,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppTokens.lightText,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppTokens.lightText,
        ),
        bodySmall: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppTokens.lightMuted,
        ),
        labelLarge: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTokens.lightText,
        ),
        labelMedium: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTokens.lightText,
        ),
        labelSmall: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppTokens.lightMuted,
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorSchemes.dark,
      fontFamily: AppTokens.fontFamily,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorSchemes.dark.surface,
        foregroundColor: AppColorSchemes.dark.onSurface,
        elevation: 0,
        scrolledUnderElevation: AppTokens.elevation1,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppTokens.darkText,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}
