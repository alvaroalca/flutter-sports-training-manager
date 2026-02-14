/// Constantes con los nombres de todas las rutas de navegación.
///
/// Centralizar las rutas evita errores de tipado al navegar y facilita
/// el refactoring cuando se añaden o renombran pantallas.
/// El router se configura en [lib/app/app.dart] usando estas constantes.
class AppRoutes {
  /// Pantalla de inicio de sesión. Punto de entrada cuando no hay sesión activa.
  static const String login = '/login';

  /// Pantalla de registro de nuevo usuario.
  static const String register = '/register';

  /// Dashboard principal tras iniciar sesión.
  ///
  /// Desde aquí el usuario puede alternar entre el portal de atleta
  /// y el portal de entrenador sin cerrar sesión.
  static const String dashboard = '/dashboard';

  /// Alias de [dashboard] mantenido por compatibilidad con redirecciones existentes.
  static const String home = '/dashboard';

  /// Listado de entrenamientos asignados al atleta.
  static const String entrenamientos = '/entrenamientos';

  /// Formulario para crear un nuevo entrenamiento (solo entrenador).
  static const String crearEntrenamiento = '/entrenamientos/nuevo';

  /// Detalle de un entrenamiento concreto.
  static const String detalleEntrenamiento = '/entrenamientos/:id';

  /// Pantalla de seguimiento/ejecución de un entrenamiento en curso.
  static const String tracking = '/tracking/:id';

  /// Panel del entrenador con el progreso de sus atletas.
  static const String panelEntrenador = '/panel-entrenador';

  /// Detalle del progreso de un atleta específico.
  static const String perfilAtleta = '/atleta/:id';

  /// Biblioteca de recursos técnicos de tiro deportivo.
  static const String biblioteca = '/biblioteca';

  /// Detalle de un recurso concreto de la biblioteca.
  static const String detalleRecurso = '/biblioteca/:id';

  /// Lista de grupos del entrenador.
  static const String gruposEntrenador = '/grupos-entrenador';

  /// Formulario para crear un nuevo grupo (solo entrenador).
  /// Debe registrarse antes que [detalleGrupo] para que 'nuevo' no se
  /// interprete como el parámetro :id.
  static const String crearGrupo = '/grupos/nuevo';

  /// Detalle de un grupo (gestión de miembros y solicitudes).
  static const String detalleGrupo = '/grupos/:id';

  /// Lista de grupos del atleta.
  static const String gruposAtleta = '/grupos-atleta';

  /// Perfil del usuario autenticado.
  static const String perfil = '/perfil';
}
