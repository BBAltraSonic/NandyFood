/// Design Tokens for NandyFood Application
///
/// This file contains all design tokens including colors, typography, spacing,
/// and other design system values that ensure consistency across the app.

import 'package:flutter/material.dart';

// ==============================
// BRAND COLORS
// ==============================

class BrandColors {
  // Primary brand colors - Black and white theme
  static const Color primary = Color(0xFF000000);      // Pure Black
  static const Color primaryLight = Color(0xFF424242);  // Dark Gray
  static const Color primaryDark = Color(0xFF000000);   // Pure Black

  // Secondary brand colors - White and gray tones
  static const Color secondary = Color(0xFFFFFFFF);     // Pure White
  static const Color secondaryLight = Color(0xFFF5F5F5); // Light Gray
  static const Color secondaryDark = Color(0xFF9E9E9E);  // Medium Gray

  // Accent colors - Grayscale tones
  static const Color accent = Color(0xFF757575);        // Medium Gray
  static const Color accentLight = Color(0xFFBDBDBD);   // Light Gray
  static const Color accentDark = Color(0xFF424242);    // Dark Gray
}

// ==============================
// NEUTRAL COLORS
// ==============================

class NeutralColors {
  // Background colors - Modern and clean
  static const Color background = Color(0xFFF8F9FA);     // Light Gray Background
  static const Color surface = Color(0xFFFFFFFF);        // Pure White
  static const Color warmCream = Color(0xFFFFF8E7);      // Warm Cream (unchanged)

  // Text colors - Enhanced contrast
  static const Color textPrimary = Color(0xFF2C3E50);    // Dark Charcoal (unchanged)
  static const Color textSecondary = Color(0xFF6C757D);  // Softer Secondary Text
  static const Color textTertiary = Color(0xFFADB5BD);   // Lighter Tertiary Text
  static const Color textOnPrimary = Color(0xFFFFFFFF);  // White text on primary (unchanged)

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
  // Status colors - Monochrome theme
  static const Color success = Color(0xFF424242);        // Dark Gray (was green)
  static const Color successLight = Color(0xFF757575);   // Medium Gray
  static const Color successDark = Color(0xFF212121);    // Very Dark Gray

  static const Color warning = Color(0xFF616161);        // Medium Dark Gray (was orange)
  static const Color warningLight = Color(0xFF9E9E9E);   // Medium Gray
  static const Color warningDark = Color(0xFF424242);    // Dark Gray

  static const Color error = Color(0xFF000000);          // Black (was red)
  static const Color errorLight = Color(0xFF424242);     // Dark Gray
  static const Color errorDark = Color(0xFF000000);      // Black

  static const Color info = Color(0xFF757575);           // Medium Gray (was blue)
  static const Color infoLight = Color(0xFFBDBDBD);      // Light Gray
  static const Color infoDark = Color(0xFF616161);       // Medium Dark Gray

  // Order status colors - Monochrome theme
  static const Color orderPlaced = Color(0xFF757575);    // Medium Gray
  static const Color orderConfirmed = Color(0xFF424242); // Dark Gray
  static const Color orderPreparing = Color(0xFF616161); // Medium Dark Gray
  static const Color orderReady = Color(0xFF000000);     // Black
  static const Color orderDelivered = Color(0xFF424242); // Dark Gray
  static const Color orderCancelled = Color(0xFF000000); // Black
}

// ==============================
// MEAL TIME COLORS
// ==============================

class MealTimeColors {
  static const Color breakfast = Color(0xFFBDBDBD);      // Light Gray
  static const Color brunch = Color(0xFF9E9E9E);         // Medium Gray
  static const Color lunch = Color(0xFF757575);          // Medium Dark Gray
  static const Color afternoonTea = Color(0xFF616161);   // Dark Gray
  static const Color dinner = Color(0xFF424242);         // Very Dark Gray
  static const Color supper = Color(0xFF212121);         // Near Black
  static const Color lateNight = Color(0xFF000000);      // Pure Black
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

  // Font sizes - Enhanced for better hierarchy
  static const double fontSizeXxs = 10.0;
  static const double fontSizeXs = 12.0;
  static const double fontSizeSm = 14.0;
  static const double fontSizeBase = 16.0;
  static const double fontSizeLg = 18.0;
  static const double fontSizeXl = 20.0;
  static const double fontSize2xl = 26.0;  // Increased from 24
  static const double fontSize3xl = 34.0;  // Increased from 30
  static const double fontSize4xl = 42.0;  // Increased from 36
  static const double fontSize5xl = 56.0;  // Increased from 48

  // Line heights - Improved readability
  static const double lineHeightXxs = 1.2;
  static const double lineHeightXs = 1.3;
  static const double lineHeightSm = 1.4;
  static const double lineHeightBase = 1.5;
  static const double lineHeightLg = 1.6;
  static const double lineHeightXl = 1.7;
  static const double lineHeightTight = 1.1;  // Added for headings
  static const double lineHeightLoose = 1.8;  // Added for body text

  // Letter spacing - Enhanced for brand feel
  static const double letterSpacingXs = -0.5;
  static const double letterSpacingSm = -0.25;
  static const double letterSpacingBase = 0.0;
  static const double letterSpacingLg = 0.25;
  static const double letterSpacingXl = 0.5;
  static const double letterSpacingWide = 1.0;   // Added for display text
  static const double letterSpacingTight = -0.75; // Added for compact text
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
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;     // Increased for more modern feel
  static const double xl = 20.0;     // Increased for cards
  static const double xxl = 28.0;    // Increased for larger elements
  static const double xxxl = 32.0;   // Added for hero elements
  static const double full = 9999.0;

  // Common radius shortcuts
  static BorderRadius borderRadiusXs = BorderRadius.circular(xs);
  static BorderRadius borderRadiusSm = BorderRadius.circular(sm);
  static BorderRadius borderRadiusMd = BorderRadius.circular(md);
  static BorderRadius borderRadiusLg = BorderRadius.circular(lg);
  static BorderRadius borderRadiusXl = BorderRadius.circular(xl);
  static BorderRadius borderRadiusXxl = BorderRadius.circular(xxl);
  static BorderRadius borderRadiusXxxl = BorderRadius.circular(xxxl);
}

// ==============================
// SHADOW TOKENS
// ==============================

class ShadowTokens {
  // Elevation shadows - Softer and more modern
  static const List<BoxShadow> shadowXs = [
    BoxShadow(
      color: Color(0x05000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 8),
      blurRadius: 20,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowXl = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 16),
      blurRadius: 32,
      spreadRadius: 0,
    ),
  ];

  // Colored shadows - Black and white theme
  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: BrandColors.primary.withValues(alpha: 0.2), // Black with opacity
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> secondaryShadow = [
    BoxShadow(
      color: NeutralColors.gray400.withValues(alpha: 0.3), // Gray shadow
      offset: const Offset(0, 4),
      blurRadius: 16,
      spreadRadius: 0,
    ),
  ];

  // Enhanced food card shadow with better elevation
  static List<BoxShadow> foodCardShadow = [
    BoxShadow(
      color: Color(0x0A000000), // More subtle shadow
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Color(0x05000000), // Even more subtle ambient shadow
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
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