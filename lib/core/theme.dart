import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF4DB6AC); // Verde Água
  static const Color secondaryColor = Color(0xFFFFB74D); // Laranja claro
  static const Color backgroundColor = Color(0xFFF5F7FA); // Fundo claro
  static const Color successColor = Color(0xFF81C784); // Verde sucesso
  static const Color errorColor = Color(0xFFE57373); // Vermelho erro
  static const Color textColor = Color(0xFF37474F); // Texto escuro
  
  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    fontFamily: 'Nunito', // Assumindo Nunito, se tiver fonte. Faremos fallback para default
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: textColor),
      displayMedium: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textColor),
      bodyLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        minimumSize: const Size(72, 72),
      ),
    ),
  );
}
