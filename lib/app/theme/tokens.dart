import 'package:flutter/material.dart';

/// Design tokens for PaisaSplit app
class AppTokens {
  AppTokens._();

  // Light theme colors (exact spec)
  static const lightBg = Color(0xFFF8FAFC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF0F172A);
  static const lightMuted = Color(0xFF64748B);
  static const lightBorder = Color(0x140F172A); // rgba(15,23,42,0.08)
  static const lightPrimary = Color(0xFF0D9488);
  static const lightPrimarySoft = Color(0xFF99F6E4);
  static const lightAccent = Color(0xFFF59E0B);
  static const lightRing = Color(0x4D0D9488); // rgba(13,148,136,0.30)
  static const lightPositive = Color(0xFF16A34A);
  static const lightNegative = Color(0xFFDC2626);
  static const lightWarning = Color(0xFFD97706);
  static const lightSubtle = Color(0xFFEEF2F6);

  // Dark theme colors (exact spec)
  static const darkBg = Color(0xFF0B1220);
  static const darkSurface = Color(0xFF111827);
  static const darkText = Color(0xFFE5E7EB);
  static const darkMuted = Color(0xFF94A3B8);
  static const darkBorder = Color(0x1F94A3B8); // rgba(148,163,184,0.12)
  static const darkPrimary = Color(0xFF2DD4BF);
  static const darkPrimarySoft = Color(0xFF134E4A);
  static const darkAccent = Color(0xFFFBBF24);
  static const darkRing = Color(0x592DD4BF); // rgba(45,212,191,0.35)
  static const darkPositive = Color(0xFF22C55E);
  static const darkNegative = Color(0xFFF87171);
  static const darkWarning = Color(0xFFF59E0B);
  static const darkSubtle = Color(0xFF0F172A);

  // Typography (using system fonts initially as per spec)
  static const String fontFamily = 'System';

  // Responsive breakpoints (as per spec)
  static const double breakpointCompact = 600.0;  // <600dp
  static const double breakpointMedium = 840.0;   // 600-840dp
  // >=840dp is expanded
  
  // Spacing (4pt grid)
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;
  static const double space16 = 64.0;
  static const double space20 = 80.0;

  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusFull = 9999.0;

  // Breakpoints for adaptive layouts
  static const double compactBreakpoint = 600.0;
  static const double mediumBreakpoint = 840.0;

  // Elevation
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 4.0;
  static const double elevation4 = 8.0;
  static const double elevation5 = 12.0;

  // Animation durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 350);

  // Icon sizes
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;

  // Button heights
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;

  // Input heights
  static const double inputHeight = 48.0;

  // Avatar sizes
  static const double avatarSm = 24.0;
  static const double avatarMd = 32.0;
  static const double avatarLg = 40.0;
  static const double avatarXl = 48.0;

  // Z-index layers
  static const int zIndexDropdown = 1000;
  static const int zIndexSticky = 1020;
  static const int zIndexFixed = 1030;
  static const int zIndexModalBackdrop = 1040;
  static const int zIndexModal = 1050;
  static const int zIndexPopover = 1060;
  static const int zIndexTooltip = 1070;
  static const int zIndexToast = 1080;

  // Content max widths
  static const double maxWidthSm = 384.0;
  static const double maxWidthMd = 448.0;
  static const double maxWidthLg = 512.0;
  static const double maxWidthXl = 576.0;
  static const double maxWidth2xl = 672.0;
  static const double maxWidth3xl = 768.0;
  static const double maxWidth4xl = 896.0;
  static const double maxWidth5xl = 1024.0;
  static const double maxWidth6xl = 1152.0;
  static const double maxWidth7xl = 1280.0;

  // Screen padding
  static const EdgeInsets screenPadding = EdgeInsets.all(space4);
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(horizontal: space4);
  static const EdgeInsets screenPaddingVertical = EdgeInsets.symmetric(vertical: space4);

  // Card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(space4);
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(space6);

  // List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space3,
  );

  // Button padding
  static const EdgeInsets buttonPaddingSm = EdgeInsets.symmetric(
    horizontal: space3,
    vertical: space2,
  );
  static const EdgeInsets buttonPaddingMd = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space3,
  );
  static const EdgeInsets buttonPaddingLg = EdgeInsets.symmetric(
    horizontal: space6,
    vertical: space4,
  );

  // Input padding
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: space4,
    vertical: space3,
  );

  // Chip padding
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: space3,
    vertical: space2,
  );

  // Safe area padding
  static const EdgeInsets safeAreaPadding = EdgeInsets.only(
    left: space4,
    right: space4,
    bottom: space4,
  );
}
