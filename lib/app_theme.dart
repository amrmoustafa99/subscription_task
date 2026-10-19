import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Theme tokens shared with the subscription flow.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFfa7215);
  static const Color primaryLight = Color(0xFFFFF0EA);

  static const Color black = Color(0xFF111111);
  static const Color darkGray = Color(0xFF333333);
  static const Color mediumGray = Color(0xFF888888);
  static const Color lightGray = Color(0xFFD8D8D8);
  static const Color ultraLightGray = Color(0xFFF5F5F5);

  static const Color white = Color(0xFFFFFFFF);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double full = 100;
}

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get displayMedium => GoogleFonts.cairo(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    letterSpacing: -0.3,
    height: 1.35,
  );

  static TextStyle get titleLarge => GoogleFonts.cairo(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    letterSpacing: -0.2,
    height: 1.45,
  );

  static TextStyle get titleMedium => GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.black,
    letterSpacing: -0.1,
    height: 1.45,
  );

  static TextStyle get bodyLarge => GoogleFonts.cairo(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGray,
    height: 1.75,
  );

  static TextStyle get bodyMedium => GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGray,
    height: 1.7,
  );

  static TextStyle get bodySmall => GoogleFonts.cairo(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.mediumGray,
    height: 1.6,
  );

  static TextStyle get caption => GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.mediumGray,
    height: 1.5,
  );

  static TextStyle get price => GoogleFonts.cairo(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle get priceLarge => GoogleFonts.cairo(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.black,
    letterSpacing: -0.4,
    height: 1.3,
  );

  static TextStyle get label => GoogleFonts.cairo(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.darkGray,
    height: 1.4,
  );

  static TextStyle get labelSmall => GoogleFonts.cairo(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.mediumGray,
    height: 1.3,
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    fontFamily: GoogleFonts.cairo().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.black),
      titleTextStyle: AppTextStyles.titleMedium,
    ),
  );
}
