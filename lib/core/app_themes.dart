import 'package:flutter/material.dart';

/// Os dois temas visuais disponíveis no app.
enum AppThemeMode { princess, cars }

/// Tokens visuais por tema (cores, ícones, textos de UI).
class AppThemeTokens {
  final AppThemeMode mode;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color onPrimary;
  final Color accent;
  final String familyIcon;   // emoji decorativo no header do menu
  final String gameIcon;     // emoji decorativo no header do jogo
  final String themeLabel;
  final String themeEmoji;

  const AppThemeTokens({
    required this.mode,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.onPrimary,
    required this.accent,
    required this.familyIcon,
    required this.gameIcon,
    required this.themeLabel,
    required this.themeEmoji,
  });
}

/// Tokens para o tema Princesa.
const AppThemeTokens princessTokens = AppThemeTokens(
  mode: AppThemeMode.princess,
  primary: Color(0xFF9C27B0),   // roxo
  secondary: Color(0xFFE91E63), // rosa
  background: Color(0xFFFCE4EC),
  surface: Color(0xFFF8BBD9),
  onPrimary: Colors.white,
  accent: Color(0xFFFFD54F),    // dourado
  familyIcon: '👑',
  gameIcon: '⭐',
  themeLabel: 'Princesa',
  themeEmoji: '👑',
);

/// Tokens para o tema Carros.
const AppThemeTokens carsTokens = AppThemeTokens(
  mode: AppThemeMode.cars,
  primary: Color(0xFF1976D2),   // azul
  secondary: Color(0xFF388E3C), // verde
  background: Color(0xFFE3F2FD),
  surface: Color(0xFFBBDEFB),
  onPrimary: Colors.white,
  accent: Color(0xFFFFB300),    // amarelo
  familyIcon: '🏎️',
  gameIcon: '🚀',
  themeLabel: 'Carros',
  themeEmoji: '🏎️',
);

/// Retorna os tokens para um dado [AppThemeMode].
AppThemeTokens tokensFor(AppThemeMode mode) =>
    mode == AppThemeMode.princess ? princessTokens : carsTokens;

/// Constrói um [ThemeData] Material 3 para o tema escolhido.
ThemeData buildThemeData(AppThemeMode mode) {
  final tokens = tokensFor(mode);
  final scheme = ColorScheme.fromSeed(
    seedColor: tokens.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: tokens.primary,
    secondary: tokens.secondary,
    surface: tokens.surface,
    tertiary: tokens.accent,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Nunito',
    colorScheme: scheme,
    scaffoldBackgroundColor: tokens.background,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: tokens.primary,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tokens.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(72, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: tokens.surface,
      selectedColor: tokens.primary,
      labelStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: tokens.primary,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: tokens.primary,
      ),
      bodyLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
    ),
  );
}
