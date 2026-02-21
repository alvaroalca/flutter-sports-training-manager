/// Estilos de texto centralizados de la aplicación.
///
/// Evita repetir `.copyWith(...)` en cada widget y garantiza coherencia
/// tipográfica. Complementa el [TextTheme] de Material con estilos
/// específicos de la app que no tienen equivalente en el tema global.
///
/// ## Convención de uso
///   - Usa [AppTextStyles.X] directamente en `style: AppTextStyles.bodySecondary`.
///   - Para variaciones puntuales usa `.copyWith(color: ...)` sin crear un nuevo token.
///   - No crees tokens para estilos de un solo uso; usa inline solo en ese caso.
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Títulos ────────────────────────────────────────────

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Título de sección dentro de una pantalla (listas, cards…).
  static const TextStyle titleSection = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Cuerpo ─────────────────────────────────────────────

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // ── Etiquetas y captions ───────────────────────────────

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    color: AppColors.textSecondary,
  );

  /// Etiqueta de estado/chip: negrita pequeña, color dinámico vía copyWith.
  static const TextStyle chipLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  // ── Especiales ─────────────────────────────────────────

  /// Número grande para temporizadores y contadores destacados.
  static const TextStyle timerDisplay = TextStyle(
    fontSize: 96,
    fontWeight: FontWeight.bold,
    // color se asigna dinámicamente con .copyWith(color: ...)
  );

  /// Etiqueta de fase del temporizador (PREPARACIÓN, APUNTA…).
  static const TextStyle timerLabel = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    letterSpacing: 2,
    // color se asigna dinámicamente con .copyWith(color: ...)
  );
}
