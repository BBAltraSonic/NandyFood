import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_tokens.dart';
import 'theme_extensions.dart';

class AppTheme {
  // Legacy color constants (for backward compatibility)
  static const Color oliveGreen = BrandColors.primary;
  static const Color sageBackground = NeutralColors.background;
  static const Color textPrimary = NeutralColors.textPrimary;
  static const Color textSecondary = NeutralColors.textSecondary;
  static const Color warmCream = NeutralColors.warmCream;
  static const Color mutedGreen = BrandColors.accent;
  static const Color cardWhite = NeutralColors.surface;
  static const Color cookingStatus = SemanticColors.warning;
  static const Color finishedStatus = SemanticColors.success;

  // Meal time colors (legacy)
  static const Color breakfastColor = MealTimeColors.breakfast;
  static const Color lunchColor = MealTimeColors.lunch;
  static const Color supperColor = MealTimeColors.supper;
  static const Color dinnerColor = MealTimeColors.dinner;

  static ThemeData get lightTheme {
    return _buildThemeData(
      brightness: Brightness.light,
      colorScheme: _buildLightColorScheme(),
    );
  }

  static ThemeData get darkTheme {
    return _buildThemeData(
      brightness: Brightness.dark,
      colorScheme: _buildDarkColorScheme(),
    );
  }

  static ThemeData _buildThemeData({
    required Brightness brightness,
    required ColorScheme colorScheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: TypographyTokens.fontFamilyPrimary,
      textTheme: _buildTextTheme(brightness),
      appBarTheme: _buildAppBarTheme(brightness),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      textButtonTheme: _buildTextButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      cardTheme: _buildCardTheme(),
      chipTheme: _buildChipTheme(),
      bottomNavigationBarTheme: _buildBottomNavigationBarTheme(),
      floatingActionButtonTheme: _buildFloatingActionButtonTheme(),
      dividerTheme: _buildDividerTheme(),
      switchTheme: _buildSwitchTheme(),
      checkboxTheme: _buildCheckboxTheme(),
      radioTheme: _buildRadioTheme(),
      sliderTheme: _buildSliderTheme(),
      progressIndicatorTheme: _buildProgressIndicatorTheme(),
      snackBarTheme: _buildSnackBarTheme(),
      dialogTheme: _buildDialogTheme(),
      bottomSheetTheme: _buildBottomSheetTheme(),
      pageTransitionsTheme: _buildPageTransitionsTheme(),
      // Theme extensions
      extensions: [
        const BrandColorsExtension(),
        const SemanticColorsExtension(),
        const MealTimeColorsExtension(),
        const SpacingExtension(),
        const BorderRadiusExtension(),
        ShadowExtension(
        xs: ShadowTokens.shadowXs,
        sm: ShadowTokens.shadowSm,
        md: ShadowTokens.shadowMd,
        lg: ShadowTokens.shadowLg,
        xl: ShadowTokens.shadowXl,
        primaryShadow: ShadowTokens.primaryShadow,
        secondaryShadow: ShadowTokens.secondaryShadow,
      ),
      ],
    );
  }

  // ==============================
  // COLOR SCHEMES
  // ==============================

  static ColorScheme _buildLightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: BrandColors.primary,
      brightness: Brightness.light,
      primary: BrandColors.primary,
      onPrimary: NeutralColors.textOnPrimary,
      secondary: BrandColors.secondary,
      onSecondary: NeutralColors.textOnPrimary,
      surface: NeutralColors.surface,
      onSurface: NeutralColors.textPrimary,
      surfaceContainer: NeutralColors.background,
      error: SemanticColors.error,
      onError: NeutralColors.textOnPrimary,
    );
  }

  static ColorScheme _buildDarkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: BrandColors.primary,
      brightness: Brightness.dark,
      primary: BrandColors.primaryLight,
      onPrimary: NeutralColors.textPrimary,
      secondary: BrandColors.secondaryLight,
      onSecondary: NeutralColors.textPrimary,
      surface: NeutralColors.gray800,
      onSurface: NeutralColors.textTertiary,
      surfaceContainer: NeutralColors.gray900,
      error: SemanticColors.errorLight,
      onError: NeutralColors.textPrimary,
    );
  }

  // ==============================
  // TEXT THEMES
  // ==============================

  static TextTheme _buildTextTheme(Brightness brightness) {
    final textColor = brightness == Brightness.light
        ? NeutralColors.textPrimary
        : NeutralColors.textTertiary;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: TypographyTokens.fontSize4xl,
        fontWeight: TypographyTokens.fontWeightBold,
        height: TypographyTokens.lineHeightSm,
        letterSpacing: TypographyTokens.letterSpacingSm,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: TypographyTokens.fontSize3xl,
        fontWeight: TypographyTokens.fontWeightBold,
        height: TypographyTokens.lineHeightSm,
        letterSpacing: TypographyTokens.letterSpacingSm,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: TypographyTokens.fontSize2xl,
        fontWeight: TypographyTokens.fontWeightBold,
        height: TypographyTokens.lineHeightXs,
        letterSpacing: TypographyTokens.letterSpacingSm,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: TypographyTokens.fontSize2xl,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeightXs,
        letterSpacing: TypographyTokens.letterSpacingXs,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: TypographyTokens.fontSizeXl,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeightXs,
        letterSpacing: TypographyTokens.letterSpacingXs,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: TypographyTokens.fontSizeLg,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeightBase,
        letterSpacing: TypographyTokens.letterSpacingBase,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: TypographyTokens.fontSizeBase,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeightBase,
        letterSpacing: TypographyTokens.letterSpacingBase,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: TypographyTokens.fontSizeSm,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeightBase,
        letterSpacing: TypographyTokens.letterSpacingBase,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: TypographyTokens.fontSizeXs,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeightBase,
        letterSpacing: TypographyTokens.letterSpacingBase,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: TypographyTokens.fontSizeBase,
        fontWeight: TypographyTokens.fontWeightRegular,
        height: TypographyTokens.lineHeightBase,
        letterSpacing: TypographyTokens.letterSpacingBase,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: TypographyTokens.fontSizeSm,
        fontWeight: TypographyTokens.fontWeightRegular,
        height: TypographyTokens.lineHeightBase,
        letterSpacing: TypographyTokens.letterSpacingBase,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: TypographyTokens.fontSizeXs,
        fontWeight: TypographyTokens.fontWeightRegular,
        height: TypographyTokens.lineHeightSm,
        letterSpacing: TypographyTokens.letterSpacingBase,
        color: textColor,
      ),
      labelLarge: TextStyle(
        fontSize: TypographyTokens.fontSizeSm,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeightBase,
        letterSpacing: TypographyTokens.letterSpacingLg,
        color: textColor,
      ),
      labelMedium: TextStyle(
        fontSize: TypographyTokens.fontSizeXs,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeightBase,
        letterSpacing: TypographyTokens.letterSpacingLg,
        color: textColor,
      ),
      labelSmall: TextStyle(
        fontSize: TypographyTokens.fontSizeXxs,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        height: TypographyTokens.lineHeightSm,
        letterSpacing: TypographyTokens.letterSpacingLg,
        color: textColor,
      ),
    );
  }

  // ==============================
  // COMPONENT THEMES
  // ==============================

  static AppBarTheme _buildAppBarTheme(Brightness brightness) {
    final textColor = brightness == Brightness.light
        ? NeutralColors.textOnPrimary
        : NeutralColors.textPrimary;

    return AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 4,
      surfaceTintColor: BrandColors.primary,
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontSize: TypographyTokens.fontSizeXl,
        fontWeight: TypographyTokens.fontWeightSemiBold,
        color: textColor,
      ),
      iconTheme: IconThemeData(
        color: textColor,
        size: 24,
      ),
      actionsIconTheme: IconThemeData(
        color: textColor,
        size: 24,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: NeutralColors.textOnPrimary,
        backgroundColor: BrandColors.primary,
        elevation: 3,
        shadowColor: BrandColors.primary.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BorderRadiusTokens.xl)),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.spacing6,
          vertical: SpacingTokens.spacing3,
        ),
        textStyle: TextStyle(
          fontSize: TypographyTokens.fontSizeBase,
          fontWeight: TypographyTokens.fontWeightSemiBold,
          letterSpacing: TypographyTokens.letterSpacingLg,
        ),
        minimumSize: const Size(0, 48),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BrandColors.primary,
        side: const BorderSide(color: BrandColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BorderRadiusTokens.xl)),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.spacing6,
          vertical: SpacingTokens.spacing3,
        ),
        textStyle: TextStyle(
          fontSize: TypographyTokens.fontSizeBase,
          fontWeight: TypographyTokens.fontWeightSemiBold,
          letterSpacing: TypographyTokens.letterSpacingLg,
        ),
        minimumSize: const Size(0, 48),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BrandColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BorderRadiusTokens.xl)),
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.spacing4,
          vertical: SpacingTokens.spacing2,
        ),
        textStyle: TextStyle(
          fontSize: TypographyTokens.fontSizeBase,
          fontWeight: TypographyTokens.fontWeightSemiBold,
          letterSpacing: TypographyTokens.letterSpacingLg,
        ),
        minimumSize: const Size(0, 40),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: NeutralColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        borderSide: BorderSide(color: NeutralColors.gray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        borderSide: BorderSide(color: NeutralColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        borderSide: BorderSide(color: BrandColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        borderSide: BorderSide(color: SemanticColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        borderSide: BorderSide(color: SemanticColors.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        borderSide: BorderSide(color: NeutralColors.gray200),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.spacing4,
        vertical: SpacingTokens.spacing3,
      ),
      hintStyle: TextStyle(
        color: NeutralColors.textSecondary,
        fontSize: TypographyTokens.fontSizeBase,
      ),
      labelStyle: TextStyle(
        color: BrandColors.primary,
        fontSize: TypographyTokens.fontSizeSm,
        fontWeight: TypographyTokens.fontWeightMedium,
      ),
      errorStyle: TextStyle(
        color: SemanticColors.error,
        fontSize: TypographyTokens.fontSizeXs,
        fontWeight: TypographyTokens.fontWeightMedium,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      elevation: 4,
      shadowColor: ShadowTokens.shadowMd.first.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BorderRadiusTokens.xl)),
      color: NeutralColors.surface,
      margin: const EdgeInsets.all(SpacingTokens.spacing2),
    );
  }

  static ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      backgroundColor: NeutralColors.gray100,
      selectedColor: BrandColors.primary.withValues(alpha: 0.2),
      disabledColor: NeutralColors.gray50,
      labelStyle: TextStyle(
        color: NeutralColors.textPrimary,
        fontSize: TypographyTokens.fontSizeSm,
        fontWeight: TypographyTokens.fontWeightMedium,
      ),
      secondaryLabelStyle: TextStyle(
        color: BrandColors.primary,
        fontSize: TypographyTokens.fontSizeSm,
        fontWeight: TypographyTokens.fontWeightSemiBold,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.spacing3,
        vertical: SpacingTokens.spacing1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
      ),
    );
  }

  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme() {
    return BottomNavigationBarThemeData(
      backgroundColor: NeutralColors.surface,
      selectedItemColor: BrandColors.primary,
      unselectedItemColor: NeutralColors.textSecondary,
      selectedLabelStyle: TextStyle(
        fontSize: TypographyTokens.fontSizeXs,
        fontWeight: TypographyTokens.fontWeightSemiBold,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: TypographyTokens.fontSizeXs,
        fontWeight: TypographyTokens.fontWeightRegular,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      enableFeedback: true,
    );
  }

  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme() {
    return FloatingActionButtonThemeData(
      backgroundColor: BrandColors.primary,
      foregroundColor: NeutralColors.textOnPrimary,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BorderRadiusTokens.xl)),
      iconSize: 24,
    );
  }

  static DividerThemeData _buildDividerTheme() {
    return DividerThemeData(
      color: NeutralColors.gray200,
      thickness: 1,
      space: SpacingTokens.spacing2,
    );
  }

  static SwitchThemeData _buildSwitchTheme() {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BrandColors.primary;
        }
        return NeutralColors.gray400;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BrandColors.primary.withValues(alpha: 0.5);
        }
        return NeutralColors.gray300;
      }),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static CheckboxThemeData _buildCheckboxTheme() {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BrandColors.primary;
        }
        return NeutralColors.gray400;
      }),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BorderRadiusTokens.xs)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static RadioThemeData _buildRadioTheme() {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return BrandColors.primary;
        }
        return NeutralColors.gray400;
      }),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static SliderThemeData _buildSliderTheme() {
    return SliderThemeData(
      activeTrackColor: BrandColors.primary,
      inactiveTrackColor: BrandColors.primary.withValues(alpha: 0.3),
      thumbColor: BrandColors.primary,
      overlayColor: BrandColors.primary.withValues(alpha: 0.2),
      valueIndicatorColor: BrandColors.primary,
      valueIndicatorTextStyle: TextStyle(
        color: NeutralColors.textOnPrimary,
        fontSize: TypographyTokens.fontSizeSm,
        fontWeight: TypographyTokens.fontWeightSemiBold,
      ),
    );
  }

  static ProgressIndicatorThemeData _buildProgressIndicatorTheme() {
    return ProgressIndicatorThemeData(
      color: BrandColors.primary,
      linearTrackColor: BrandColors.primary.withValues(alpha: 0.2),
      circularTrackColor: BrandColors.primary.withValues(alpha: 0.2),
      refreshBackgroundColor: NeutralColors.surface,
    );
  }

  static SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      backgroundColor: NeutralColors.gray800,
      contentTextStyle: TextStyle(
        color: NeutralColors.textOnPrimary,
        fontSize: TypographyTokens.fontSizeBase,
        fontWeight: TypographyTokens.fontWeightRegular,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BorderRadiusTokens.lg)),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      insetPadding: const EdgeInsets.all(SpacingTokens.spacing4),
    );
  }

  static DialogThemeData _buildDialogTheme() {
    return DialogThemeData(
      backgroundColor: NeutralColors.surface,
      elevation: 8,
      shadowColor: ShadowTokens.shadowLg.first.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BorderRadiusTokens.xl)),
      titleTextStyle: TextStyle(
        color: NeutralColors.textPrimary,
        fontSize: TypographyTokens.fontSizeXl,
        fontWeight: TypographyTokens.fontWeightSemiBold,
      ),
      contentTextStyle: TextStyle(
        color: NeutralColors.textPrimary,
        fontSize: TypographyTokens.fontSizeBase,
        fontWeight: TypographyTokens.fontWeightRegular,
      ),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme() {
    return BottomSheetThemeData(
      backgroundColor: NeutralColors.surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(BorderRadiusTokens.xxl),
          topRight: Radius.circular(BorderRadiusTokens.xxl),
        ),
      ),
      clipBehavior: Clip.antiAlias,
    );
  }

  static PageTransitionsTheme _buildPageTransitionsTheme() {
    return PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      },
    );
  }
}
