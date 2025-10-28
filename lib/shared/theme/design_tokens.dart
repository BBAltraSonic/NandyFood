/// Design Tokens for NandyFood Application
///
/// This file contains all design tokens including colors, typography, spacing,
/// and other design system values that ensure consistency across the app.

import 'package:flutter/material.dart';

// ==============================
// BRAND COLORS
// ==============================

class BrandColors {
  // Primary brand colors
  static const Color primary = Color(0xFF4A7B59);      // Olive Green
  static const Color primaryLight = Color(0xFF6B9C7A);   // Light Olive Green
  static const Color primaryDark = Color(0xFF3A5A47);    // Dark Olive Green

  // Secondary brand colors
  static const Color secondary = Color(0xFFFF9800);     // Warm Orange
  static const Color secondaryLight = Color(0xFFFFB74D); // Light Orange
  static const Color secondaryDark = Color(0xFFE68900);  // Dark Orange

  // Accent colors
  static const Color accent = Color(0xFF8FA998);         // Muted Green
  static const Color accentLight = Color(0xFFB8C9BE);   // Light Muted Green
  static const Color accentDark = Color(0xFF6B8474);    // Dark Muted Green
}

// ==============================
// NEUTRAL COLORS
// ==============================

class NeutralColors {
  // Background colors
  static const Color background = Color(0xFFF5F7F4);     // Sage Background
  static const Color surface = Color(0xFFFDFDFD);        // Card White
  static const Color warmCream = Color(0xFFFFF8E7);      // Warm Cream

  // Text colors
  static const Color textPrimary = Color(0xFF2C3E50);    // Primary Text
  static const Color textSecondary = Color(0xFF7F8C8D);  // Secondary Text
  static const Color textTertiary = Color(0xFFBDC3C7);   // Tertiary Text
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // White text on primary

  // Neutral grays
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);
}

// ==============================
// SEMANTIC COLORS
// ==============================

class SemanticColors {
  // Status colors
  static const Color success = Color(0xFF4CAF50);        // Success Green
  static const Color successLight = Color(0xFF81C784);   // Light Success
  static const Color successDark = Color(0xFF388E3C);    // Dark Success

  static const Color warning = Color(0xFFFF9800);        // Warning Orange
  static const Color warningLight = Color(0xFFFFB74D);   // Light Warning
  static const Color warningDark = Color(0xFFF57C00);    // Dark Warning

  static const Color error = Color(0xFFE53935);          // Error Red
  static const Color errorLight = Color(0xFFEF5350);     // Light Error
  static const Color errorDark = Color(0xFFD32F2F);      // Dark Error

  static const Color info = Color(0xFF2196F3);           // Info Blue
  static const Color infoLight = Color(0xFF64B5F6);      // Light Info
  static const Color infoDark = Color(0xFF1976D2);       // Dark Info

  // Order status colors
  static const Color orderPlaced = Color(0xFF2196F3);    // Blue
  static const Color orderConfirmed = Color(0xFF9C27B0); // Purple
  static const Color orderPreparing = Color(0xFFFF9800); // Orange
  static const Color orderReady = Color(0xFF4CAF50);     // Green
  static const Color orderDelivered = Color(0xFF8BC34A); // Light Green
  static const Color orderCancelled = Color(0xFFE53935); // Red
}

// ==============================
// MEAL TIME COLORS
// ==============================

class MealTimeColors {
  static const Color breakfast = Color(0xFFFFB74D);      // Warm Yellow
  static const Color brunch = Color(0xFFFF8A65);         // Light Orange
  static const Color lunch = Color(0xFF4CAF50);          // Fresh Green
  static const Color afternoonTea = Color(0xFF7986CB);   // Indigo
  static const Color dinner = Color(0xFF5C6BC0);         // Blue-Indigo
  static const Color supper = Color(0xFFFF7043);         // Deep Orange
  static const Color lateNight = Color(0xFF5E35B1);      // Deep Purple
}

// ==============================
// TYPOGRAPHY TOKENS
// ==============================

class TypographyTokens {
  // Font families
  static const String fontFamilyPrimary = 'Inter';
  static const String fontFamilySecondary = 'Roboto';

  // Font weights
  static const FontWeight fontWeightThin = FontWeight.w100;
  static const FontWeight fontWeightExtraLight = FontWeight.w200;
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightExtraBold = FontWeight.w800;
  static const FontWeight fontWeightBlack = FontWeight.w900;

  // Font sizes
  static const double fontSizeXxs = 10.0;
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 24.0;
  static const double fontSize3xl = 30.0;
  static const double fontSize4xl = 36.0;
  static const double fontSize5xl = 48.0;

  // Line heights
  static const double lineHeightXxs = 1.2;
  static const double lineHeightXs = 1.3;
  static const double lineHeightSm = 1.4;
  static const double lineHeightBase = 1.5;
  static const double lineHeightLg = 1.6;
  static const double lineHeightXl = 1.7;

  // Letter spacing
  static const double letterSpacingXs = -0.5;
  static const double letterSpacingSm = -0.25;
  static const double letterSpacingBase = 0.0;
  static const double letterSpacingLg = 0.25;
  static const double letterSpacingXl = 0.5;
}

// ==============================
// SPACING TOKENS
// ==============================

class SpacingTokens {
  // Base spacing unit (4px)
  static const double unit = 4.0;

  // Spacing scale
  static const double spacing0 = 0.0;      // 0px
  static const double spacing1 = 4.0;      // 4px
  static const double spacing2 = 8.0;      // 8px
  static const double spacing3 = 12.0;     // 12px
  static const double spacing4 = 16.0;     // 16px
  static const double spacing5 = 20.0;     // 20px
  static const double spacing6 = 24.0;     // 24px
  static const double spacing8 = 32.0;     // 32px
  static const double spacing10 = 40.0;    // 40px
  static const double spacing12 = 48.0;    // 48px
  static const double spacing16 = 64.0;    // 64px
  static const double spacing20 = 80.0;    // 80px
  static const double spacing24 = 96.0;    // 96px
  static const double spacing32 = 128.0;   // 128px

  // Common spacing shortcuts
  static const double xs = spacing1;       // 4px
  static const double sm = spacing2;       // 8px
  static const double md = spacing3;       // 12px
  static const double lg = spacing4;       // 16px
  static const double xl = spacing5;       // 20px
  static const double xxl = spacing6;      // 24px
}

// ==============================
// BORDER RADIUS TOKENS
// ==============================

class BorderRadiusTokens {
  static const double none = 0.0;
  static const double xs = 2.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
  static const double full = 9999.0;

  // Common radius shortcuts
  static BorderRadius borderRadiusXs = BorderRadius.circular(xs);
  static BorderRadius borderRadiusSm = BorderRadius.circular(sm);
  static BorderRadius borderRadiusMd = BorderRadius.circular(md);
  static BorderRadius borderRadiusLg = BorderRadius.circular(lg);
  static BorderRadius borderRadiusXl = BorderRadius.circular(xl);
  static BorderRadius borderRadiusXxl = BorderRadius.circular(xxl);
}

// ==============================
// SHADOW TOKENS
// ==============================

class ShadowTokens {
  // Elevation shadows
  static const List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 4),
      blurRadius: 6,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 10),
      blurRadius: 15,
    ),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 20),
      blurRadius: 25,
    ),
  ];

  // Colored shadows
  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: BrandColors.primary.withValues(alpha: 0.2),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static List<BoxShadow> secondaryShadow = [
    BoxShadow(
      color: BrandColors.secondary.withValues(alpha: 0.2),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];
}

// ==============================
// ANIMATION TOKENS
// ==============================

class AnimationTokens {
  // Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationSlower = Duration(milliseconds: 800);

  // Curves
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveBounceIn = Curves.bounceIn;
  static const Curve curveBounceOut = Curves.bounceOut;
  static const Curve curveElasticOut = Curves.elasticOut;
}

// ==============================
// BREAKPOINT TOKENS
// ==============================

class BreakpointTokens {
  static const double xs = 0;      // Extra small devices
  static const double sm = 576;    // Small devices
  static const double md = 768;    // Medium devices
  static const double lg = 992;    // Large devices
  static const double xl = 1200;   // Extra large devices
  static const double xxl = 1400;  // Extra extra large devices

  // Mobile first approach
  static bool isMobile(double width) => width < md;
  static bool isTablet(double width) => width >= md && width < lg;
  static bool isDesktop(double width) => width >= lg;
}

// ==============================
// Z-INDEX TOKENS
// ==============================

class ZIndexTokens {
  static const int dropdown = 1000;
  static const int sticky = 1020;
  static const int fixed = 1030;
  static const int modalBackdrop = 1040;
  static const int modal = 1050;
  static const int popover = 1060;
  static const int tooltip = 1070;
  static const int notification = 1080;
  static const int maximum = 9999;
}