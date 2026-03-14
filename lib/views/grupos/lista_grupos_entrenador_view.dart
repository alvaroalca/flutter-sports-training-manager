/// Pantalla del entrenador con la lista de sus grupos de entrenamiento.
///
/// Muestra todos los grupos creados por el entrenador en tiempo real.
/// Desde aquí puede crear un grupo nuevo (FAB) o acceder al detalle
/// de uno existente para gestionar miembros y solicitudes.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/controllers/grupos_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/constants/app_routes.dart';
import 'package:tfg/models/grupo.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class ListaGruposEntrenadorView extends StatelessWidget {
  const ListaGruposEntrenadorView({super.key});

  @override
  Widget build(BuildContext context) {
    final entrenadorId = context.read<AuthController>().usuario!.uid;

    return AppScaffold(
      title: 'Mis grupos',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.crearGrupo),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo grupo'),
      ),
      body: StreamBuilder<List<Grupo>>(
        stream: context
            .read<GruposController>()
            .gruposPorEntrenador(entrenadorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los grupos.'));
          }

          final grupos = snapshot.data ?? [];

          if (grupos.isEmpty) {
            return const _EstadoVacio();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: grupos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _TarjetaGrupo(grupo: grupos[index]),
          );
        },
      ),
    );
  }
}

/// Tarjeta que muestra el nombre, descripción, número de miembros
/// y código de un grupo en la lista del entrenador.
class _TarjetaGrupo extends StatelessWidget {
  final Grupo grupo;
  const _TarjetaGrupo({required this.grupo});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.groups_outlined, color: Colors.white),
        ),
        title: Text(
          grupo.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (grupo.descripcion.isNotEmpty)
              Text(
                grupo.descripcion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                _Chip(
                  icon: Icons.person_outline,
                  label: '${grupo.miembrosIds.length} miembros',
                ),
                const SizedBox(width: 8),
                _Chip(
                  icon: Icons.tag,
                  label: grupo.codigoGrupo,
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        onTap: () => context.push(
          AppRoutes.detalleGrupo.replaceFirst(':id', grupo.id),
        ),
      ),
    );
  }
}

/// Pequeño indicador visual con icono y texto para mostrar
/// datos compactos de un grupo (nº miembros, código).
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Vista que se muestra cuando el entrenador todavía no ha creado ningún grupo.
/// Orienta al usuario sobre cómo crear el primero.
class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Sin grupos creados',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'Pulsa + para crear tu primer grupo\ny añadir atletas por su código.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
