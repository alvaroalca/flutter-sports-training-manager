/// Pantalla principal (dashboard) de la aplicación.
///
/// Es la pantalla raíz tras iniciar sesión. El header muestra el menú
/// hamburguesa (izquierda) y el avatar del usuario (derecha), gestionados
/// por [AppScaffold].
///
/// El cuerpo contiene:
///   - Saludo personalizado con el nombre del usuario.
///   - [SegmentedButton] para alternar entre el portal de atleta y entrenador.
///   - Grid de accesos rápidos según el portal activo.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/core/constants/app_routes.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/theme/app_dimensions.dart';
import 'package:tfg/core/theme/app_text_styles.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final usuario = authController.usuario;
    final modo = authController.modoVista;

    return AppScaffold(
      // El SegmentedButton vive en el bottom del AppBar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingM,
            vertical: AppDimensions.paddingS,
          ),
          child: _ModoSelector(modoActual: modo),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Saludo ──────────────────────────────────────
            const SizedBox(height: AppDimensions.gapS),
            Text(
              'Hola, ${usuario?.nombre ?? ''}',
              style: AppTextStyles.headlineMedium,
            ),
            Text(
              modo == ModoVista.atleta
                  ? 'Tu panel de entrenamiento'
                  : 'Panel de entrenador',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: AppDimensions.gapXL),

            // ── Grid de accesos rápidos ──────────────────────
            Expanded(
              child: modo == ModoVista.atleta
                  ? const _GridAtleta()
                  : const _GridEntrenador(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selector de modo
// ─────────────────────────────────────────────────────────────────────────────

class _ModoSelector extends StatelessWidget {
  final ModoVista modoActual;

  const _ModoSelector({required this.modoActual});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ModoVista>(
      style: SegmentedButton.styleFrom(
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        selectedBackgroundColor: Colors.white,
        selectedForegroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white54),
      ),
      segments: const [
        ButtonSegment(
          value: ModoVista.atleta,
          icon: Icon(Icons.person_outline),
          label: Text('Atleta'),
        ),
        ButtonSegment(
          value: ModoVista.entrenador,
          icon: Icon(Icons.sports_outlined),
          label: Text('Entrenador'),
        ),
      ],
      selected: {modoActual},
      onSelectionChanged: (seleccion) {
        context.read<AuthController>().cambiarModo(seleccion.first);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grids de accesos rápidos
// ─────────────────────────────────────────────────────────────────────────────

class _GridAtleta extends StatelessWidget {
  const _GridAtleta();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppDimensions.gapM,
      mainAxisSpacing: AppDimensions.gapM,
      children: [
        _MenuCard(
          icon: Icons.fitness_center,
          label: 'Mis entrenamientos',
          onTap: () => context.push(AppRoutes.entrenamientos),
        ),
        _MenuCard(
          icon: Icons.play_circle_outline,
          label: 'Entrenar',
          onTap: () => context.push(AppRoutes.entrenamientos),
        ),
        _MenuCard(
          icon: Icons.menu_book_outlined,
          label: 'Biblioteca',
          onTap: () => context.push(AppRoutes.biblioteca),
        ),
        _MenuCard(
          icon: Icons.group_work_outlined,
          label: 'Mis grupos',
          onTap: () => context.push(AppRoutes.gruposAtleta),
        ),
        _MenuCard(
          icon: Icons.person_outline,
          label: 'Mi perfil',
          onTap: () => context.push(AppRoutes.perfil),
        ),
      ],
    );
  }
}

class _GridEntrenador extends StatelessWidget {
  const _GridEntrenador();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppDimensions.gapM,
      mainAxisSpacing: AppDimensions.gapM,
      children: [
        _MenuCard(
          icon: Icons.group_outlined,
          label: 'Mis atletas',
          onTap: () => context.push(AppRoutes.panelEntrenador),
        ),
        _MenuCard(
          icon: Icons.add_box_outlined,
          label: 'Mis plantillas',
          onTap: () => context.push(AppRoutes.entrenamientos),
        ),
        _MenuCard(
          icon: Icons.bar_chart,
          label: 'Progreso atletas',
          onTap: () => context.push(AppRoutes.panelEntrenador),
        ),
        _MenuCard(
          icon: Icons.groups_outlined,
          label: 'Grupos',
          onTap: () => context.push(AppRoutes.gruposEntrenador),
        ),
        _MenuCard(
          icon: Icons.menu_book_outlined,
          label: 'Biblioteca',
          onTap: () => context.push(AppRoutes.biblioteca),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de acceso rápido
// ─────────────────────────────────────────────────────────────────────────────

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: AppDimensions.menuCardIconSize, color: AppColors.primary),
              const SizedBox(height: AppDimensions.gapM),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.titleSection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
