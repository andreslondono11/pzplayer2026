import 'package:flutter/material.dart';

class AppColors {
  // 🎨 Paleta principal en tonos rojos
  static const Color primary = Color(0xFFE53935); // rojo intenso
  static const Color secondary = Color(0xFFB71C1C); // rojo oscuro profundo
  static const Color accent = Color(0xFFEF5350); // rojo claro/acento
  static const Color background = Color(0xFFF5F5F5); // fondo claro neutro

  // 🖋️ Texto
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color white = Colors.white;

  // 🔥 Gradientes
  static const LinearGradient redGradientLight = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradientDark = LinearGradient(
    colors: [secondary, Color(0xFF7F0000)], // rojo muy oscuro, no negro
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // 🌑 Sombras y overlays
  static const BoxShadow softShadow = BoxShadow(
    color: Colors.black26,
    blurRadius: 12,
    offset: Offset(0, 6),
  );

  static const BoxShadow strongShadow = BoxShadow(
    color: Colors.black45,
    blurRadius: 20,
    offset: Offset(0, 10),
  );
}
