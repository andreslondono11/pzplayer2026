import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // 🌞 Tema claro
  static const TextStyle headingLight = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle subheadingLight = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle bodyLight = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  static const TextStyle darkti = TextStyle(
    fontSize: 22,
    color: AppColors.accent,
  );

  static const TextStyle darkto = TextStyle(
    fontSize: 22,

    color: Colors.blueGrey,
  );

  //numero de canciones album
  static const TextStyle darktof = TextStyle(
    fontSize: 16,

    color: Colors.blueGrey,
  );

  static const TextStyle darktoif = TextStyle(
    fontSize: 16,

    color: AppColors.primary,
  );

  //album titulo cancion

  static const TextStyle darktoi = TextStyle(
    fontSize: 12,

    color: Colors.blueGrey,
  );

  static const TextStyle darktoa = TextStyle(
    fontSize: 12,

    color: AppColors.primary,
  );

  //otro
  static const TextStyle captionLight = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // 🌑 Tema oscuro
  static const TextStyle headingDark = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.blueGrey,
  );

  static const TextStyle subheadingDark = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.blueGrey,
  );

  static const TextStyle bodyDark = TextStyle(
    fontSize: 16,
    color: AppColors.white,
  );

  static const TextStyle captionDark = TextStyle(
    fontSize: 14,
    color: Colors.white70,
  );

  // 🔘 Botones
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    letterSpacing: 1.2,
  );

  static const TextStyle button2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black,
    letterSpacing: 1.2,
  );

  // 🏷️ Overlay
  static const TextStyle overlay = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.accent,
  );
}
