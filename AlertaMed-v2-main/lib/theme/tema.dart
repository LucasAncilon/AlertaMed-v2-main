import 'package:flutter/material.dart';
import 'cores.dart';

ThemeData buildTema() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppCores.primaria,
    brightness: Brightness.light,
    primary: AppCores.primaria,
    onPrimary: Colors.white,
    surface: AppCores.superficie,
    error: AppCores.erro,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppCores.fundo,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppCores.primaria,
      foregroundColor: Colors.white,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppCores.textoPrimario),
      titleLarge:   TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppCores.textoPrimario),
      titleMedium:  TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppCores.textoPrimario),
      bodyLarge:    TextStyle(fontSize: 18, color: AppCores.textoPrimario),
      bodyMedium:   TextStyle(fontSize: 16, color: AppCores.textoSecundario),
      labelLarge:   TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppCores.primaria,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppCores.primaria,
      foregroundColor: Colors.white,
      extendedTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      labelStyle: const TextStyle(fontSize: 18, color: AppCores.textoSecundario),
      hintStyle: const TextStyle(fontSize: 16, color: AppCores.textoSecundario),
    ),

    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppCores.superficie,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    snackBarTheme: const SnackBarThemeData(
      contentTextStyle: TextStyle(fontSize: 16),
    ),
  );
}
