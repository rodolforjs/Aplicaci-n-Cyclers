import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamilyData = 'DM Mono';
  static const String fontFamilyText = 'DM Sans';
  // HEADLINE
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 56,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.5,
    height: 1.07,
  );
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 44,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.84,
    height: 1.09,
  );
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 36,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.69,
    height: 1.22,
  );
  static const TextStyle h4 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.19,
  );
  static const TextStyle h5 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.23,
  );
  static const TextStyle h6 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );
  // SUBTITLE
  static const TextStyle subtitle1 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.72,
    height: 1.33,
  );
  static const TextStyle subtitle2 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.38,
  );
  // BODY
  static const TextStyle body1 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  static const TextStyle body2 = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.5,
  );
  // BUTTON
  static const TextStyle button = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
    height: 1.25,
  );
  // CHIP
  static const TextStyle chip = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
    height: 1.29,
  );
  // CAPTION
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    height: 1.33,
  );
  // OVERLINE
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamilyText,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    height: 1.33,
  );
  // DATA
  static const TextStyle data1 = TextStyle(
    fontFamily: fontFamilyData,
    fontSize: 40,
    fontWeight: FontWeight.w500,
    letterSpacing: -1.5,
    height: 1.1,
  );
  static const TextStyle data2 = TextStyle(
    fontFamily: fontFamilyData,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.5,
    height: 1.14,
  );
  static const TextStyle data3 = TextStyle(
    fontFamily: fontFamilyData,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.25,
  );
}

// MÉTRICAS

class AppSpacing {
  static const double space050 = 2;
  static const double space100 = 4;
  static const double space200 = 8;
  static const double space300 = 12;
  static const double space400 = 16;
  static const double space500 = 20;
  static const double space600 = 24;
  static const double space700 = 32;
  static const double space800 = 40;
  static const double space900 = 48;
  static const double space1000 = 56;
  static const double space1100 = 64;
  static const double space1200 = 72;
}

class AppPadding {
  static const double xs = AppSpacing.space100;
  static const double sm = AppSpacing.space200;
  static const double md = AppSpacing.space400;
  static const double lg = AppSpacing.space600;
  static const double xl = AppSpacing.space900;
}

class AppMargin {
  static const double xs = AppSpacing.space100;
  static const double sm = AppSpacing.space200;
  static const double md = AppSpacing.space400;
  static const double lg = AppSpacing.space600;
  static const double xl = AppSpacing.space900;
}

class AppGap {
  static const double tight = AppSpacing.space100;
  static const double related = AppSpacing.space200;
  static const double component = AppSpacing.space400;
  static const double group = AppSpacing.space500;
  static const double section = AppSpacing.space700;
  static const double nav = AppSpacing.space800;
  static const double container = AppSpacing.space900;
}

class AppRadius {
  static const double sm = AppSpacing.space100;
  static const double md = AppSpacing.space200;
  static const double lg = AppSpacing.space300;
  static const double xl = AppSpacing.space400;
  static const double full = AppSpacing.space1200;
}

// COLORES

class AppColors {
  // BRAND
  static const Color brand50 = Color(0xFFF0F2E8);
  static const Color brand100 = Color(0xFFD5DAB8);
  static const Color brand200 = Color(0xFFBAC28A);
  static const Color brand300 = Color(0xFF9EAA5D);
  static const Color brand400 = Color(0xFF7D8E3A);
  static const Color brand500 = Color(0xFF5E6D28); // BASE
  static const Color brand600 = Color(0xFF40481F);
  static const Color brand700 = Color(0xFF2E3416);
  static const Color brand800 = Color(0xFF1E220E);
  static const Color brand900 = Color(0xFF101208);

  // SECONDARY
  static const Color secondary50 = Color(0xFFFAF7F2);
  static const Color secondary100 = Color(0xFFF5EEE0);
  static const Color secondary200 = Color(0xFFEDE0C6);
  static const Color secondary300 = Color(0xFFE3D2B4);
  static const Color secondary400 = Color(0xFFD4BC94);
  static const Color secondary500 = Color(0xFFBFA070); // BASE
  static const Color secondary600 = Color(0xFFA07E4E);
  static const Color secondary700 = Color(0xFF7A5E35);
  static const Color secondary800 = Color(0xFF523E22);
  static const Color secondary900 = Color(0xFF2C2010);

  // NEUTRAL
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF2F3F5);
  static const Color neutral100 = Color(0xFFE2E4E8);
  static const Color neutral200 = Color(0xFFC8CCD4);
  static const Color neutral300 = Color(0xFFA8ADB8);
  static const Color neutral400 = Color(0xFF848A96);
  static const Color neutral500 = Color(0xFF606672); // BASE
  static const Color neutral600 = Color(0xFF404550);
  static const Color neutral700 = Color(0xFF2A2E36);
  static const Color neutral800 = Color(0xFF151516);
  static const Color neutral900 = Color(0xFF0A0A0B);
  static const Color neutral1000 = Color(0xFF000000);

  // ACCENT
  static const Color accent50 = Color(0xFFFFF2EA);
  static const Color accent100 = Color(0xFFFFD9BC);
  static const Color accent200 = Color(0xFFFFBC8C);
  static const Color accent300 = Color(0xFFFF9A5C);
  static const Color accent400 = Color(0xFFFF7A30);
  static const Color accent500 = Color(0xFFFF6400); // BASE
  static const Color accent600 = Color(0xFFCC5000);
  static const Color accent700 = Color(0xFF993C00);
  static const Color accent800 = Color(0xFF662800);
  static const Color accent900 = Color(0xFF331400);

  // PREMIUM
  static const Color premium50 = Color(0xFFF0ECFB);
  static const Color premium200 = Color(0xFFC4AEF0);
  static const Color premium500 = Color(0xFF7C3AED); // BASE
  static const Color premium600 = Color(0xFF5B21B6);
  static const Color premium800 = Color(0xFF2E1065);

  // SUCCESS
  static const Color success50 = Color(0xFFDCFCE7);
  static const Color success200 = Color(0xFF86EFAC);
  static const Color success500 = Color(0xFF16A34A); // BASE
  static const Color success600 = Color(0xFF15803D);
  static const Color success800 = Color(0xFF14532D);

  // WARNING
  static const Color warning50 = Color(0xFFFEF9C3);
  static const Color warning200 = Color(0xFFFDE047);
  static const Color warning500 = Color(0xFFCA8A04); // BASE
  static const Color warning600 = Color(0xFFA16207);
  static const Color warning800 = Color(0xFF713F12);

  // ERROR
  static const Color error50 = Color(0xFFFEE2E2);
  static const Color error200 = Color(0xFFFCA5A5);
  static const Color error500 = Color(0xFFDC2626); // BASE
  static const Color error600 = Color(0xFFB91C1C);
  static const Color error800 = Color(0xFF7F1D1D);
}

// COLORES DE FEEDBACK
// (M3 solo trae "error"; success y warning se definen aparte, igual que en la clase)

class AppFeedbackColors {
  // success
  static const Color success = AppColors.success500;
  static const Color onSuccess = AppColors.success50; // Figma: text-on-success
  static const Color successContainer = AppColors.success50;
  static const Color onSuccessContainer = AppColors.success800;

  // warning
  static const Color warning = AppColors.warning500;
  static const Color onWarning = AppColors.warning50; // Figma: text-on-warning
  static const Color warningContainer = AppColors.warning50;
  static const Color onWarningContainer = AppColors.warning800;
}

// COLORES PREMIUM

class AppPremiumColors {
  static const Color premium = AppColors.premium500;
  static const Color onPremium = AppColors.neutral0; // Figma: text-on-premium
  static const Color premiumContainer = AppColors.premium50;
  static const Color onPremiumContainer = AppColors.premium800;
}

// SOMBRAS
class AppShadows {
  static const List<BoxShadow> elevation1 = [
    BoxShadow(color: Color(0x140A0A0B), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const List<BoxShadow> elevation2 = [
    BoxShadow(color: Color(0x1F0A0A0B), offset: Offset(0, 2), blurRadius: 8),
  ];
  static const List<BoxShadow> elevation3 = [
    BoxShadow(color: Color(0x290A0A0B), offset: Offset(0, 8), blurRadius: 24),
  ];
}

// MATERIAL TEXT THEME
const TextTheme appTextTheme = TextTheme(
  displayLarge: AppTypography.h1,
  displayMedium: AppTypography.h2,
  displaySmall: AppTypography.h3,

  headlineLarge: AppTypography.h4,
  headlineMedium: AppTypography.h5,
  headlineSmall: AppTypography.h6,

  titleLarge: AppTypography.subtitle1,
  titleMedium: AppTypography.subtitle2,
  titleSmall: AppTypography.subtitle2, // no lo usamos nosotros

  bodyLarge: AppTypography.body1,
  bodyMedium: AppTypography.body2,
  bodySmall: AppTypography.caption,

  labelLarge: AppTypography.button,
  labelMedium: AppTypography.chip,
  labelSmall: AppTypography.overline,
);

// COLOR SCHEME

const ColorScheme appColorScheme = ColorScheme.light(
  // primary
  primary: AppColors.brand500,
  onPrimary: AppColors.neutral0,
  primaryContainer: AppColors.brand100,
  onPrimaryContainer: AppColors.brand700,

  // secondary
  secondary: AppColors.secondary500,
  onSecondary: AppColors.secondary900,
  secondaryContainer: AppColors.secondary100,
  onSecondaryContainer: AppColors.secondary900,

  // tertiary (accent)
  tertiary: AppColors.accent500,
  onTertiary: AppColors.neutral0,
  tertiaryContainer: AppColors.accent100,
  onTertiaryContainer: AppColors.accent800,

  // surface
  surface: AppColors.secondary50,
  onSurface: AppColors.neutral800,
  surfaceContainer: AppColors.secondary100,
  surfaceContainerLowest: AppColors.neutral0, // tarjetas y paneles blancos
  surfaceContainerHighest: AppColors.neutral300, // manijas de paneles
  onSurfaceVariant: AppColors.neutral500,

  // outline
  outline: AppColors.neutral400,
  outlineVariant: AppColors.neutral200,

  // error
  error: AppColors.error500,
  onError: AppColors.error50,
  errorContainer: AppColors.error50,
  onErrorContainer: AppColors.error800,
);

// COMPONENT THEMES

final NavigationBarThemeData appNavigationBarTheme = NavigationBarThemeData(
  height: 64,
  backgroundColor: AppColors.neutral0,
  surfaceTintColor: Colors.transparent,
  elevation: 0,
  indicatorColor: Colors.transparent,
  labelTextStyle: WidgetStateProperty.all(
    AppTypography.body2.copyWith(color: AppColors.neutral700),
  ),
  iconTheme: WidgetStateProperty.resolveWith((states) {
    final selected = states.contains(WidgetState.selected);
    return IconThemeData(
      size: 24,
      color: selected ? AppColors.brand500 : AppColors.neutral500,
    );
  }),
);

// botón principal (navegación): circular, brand
const FloatingActionButtonThemeData appFabTheme = FloatingActionButtonThemeData(
  backgroundColor: AppColors.brand500,
  foregroundColor: AppColors.neutral0,
  elevation: 2,
  shape: CircleBorder(),
);

final FilledButtonThemeData appFilledButtonTheme = FilledButtonThemeData(
  style: FilledButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: AppPadding.md,
      vertical: AppPadding.sm,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  ),
);

// botón con borde: mismas medidas que el relleno para que se alineen
final OutlinedButtonThemeData appOutlinedButtonTheme = OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: AppPadding.md,
      vertical: AppPadding.sm,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  ),
);

final ChipThemeData appChipTheme = ChipThemeData(
  backgroundColor: AppColors.neutral0,
  selectedColor: AppColors.brand100,
  checkmarkColor: AppColors.brand700,
  side: const BorderSide(color: AppColors.neutral200),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
);

// APP THEME
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  fontFamily: AppTypography.fontFamilyText,
  colorScheme: appColorScheme,
  textTheme: appTextTheme,
  navigationBarTheme: appNavigationBarTheme,
  floatingActionButtonTheme: appFabTheme,
  filledButtonTheme: appFilledButtonTheme,
  outlinedButtonTheme: appOutlinedButtonTheme,
  chipTheme: appChipTheme,
);
