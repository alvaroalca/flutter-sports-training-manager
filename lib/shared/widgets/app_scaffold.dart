/// Scaffold compartido de la aplicación.
///
/// Proporciona el header consistente en todas las pantallas:
///   - Izquierda: menú hamburguesa si es pantalla raíz (sin historial de nav),
///     flecha de volver si hay una pantalla anterior en el stack.
///   - Derecha: avatar del usuario autenticado (toca para ir a perfil).
///
/// Uso:
/// ```dart
/// AppScaffold(
///   title: 'Mis grupos',
///   body: ...,
///   floatingActionButton: ...,   // opcional
/// )
/// ```
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/core/constants/app_routes.dart';
import 'package:tfg/core/theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  /// Contenido principal de la pantalla.
  final Widget body;

  /// Título mostrado en el centro del header. Opcional: en el dashboard
  /// se deja vacío para un aspecto más limpio.
  final String? title;

  /// Botón flotante opcional (FAB). Se pasa tal cual al [Scaffold].
  final Widget? floatingActionButton;

  /// Widget adicional bajo la barra (p.ej. el SegmentedButton del dashboard).
  final PreferredSizeWidget? bottom;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.floatingActionButton,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    // ModalRoute.of(context)?.isFirst == false es más fiable que context.canPop()
    // en go_router v14 para rutas navegadas con context.push(), ya que consulta
    // directamente el stack del Navigator de Flutter y crea una dependencia
    // reactiva (el widget se reconstruye cuando cambia la navegación).
    final canGoBack = ModalRoute.of(context)?.isFirst == false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,

        // ── Izquierda: hamburguesa o flecha ──────────────
        leading: canGoBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Volver',
                onPressed: () => context.pop(),
              )
            : IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menú',
                onPressed: () {
                  // TODO: abrir drawer cuando se implemente el menú lateral
                },
              ),

        // ── Título ───────────────────────────────────────
        title: title != null
            ? Text(
                title!,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnPrimary,
                ),
              )
            : null,

        // ── Derecha: avatar ──────────────────────────────
        actions: const [_UserAvatar()],

        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar del usuario (siempre en el header)
// ─────────────────────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  Future<void> _cambiarFoto(BuildContext context) async {
    final ctrl = context.read<AuthController>();
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    if (!context.mounted) return;
    final url = await ctrl.subirFotoPerfil(bytes, ext.isEmpty ? 'jpg' : ext);
    if (url == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar la foto de perfil.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<AuthController>().usuario;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => context.push(AppRoutes.perfil),
        onLongPress: () => _cambiarFoto(context),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white24,
          backgroundImage: usuario?.fotoPerfil != null
              ? NetworkImage(usuario!.fotoPerfil!)
              : null,
          child: usuario?.fotoPerfil == null
              ? Text(
                  usuario?.nombre.isNotEmpty == true
                      ? usuario!.nombre[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
