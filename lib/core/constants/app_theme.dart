import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._privateConstructor();

  static final AppTheme instance = AppTheme._privateConstructor();

  ThemeData get lightTheme {
    return ThemeData(
      // Set your custom font as the default for the entire app
      fontFamily: 'ChelseaMarket-Regular',

      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundWhite,

      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryPurple,
        primary: AppColors.primaryPurple,
        secondary: AppColors.accentOrange,
        surface: AppColors.backgroundWhite,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentOrange,
        foregroundColor: AppColors.white,
      ),
    );
  }
}