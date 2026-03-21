/// Pantalla de listado de entrenamientos.
///
/// Muestra comportamiento diferente según el modo de vista activo:
///   - [ModoVista.atleta]: lista los entrenamientos que le han sido asignados,
///     con su estado (pendiente, en progreso, completado).
///   - [ModoVista.entrenador]: lista las plantillas que ha creado y ofrece
///     el botón para crear una nueva.
///
/// Se suscribe a streams de Firestore para actualización en tiempo real.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/controllers/entrenamiento_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/constants/app_routes.dart';
import 'package:tfg/core/theme/app_text_styles.dart';
import 'package:tfg/models/entrenamiento.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class EntrenamientosView extends StatelessWidget {
  const EntrenamientosView({super.key});

  @override
  Widget build(BuildContext context) {
    final esEntrenador =
        context.read<AuthController>().modoVista == ModoVista.entrenador;

    return AppScaffold(
      title: esEntrenador ? 'Mis plantillas' : 'Mis entrenamientos',
      // Botón flotante solo visible para el entrenador
      floatingActionButton: esEntrenador
          ? FloatingActionButton.extended(
              onPressed: () =>
                  context.push(AppRoutes.crearEntrenamiento),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo entrenamiento'),
            )
          : null,
      body: Builder(builder: (context) {
        final uid = context.read<AuthController>().usuario!.uid;
        return esEntrenador
            ? _ListaPlantillas(entrenadorId: uid)
            : _ListaEntrenamientosAtleta(atletaId: uid);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista para el ROL ATLETA
// ─────────────────────────────────────────────────────────────────────────────

/// Widget que muestra los entrenamientos asignados a un atleta en tiempo real.
class _ListaEntrenamientosAtleta extends StatelessWidget {
  final String atletaId;
  const _ListaEntrenamientosAtleta({required this.atletaId});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<EntrenamientoController>();

    return StreamBuilder<List<Entrenamiento>>(
      stream: controller.entrenamientosPorAtleta(atletaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
              child: Text('Error al cargar los entrenamientos.'));
        }
        final entrenamientos = snapshot.data ?? [];
        if (entrenamientos.isEmpty) {
          return const Center(
            child: Text(
              'No tienes entrenamientos asignados aún.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entrenamientos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _TarjetaEntrenamiento(entrenamiento: entrenamientos[index]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Lista para el ROL ENTRENADOR
// ─────────────────────────────────────────────────────────────────────────────

/// Widget que muestra las plantillas creadas por el entrenador.
class _ListaPlantillas extends StatelessWidget {
  final String entrenadorId;
  const _ListaPlantillas({required this.entrenadorId});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<EntrenamientoController>();

    return StreamBuilder<List<Entrenamiento>>(
      stream: controller.plantillasPorEntrenador(entrenadorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar las plantillas.'));
        }
        final plantillas = snapshot.data ?? [];
        if (plantillas.isEmpty) {
          return const Center(
            child: Text(
              'Aún no has creado ninguna plantilla.\nPulsa + para empezar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: plantillas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _TarjetaEntrenamiento(entrenamiento: plantillas[index]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de entrenamiento
// ─────────────────────────────────────────────────────────────────────────────

/// Tarjeta que resume un entrenamiento con su estado y datos principales.
class _TarjetaEntrenamiento extends StatelessWidget {
  final Entrenamiento entrenamiento;
  const _TarjetaEntrenamiento({required this.entrenamiento});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _colorEstado(entrenamiento.estado),
          child: Icon(_iconoEstado(entrenamiento.estado),
              color: AppColors.textOnPrimary, size: 20),
        ),
        title: Text(
          entrenamiento.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entrenamiento.descripcion,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            // Chip con el estado del entrenamiento
            _ChipEstado(estado: entrenamiento.estado),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          AppRoutes.detalleEntrenamiento
              .replaceFirst(':id', entrenamiento.id),
        ),
      ),
    );
  }

  Color _colorEstado(EstadoEntrenamiento estado) {
    switch (estado) {
      case EstadoEntrenamiento.completado:
        return AppColors.success;
      case EstadoEntrenamiento.enProgreso:
        return AppColors.warning;
      case EstadoEntrenamiento.pendiente:
        return AppColors.textSecondary;
    }
  }

  IconData _iconoEstado(EstadoEntrenamiento estado) {
    switch (estado) {
      case EstadoEntrenamiento.completado:
        return Icons.check;
      case EstadoEntrenamiento.enProgreso:
        return Icons.play_arrow;
      case EstadoEntrenamiento.pendiente:
        return Icons.schedule;
    }
  }
}

/// Chip de color que indica el estado actual del entrenamiento.
class _ChipEstado extends StatelessWidget {
  final EstadoEntrenamiento estado;
  const _ChipEstado({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      EstadoEntrenamiento.pendiente => ('Pendiente', AppColors.textSecondary),
      EstadoEntrenamiento.enProgreso => ('En progreso', AppColors.warning),
      EstadoEntrenamiento.completado => ('Completado', AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.chipLabel.copyWith(color: color),
      ),
    );
  }
}
