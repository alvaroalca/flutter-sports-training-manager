/// Constantes de espaciado, radios, tamaños e iconos de la aplicación.
///
/// Centraliza los valores de layout para garantizar consistencia visual
/// y facilitar ajustes globales sin tocar cada widget individualmente.
///
/// ## Convención de escala
///   S → 8   M → 12/16   L → 24   XL → 32
class AppDimensions {
  AppDimensions._();

  // ── Padding / Margin ───────────────────────────────────
  static const double paddingS   =  8.0;
  static const double paddingM   = 16.0;
  static const double paddingL   = 24.0;
  static const double paddingXL  = 32.0;

  // ── Espaciado entre elementos ──────────────────────────
  static const double gapS   =  8.0;
  static const double gapM   = 12.0;
  static const double gapL   = 16.0;
  static const double gapXL  = 24.0;

  // ── Border radius ──────────────────────────────────────
  static const double radiusS    =  8.0;
  static const double radiusM    = 12.0;
  static const double radiusL    = 16.0;
  /// Radio específico para chips de filtro y etiquetas de categoría.
  static const double radiusChip = 20.0;

  // ── Elevación ──────────────────────────────────────────
  static const double elevationCard   = 2.0;

  // ── Tamaños de componentes ─────────────────────────────
  static const double buttonHeight  = 48.0;
  static const double avatarRadiusM =  24.0;
  static const double iconSizeM     =  24.0;
  static const double menuCardIconSize = 40.0;
}
