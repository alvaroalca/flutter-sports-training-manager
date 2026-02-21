/// Cadenas de texto de la aplicación centralizadas.
///
/// ## Preparación para i18n
/// Cuando se añada soporte multiidioma (flutter_localizations + .arb),
/// cada clave de esta clase se convertirá en una entrada del fichero
/// `lib/l10n/app_es.arb` (y sus equivalentes en otros idiomas).
/// El nombre de cada constante coincide intencionalmente con la clave ARB
/// para facilitar la migración: solo habrá que sustituir `AppStrings.X`
/// por `AppLocalizations.of(context)!.X`.
class AppStrings {
  AppStrings._();

  // ── App ────────────────────────────────────────────────
  static const String appName        = 'ShootTrack';

  // ── Auth ───────────────────────────────────────────────
  static const String login          = 'Iniciar sesión';
  static const String register       = 'Crear cuenta';
  static const String email          = 'Correo electrónico';
  static const String password       = 'Contraseña';
  static const String confirmPassword = 'Confirmar contraseña';
  static const String nombre         = 'Nombre';
  static const String apellidos      = 'Apellidos';
  static const String noAccount      = '¿No tienes cuenta? Regístrate';
  static const String hasAccount     = '¿Ya tienes cuenta? Inicia sesión';

  // ── Validation ────────────────────────────────────────
  static const String fieldRequired  = 'Este campo es obligatorio';
  static const String emailInvalid   = 'Introduce un email válido';
  static const String passwordShort  = 'Mínimo 6 caracteres';
  static const String passwordMismatch = 'Las contraseñas no coinciden';

  // ── General ───────────────────────────────────────────
  static const String save           = 'Guardar';
  static const String cancel         = 'Cancelar';
  static const String accept         = 'Aceptar';
  static const String errorGeneric   = 'Ha ocurrido un error. Inténtalo de nuevo.';
}
