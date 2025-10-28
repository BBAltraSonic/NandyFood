/// Theme Extensions for NandyFood Application
///
/// This file provides extension classes that can be added to ThemeData
/// to access custom design tokens and theme-specific values.

import 'package:flutter/material.dart';
import 'design_tokens.dart';

// ==============================
// BRAND COLORS EXTENSION
// ==============================

@immutable
class BrandColorsExtension extends ThemeExtension<BrandColorsExtension> {
  const BrandColorsExtension({
    this.primary = BrandColors.primary,
    this.primaryLight = BrandColors.primaryLight,
    this.primaryDark = BrandColors.primaryDark,
    this.secondary = BrandColors.secondary,
    this.secondaryLight = BrandColors.secondaryLight,
    this.secondaryDark = BrandColors.secondaryDark,
    this.accent = BrandColors.accent,
    this.accentLight = BrandColors.accentLight,
    this.accentDark = BrandColors.accentDark,
  });

  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color secondary;
  final Color secondaryLight;
  final Color secondaryDark;
  final Color accent;
  final Color accentLight;
  final Color accentDark;

  @override
  BrandColorsExtension copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? secondary,
    Color? secondaryLight,
    Color? secondaryDark,
    Color? accent,
    Color? accentLight,
    Color? accentDark,
  }) {
    return BrandColorsExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      secondary: secondary ?? this.secondary,
      secondaryLight: secondaryLight ?? this.secondaryLight,
      secondaryDark: secondaryDark ?? this.secondaryDark,
      accent: accent ?? this.accent,
      accentLight: accentLight ?? this.accentLight,
      accentDark: accentDark ?? this.accentDark,
    );
  }

  @override
  BrandColorsExtension lerp(ThemeExtension<BrandColorsExtension>? other, double t) {
    if (other is! BrandColorsExtension) {
      return this;
    }

    return BrandColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryLight: Color.lerp(secondaryLight, other.secondaryLight, t)!,
      secondaryDark: Color.lerp(secondaryDark, other.secondaryDark, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
    );
  }
}

// ==============================
// SEMANTIC COLORS EXTENSION
// ==============================

@immutable
class SemanticColorsExtension extends ThemeExtension<SemanticColorsExtension> {
  const SemanticColorsExtension({
    this.success = SemanticColors.success,
    this.successLight = SemanticColors.successLight,
    this.successDark = SemanticColors.successDark,
    this.warning = SemanticColors.warning,
    this.warningLight = SemanticColors.warningLight,
    this.warningDark = SemanticColors.warningDark,
    this.error = SemanticColors.error,
    this.errorLight = SemanticColors.errorLight,
    this.errorDark = SemanticColors.errorDark,
    this.info = SemanticColors.info,
    this.infoLight = SemanticColors.infoLight,
    this.infoDark = SemanticColors.infoDark,
    this.orderPlaced = SemanticColors.orderPlaced,
    this.orderConfirmed = SemanticColors.orderConfirmed,
    this.orderPreparing = SemanticColors.orderPreparing,
    this.orderReady = SemanticColors.orderReady,
    this.orderDelivered = SemanticColors.orderDelivered,
    this.orderCancelled = SemanticColors.orderCancelled,
  });

  final Color success;
  final Color successLight;
  final Color successDark;
  final Color warning;
  final Color warningLight;
  final Color warningDark;
  final Color error;
  final Color errorLight;
  final Color errorDark;
  final Color info;
  final Color infoLight;
  final Color infoDark;
  final Color orderPlaced;
  final Color orderConfirmed;
  final Color orderPreparing;
  final Color orderReady;
  final Color orderDelivered;
  final Color orderCancelled;

  @override
  SemanticColorsExtension copyWith({
    Color? success,
    Color? successLight,
    Color? successDark,
    Color? warning,
    Color? warningLight,
    Color? warningDark,
    Color? error,
    Color? errorLight,
    Color? errorDark,
    Color? info,
    Color? infoLight,
    Color? infoDark,
    Color? orderPlaced,
    Color? orderConfirmed,
    Color? orderPreparing,
    Color? orderReady,
    Color? orderDelivered,
    Color? orderCancelled,
  }) {
    return SemanticColorsExtension(
      success: success ?? this.success,
      successLight: successLight ?? this.successLight,
      successDark: successDark ?? this.successDark,
      warning: warning ?? this.warning,
      warningLight: warningLight ?? this.warningLight,
      warningDark: warningDark ?? this.warningDark,
      error: error ?? this.error,
      errorLight: errorLight ?? this.errorLight,
      errorDark: errorDark ?? this.errorDark,
      info: info ?? this.info,
      infoLight: infoLight ?? this.infoLight,
      infoDark: infoDark ?? this.infoDark,
      orderPlaced: orderPlaced ?? this.orderPlaced,
      orderConfirmed: orderConfirmed ?? this.orderConfirmed,
      orderPreparing: orderPreparing ?? this.orderPreparing,
      orderReady: orderReady ?? this.orderReady,
      orderDelivered: orderDelivered ?? this.orderDelivered,
      orderCancelled: orderCancelled ?? this.orderCancelled,
    );
  }

  @override
  SemanticColorsExtension lerp(ThemeExtension<SemanticColorsExtension>? other, double t) {
    if (other is! SemanticColorsExtension) {
      return this;
    }

    return SemanticColorsExtension(
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      successDark: Color.lerp(successDark, other.successDark, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      warningDark: Color.lerp(warningDark, other.warningDark, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorLight: Color.lerp(errorLight, other.errorLight, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      infoDark: Color.lerp(infoDark, other.infoDark, t)!,
      orderPlaced: Color.lerp(orderPlaced, other.orderPlaced, t)!,
      orderConfirmed: Color.lerp(orderConfirmed, other.orderConfirmed, t)!,
      orderPreparing: Color.lerp(orderPreparing, other.orderPreparing, t)!,
      orderReady: Color.lerp(orderReady, other.orderReady, t)!,
      orderDelivered: Color.lerp(orderDelivered, other.orderDelivered, t)!,
      orderCancelled: Color.lerp(orderCancelled, other.orderCancelled, t)!,
    );
  }
}

// ==============================
// MEAL TIME COLORS EXTENSION
// ==============================

@immutable
class MealTimeColorsExtension extends ThemeExtension<MealTimeColorsExtension> {
  const MealTimeColorsExtension({
    this.breakfast = MealTimeColors.breakfast,
    this.brunch = MealTimeColors.brunch,
    this.lunch = MealTimeColors.lunch,
    this.afternoonTea = MealTimeColors.afternoonTea,
    this.dinner = MealTimeColors.dinner,
    this.supper = MealTimeColors.supper,
    this.lateNight = MealTimeColors.lateNight,
  });

  final Color breakfast;
  final Color brunch;
  final Color lunch;
  final Color afternoonTea;
  final Color dinner;
  final Color supper;
  final Color lateNight;

  @override
  MealTimeColorsExtension copyWith({
    Color? breakfast,
    Color? brunch,
    Color? lunch,
    Color? afternoonTea,
    Color? dinner,
    Color? supper,
    Color? lateNight,
  }) {
    return MealTimeColorsExtension(
      breakfast: breakfast ?? this.breakfast,
      brunch: brunch ?? this.brunch,
      lunch: lunch ?? this.lunch,
      afternoonTea: afternoonTea ?? this.afternoonTea,
      dinner: dinner ?? this.dinner,
      supper: supper ?? this.supper,
      lateNight: lateNight ?? this.lateNight,
    );
  }

  @override
  MealTimeColorsExtension lerp(ThemeExtension<MealTimeColorsExtension>? other, double t) {
    if (other is! MealTimeColorsExtension) {
      return this;
    }

    return MealTimeColorsExtension(
      breakfast: Color.lerp(breakfast, other.breakfast, t)!,
      brunch: Color.lerp(brunch, other.brunch, t)!,
      lunch: Color.lerp(lunch, other.lunch, t)!,
      afternoonTea: Color.lerp(afternoonTea, other.afternoonTea, t)!,
      dinner: Color.lerp(dinner, other.dinner, t)!,
      supper: Color.lerp(supper, other.supper, t)!,
      lateNight: Color.lerp(lateNight, other.lateNight, t)!,
    );
  }
}

// ==============================
// SPACING EXTENSION
// ==============================

@immutable
class SpacingExtension extends ThemeExtension<SpacingExtension> {
  const SpacingExtension({
    this.xs = SpacingTokens.xs,
    this.sm = SpacingTokens.sm,
    this.md = SpacingTokens.md,
    this.lg = SpacingTokens.lg,
    this.xl = SpacingTokens.xl,
    this.xxl = SpacingTokens.xxl,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  @override
  SpacingExtension copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
  }) {
    return SpacingExtension(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
    );
  }

  @override
  SpacingExtension lerp(ThemeExtension<SpacingExtension>? other, double t) {
    if (other is! SpacingExtension) {
      return this;
    }

    return SpacingExtension(
      xs: lerpDouble(xs, other.xs, t) ?? xs,
      sm: lerpDouble(sm, other.sm, t) ?? sm,
      md: lerpDouble(md, other.md, t) ?? md,
      lg: lerpDouble(lg, other.lg, t) ?? lg,
      xl: lerpDouble(xl, other.xl, t) ?? xl,
      xxl: lerpDouble(xxl, other.xxl, t) ?? xxl,
    );
  }
}

// ==============================
// BORDER RADIUS EXTENSION
// ==============================

@immutable
class BorderRadiusExtension extends ThemeExtension<BorderRadiusExtension> {
  const BorderRadiusExtension({
    this.xs = BorderRadiusTokens.xs,
    this.sm = BorderRadiusTokens.sm,
    this.md = BorderRadiusTokens.md,
    this.lg = BorderRadiusTokens.lg,
    this.xl = BorderRadiusTokens.xl,
    this.xxl = BorderRadiusTokens.xxl,
    this.full = BorderRadiusTokens.full,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double full;

  @override
  BorderRadiusExtension copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? full,
  }) {
    return BorderRadiusExtension(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      full: full ?? this.full,
    );
  }

  @override
  BorderRadiusExtension lerp(ThemeExtension<BorderRadiusExtension>? other, double t) {
    if (other is! BorderRadiusExtension) {
      return this;
    }

    return BorderRadiusExtension(
      xs: lerpDouble(xs, other.xs, t) ?? xs,
      sm: lerpDouble(sm, other.sm, t) ?? sm,
      md: lerpDouble(md, other.md, t) ?? md,
      lg: lerpDouble(lg, other.lg, t) ?? lg,
      xl: lerpDouble(xl, other.xl, t) ?? xl,
      xxl: lerpDouble(xxl, other.xxl, t) ?? xxl,
      full: lerpDouble(full, other.full, t) ?? full,
    );
  }

  // Helper methods to get BorderRadius objects
  BorderRadius get borderRadiusXs => BorderRadius.circular(xs);
  BorderRadius get borderRadiusSm => BorderRadius.circular(sm);
  BorderRadius get borderRadiusMd => BorderRadius.circular(md);
  BorderRadius get borderRadiusLg => BorderRadius.circular(lg);
  BorderRadius get borderRadiusXl => BorderRadius.circular(xl);
  BorderRadius get borderRadiusXxl => BorderRadius.circular(xxl);
  BorderRadius get borderRadiusFull => BorderRadius.circular(full);
}

// ==============================
// SHADOW EXTENSION
// ==============================

@immutable
class ShadowExtension extends ThemeExtension<ShadowExtension> {
  const ShadowExtension({
    this.xs = ShadowTokens.shadowXs,
    this.sm = ShadowTokens.shadowSm,
    this.md = ShadowTokens.shadowMd,
    this.lg = ShadowTokens.shadowLg,
    this.xl = ShadowTokens.shadowXl,
    this.primaryShadow = ShadowTokens.primaryShadow,
    this.secondaryShadow = ShadowTokens.secondaryShadow,
  });

  final List<BoxShadow> xs;
  final List<BoxShadow> sm;
  final List<BoxShadow> md;
  final List<BoxShadow> lg;
  final List<BoxShadow> xl;
  final List<BoxShadow> primaryShadow;
  final List<BoxShadow> secondaryShadow;

  @override
  ShadowExtension copyWith({
    List<BoxShadow>? xs,
    List<BoxShadow>? sm,
    List<BoxShadow>? md,
    List<BoxShadow>? lg,
    List<BoxShadow>? xl,
    List<BoxShadow>? primaryShadow,
    List<BoxShadow>? secondaryShadow,
  }) {
    return ShadowExtension(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      primaryShadow: primaryShadow ?? this.primaryShadow,
      secondaryShadow: secondaryShadow ?? this.secondaryShadow,
    );
  }

  @override
  ShadowExtension lerp(ThemeExtension<ShadowExtension>? other, double t) {
    if (other is! ShadowExtension) {
      return this;
    }

    return ShadowExtension(
      xs: lerpBoxShadowList(xs, other.xs, t),
      sm: lerpBoxShadowList(sm, other.sm, t),
      md: lerpBoxShadowList(md, other.md, t),
      lg: lerpBoxShadowList(lg, other.lg, t),
      xl: lerpBoxShadowList(xl, other.xl, t),
      primaryShadow: lerpBoxShadowList(primaryShadow, other.primaryShadow, t),
      secondaryShadow: lerpBoxShadowList(secondaryShadow, other.secondaryShadow, t),
    );
  }

  // Helper method to lerp between lists of BoxShadows
  List<BoxShadow> lerpBoxShadowList(List<BoxShadow> a, List<BoxShadow> b, double t) {
    if (a.length != b.length) {
      return a;
    }
    return List.generate(a.length, (index) {
      final shadowA = a[index];
      final shadowB = b[index];
      return BoxShadow(
        color: Color.lerp(shadowA.color, shadowB.color, t) ?? shadowA.color,
        offset: Offset.lerp(shadowA.offset, shadowB.offset, t) ?? shadowA.offset,
        blurRadius: lerpDouble(shadowA.blurRadius, shadowB.blurRadius, t) ?? shadowA.blurRadius,
        spreadRadius: lerpDouble(shadowA.spreadRadius, shadowB.spreadRadius, t) ?? shadowA.spreadRadius,
      );
    });
  }
}

// ==============================
// THEME EXTENSION HELPERS
// ==============================

extension ThemeExtensions on ThemeData {
  // Brand colors
  BrandColorsExtension get brandColors =>
      extension<BrandColorsExtension>() ?? const BrandColorsExtension();

  // Semantic colors
  SemanticColorsExtension get semanticColors =>
      extension<SemanticColorsExtension>() ?? const SemanticColorsExtension();

  // Meal time colors
  MealTimeColorsExtension get mealTimeColors =>
      extension<MealTimeColorsExtension>() ?? const MealTimeColorsExtension();

  // Spacing
  SpacingExtension get spacing =>
      extension<SpacingExtension>() ?? const SpacingExtension();

  // Border radius
  BorderRadiusExtension get borderRadius =>
      extension<BorderRadiusExtension>() ?? const BorderRadiusExtension();

  // Shadows
  ShadowExtension get shadows =>
      extension<ShadowExtension>() ?? const ShadowExtension();
}

// Helper function for double linear interpolation
double? lerpDouble(double? a, double? b, double t) {
  if (a == null || b == null) return null;
  return a + (b - a) * t;
}