import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: AppTextStyles.headingLight,
        // 🔥 Gradiente rojo más oscuro en claro
        // flexibleSpace: Container(
        //   decoration: const BoxDecoration(
        //     gradient: AppColors.redGradientLight,
        //   ),
        // ),
      ),
      textTheme: const TextTheme(
        titleLarge: AppTextStyles.headingLight,
        titleMedium: AppTextStyles.subheadingLight,
        bodyLarge: AppTextStyles.bodyLight,
        bodyMedium: AppTextStyles.captionLight,
        labelLarge: AppTextStyles.button,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.background,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.black, // 🔑 negro puro
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        titleTextStyle: AppTextStyles.headingDark,
      ),
      textTheme: TextTheme(
        titleLarge: AppTextStyles.headingDark,
        titleMedium: AppTextStyles.subheadingDark,
        bodyLarge: AppTextStyles.bodyDark,
        bodyMedium: AppTextStyles.captionDark,
        labelLarge: AppTextStyles.button,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Colors.black,
        secondary: AppColors.accent,
        surface: Colors.black,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
      ),
    );
  }
}
