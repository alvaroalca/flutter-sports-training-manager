/// Configuración central de la navegación con GoRouter.
///
/// La estrategia de redirección es la siguiente:
///   - Si el usuario NO está autenticado → siempre redirige a [AppRoutes.login].
///   - Si el usuario SÍ está autenticado e intenta acceder a login o registro
///     → redirige a [AppRoutes.home] para evitar volver a la pantalla de auth.
///
/// El router escucha el stream [AuthController.authStateChanges] para
/// reaccionar automáticamente cuando la sesión cambia (login / logout).
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/core/constants/app_routes.dart';
import 'package:tfg/views/auth/login_view.dart';
import 'package:tfg/views/auth/register_view.dart';
import 'package:tfg/views/dashboard/dashboard_view.dart';
import 'package:tfg/views/training/entrenamientos_view.dart';
import 'package:tfg/views/training/crear_entrenamiento_view.dart';
import 'package:tfg/views/training/detalle_entrenamiento_view.dart';
import 'package:tfg/views/tracking/tracking_view.dart';
import 'package:tfg/views/coach/panel_entrenador_view.dart';
import 'package:tfg/views/coach/perfil_atleta_view.dart';
import 'package:tfg/views/library/biblioteca_view.dart';
import 'package:tfg/views/library/detalle_recurso_view.dart';
import 'package:tfg/views/grupos/lista_grupos_entrenador_view.dart';
import 'package:tfg/views/grupos/lista_grupos_atleta_view.dart';
import 'package:tfg/views/grupos/crear_grupo_view.dart';
import 'package:tfg/views/grupos/detalle_grupo_view.dart';
import 'package:tfg/views/profile/perfil_view.dart';

/// Construye y devuelve el [GoRouter] configurado para la aplicación.
///
/// Recibe el [BuildContext] raíz para poder acceder a [AuthController]
/// a través de Provider y suscribirse a los cambios de sesión.
GoRouter buildRouter(BuildContext context) {
  final authController = Provider.of<AuthController>(context, listen: false);

  return GoRouter(
    /// Ruta inicial al abrir la app. El redirect se encargará de redirigir
    /// al destino correcto según el estado de autenticación.
    initialLocation: AppRoutes.login,

    /// Stream que notifica al router cuando el estado de autenticación cambia,
    /// forzando una reevaluación de la lógica de redirección.
    refreshListenable: _AuthStateListenable(authController.authStateChanges),

    /// Lógica de redirección centralizada.
    redirect: (BuildContext ctx, GoRouterState state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAuthenticated = user != null;
      final isOnAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;

      // Usuario no autenticado intentando acceder a una ruta protegida
      if (!isAuthenticated && !isOnAuthRoute) {
        return AppRoutes.login;
      }

      // Usuario autenticado intentando acceder a login o registro
      if (isAuthenticated && isOnAuthRoute) {
        return AppRoutes.home;
      }

      // Sin redirección necesaria
      return null;
    },

    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterView(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardView(),
      ),

      GoRoute(
        path: AppRoutes.entrenamientos,
        builder: (context, state) => const EntrenamientosView(),
      ),
      GoRoute(
        path: AppRoutes.crearEntrenamiento,
        builder: (context, state) => const CrearEntrenamientoView(),
      ),
      GoRoute(
        path: AppRoutes.detalleEntrenamiento,
        builder: (context, state) => DetalleEntrenamientoView(
          entrenamientoId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.tracking,
        builder: (context, state) => TrackingView(
          entrenamientoId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.panelEntrenador,
        builder: (context, state) => const PanelEntrenadorView(),
      ),
      GoRoute(
        path: AppRoutes.perfilAtleta,
        builder: (context, state) => PerfilAtletaView(
          atletaId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.biblioteca,
        builder: (context, state) => const BibliotecaView(),
      ),
      GoRoute(
        path: AppRoutes.detalleRecurso,
        builder: (context, state) => DetalleRecursoView(
          recursoId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.gruposEntrenador,
        builder: (context, state) => const ListaGruposEntrenadorView(),
      ),
      // crearGrupo (/grupos/nuevo) debe ir ANTES que detalleGrupo (/grupos/:id)
      GoRoute(
        path: AppRoutes.crearGrupo,
        builder: (context, state) => const CrearGrupoView(),
      ),
      GoRoute(
        path: AppRoutes.detalleGrupo,
        builder: (context, state) => DetalleGrupoView(
          grupoId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.gruposAtleta,
        builder: (context, state) => const ListaGruposAtletaView(),
      ),
      GoRoute(
        path: AppRoutes.perfil,
        builder: (context, state) => const PerfilView(),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilidades internas
// ─────────────────────────────────────────────────────────────────────────────

/// Adaptador que convierte un [Stream<User?>] en un [Listenable].
///
/// GoRouter acepta un [Listenable] en su parámetro [refreshListenable].
/// Esta clase suscribe al stream de Firebase Auth y llama a [notifyListeners]
/// cada vez que el estado de sesión cambia, forzando la reevaluación del redirect.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(Stream<User?> stream) {
    stream.listen((_) => notifyListeners());
  }
}
