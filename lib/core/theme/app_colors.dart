/// Paleta de colores centralizada de la aplicación.
///
/// Todos los widgets deben referenciar colores desde esta clase para
/// garantizar consistencia visual y facilitar futuros cambios de tema.
///
/// ## Convención de nombres
///   - [primary], [primaryLight], [accent]  → gama principal
///   - [background], [surface]              → fondos y tarjetas
///   - [textPrimary], [textSecondary]       → tipografía
///   - [textOnPrimary]                      → texto SOBRE colores de fondo
///   - [error], [success], [warning]        → semánticos
///   - [primaryAlpha*]                      → variantes con transparencia del primary
///   - [surfaceAlpha*]                      → variantes con transparencia de blanco
///   - [divider], [border]                  → separadores y bordes
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primarios ──────────────────────────────────────────
  static const Color primary      = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF5E92F3);
  static const Color accent       = Color(0xFF0D47A1);

  // ── Fondo y superficies ────────────────────────────────
  static const Color background   = Color(0xFFF5F5F5);
  static const Color surface      = Colors.white;

  // ── Texto ──────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  /// Color de texto/iconos sobre fondos primarios (AppBar, botones rellenos…).
  static const Color textOnPrimary = Colors.white;

  // ── Semánticos ─────────────────────────────────────────
  static const Color error   = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  // ── Separadores y bordes ───────────────────────────────
  /// Borde suave para inputs y tarjetas en modo claro.
  static const Color border  = Color(0xFFE0E0E0);
  /// Separador ultraligero entre elementos de lista.
  static const Color divider = Color(0xFFEEEEEE);

  // ── Variantes alpha del primary ────────────────────────
  /// primary al 10 % — fondo de chips y badges.
  static const Color primaryAlpha10 = Color(0x1A1565C0);
  /// primary al 20 % — fondo del SegmentedButton no seleccionado.
  static const Color primaryAlpha20 = Color(0x331565C0);
  /// primary al 30 % — borde de chips.
  static const Color primaryAlpha30 = Color(0x4D1565C0);

  // ── Variantes alpha del primaryLight ───────────────────
  /// primaryLight al 10 % — fondo suave de chips de ejercicio.
  static const Color primaryLightAlpha10 = Color(0x1A5E92F3);
  /// primaryLight al 15 % — fondo de chips de resumen.
  static const Color primaryLightAlpha15 = Color(0x265E92F3);

  // ── Variantes alpha de surface (blanco) ────────────────
  /// Blanco al 20 % — fondo de avatar sobre AppBar primario.
  static const Color surfaceAlpha20 = Color(0x33FFFFFF);
  /// Blanco al 25 % — overlay suave sobre imagen de cabecera.
  static const Color surfaceAlpha25 = Color(0x40FFFFFF);
  /// Blanco al 70 % — texto secundario sobre imagen oscura.
  static const Color surfaceAlpha70 = Color(0xB3FFFFFF);
  /// Blanco al 85 % — texto principal sobre imagen oscura.
  static const Color surfaceAlpha85 = Color(0xD9FFFFFF);

}
