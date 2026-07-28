import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';

/// Global ThemeData: strict minimalism, sharp edges, locale-aware typography.
class AppTheme {
  AppTheme._();

  static ThemeData themeFor(String languageCode) {
    final bool isArabic = languageCode == 'ar';

    final TextTheme baseTextTheme = isArabic
        ? GoogleFonts.tajawalTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme);

    final TextTheme textTheme = baseTextTheme.apply(
      bodyColor: AppColors.white,
      displayColor: AppColors.white,
      decorationColor: AppColors.white,
    );

    const BorderRadius sharpRadius = BorderRadius.all(Radius.circular(2));
    const OutlineInputBorder inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.gray),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: isArabic
          ? GoogleFonts.tajawal().fontFamily
          : GoogleFonts.orbitron().fontFamily,
      scaffoldBackgroundColor: AppColors.black,
      canvasColor: AppColors.black,
      primaryColor: AppColors.red,
      disabledColor: AppColors.gray,
      dividerColor: AppColors.gray,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.blackAlt,
        primary: AppColors.red,
        secondary: AppColors.gray,
        onSurface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        error: AppColors.red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.red,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray,
          disabledForegroundColor: AppColors.white,
          shape: const RoundedRectangleBorder(borderRadius: sharpRadius),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.white,
          shape: const RoundedRectangleBorder(borderRadius: sharpRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: const BorderSide(color: AppColors.white),
          shape: const RoundedRectangleBorder(borderRadius: sharpRadius),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder,
        disabledBorder: inputBorder,
        hintStyle: TextStyle(color: AppColors.whiteMuted),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.blackAlt,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: sharpRadius),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.blackAlt,
        shape: RoundedRectangleBorder(borderRadius: sharpRadius),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.gray,
        contentTextStyle: TextStyle(color: AppColors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}
