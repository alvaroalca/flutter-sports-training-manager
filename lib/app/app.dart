/// Punto de entrada de la interfaz de la aplicación.
///
/// [MyApp] configura:
///   - [MultiProvider]: inyecta los controllers disponibles en todo el árbol
///     de widgets mediante el paquete Provider.
///   - [MaterialApp.router]: usa GoRouter para la navegación declarativa.
///   - [AppTheme.light()]: aplica el tema visual global (ver core/theme/app_theme.dart).
///
/// El router se construye dentro de [_AppWithRouter] para poder acceder
/// al [BuildContext] con los providers ya disponibles en el árbol.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/controllers/entrenamiento_controller.dart';
import 'package:tfg/controllers/tracking_controller.dart';
import 'package:tfg/controllers/coach_controller.dart';
import 'package:tfg/controllers/biblioteca_controller.dart';
import 'package:tfg/controllers/grupos_controller.dart';
import 'package:tfg/core/l10n/app_strings.dart';
import 'package:tfg/core/theme/app_theme.dart';
import 'package:tfg/app/router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      /// Registro de todos los ChangeNotifier disponibles en la app.
      /// Al añadir nuevos controllers se registran aquí.
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => EntrenamientoController()),
        ChangeNotifierProvider(create: (_) => TrackingController()),
        ChangeNotifierProvider(create: (_) => CoachController()),
        ChangeNotifierProvider(create: (_) => BibliotecaController()),
        ChangeNotifierProvider(create: (_) => GruposController()),
      ],
      child: const _AppWithRouter(),
    );
  }
}

/// Widget separado que construye el router DESPUÉS de que los providers
/// estén disponibles en el contexto, permitiendo acceder a [AuthController]
/// dentro de [buildRouter] sin errores de contexto.
class _AppWithRouter extends StatefulWidget {
  const _AppWithRouter();

  @override
  State<_AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<_AppWithRouter> {
  /// El router se crea una sola vez y se reutiliza durante toda la sesión.
  late final router = buildRouter(context);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      theme: AppTheme.light(),

      routerConfig: router,
    );
  }
}
