import 'package:flutter/material.dart';

/// Configuración centralizada de tema y estilos de la interfaz de Autösen.
/// Mantiene una estética minimalista monocromática (negro, blanco, gris neutro)
/// y proporciona decoraciones a prueba de errores visuales.
class AppTheme {
  static const Color background = Color(0xFFF4F4F5);
  static const Color surface = Colors.white;
  static const Color primary = Colors.black;
  static const Color onPrimary = Colors.white;
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textMuted = Colors.black38;
  static const Color border = Color(0xFFE4E4E7);
  static const Color inputFill = Color(0xFFF8F9FA);

  // Colores de estado (semáforo controlado)
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        onPrimary: onPrimary,
        surface: surface,
        onSurface: primary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: onPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: onPrimary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
    );
  }

  /// Sombra suave corporativa
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ];

  /// Decoración estándar para campos de entrada de datos protegidos
  static InputDecoration inputDecoration(
    String hint, {
    IconData? icon,
    Widget? suffix,
    String? helperText,
    bool readOnly = false,
  }) {
    return InputDecoration(
      hintText: hint,
      helperText: helperText,
      hintStyle: const TextStyle(color: textMuted, fontSize: 13),
      helperStyle: const TextStyle(color: textSecondary, fontSize: 11),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: textSecondary) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: readOnly ? const Color(0xFFF1F2F4) : inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: danger, width: 1.2),
      ),
    );
  }
}
