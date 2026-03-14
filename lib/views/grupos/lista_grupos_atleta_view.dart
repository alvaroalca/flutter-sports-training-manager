/// Pantalla del atleta con los grupos a los que pertenece.
///
/// Muestra en tiempo real los grupos en los que el atleta es miembro.
/// Desde aquí puede solicitar unirse a un nuevo grupo introduciendo
/// el código del grupo que le haya compartido el entrenador.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/controllers/grupos_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/models/grupo.dart';
import 'package:tfg/models/usuario.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class ListaGruposAtletaView extends StatefulWidget {
  const ListaGruposAtletaView({super.key});

  @override
  State<ListaGruposAtletaView> createState() => _ListaGruposAtletaViewState();
}

class _ListaGruposAtletaViewState extends State<ListaGruposAtletaView> {
  /// Caché de entrenadores: UID → Usuario.
  final Map<String, Usuario> _entrenadores = {};

  Future<void> _cargarEntrenadores(List<Grupo> grupos) async {
    final nuevos = grupos
        .map((g) => g.entrenadorId)
        .where((uid) => !_entrenadores.containsKey(uid))
        .toSet()
        .toList();
    if (nuevos.isEmpty) return;
    final usuarios =
        await context.read<GruposController>().cargarUsuarios(nuevos);
    if (!mounted) return;
    setState(() {
      for (final u in usuarios) {
        _entrenadores[u.uid] = u;
      }
    });
  }

  /// Muestra un diálogo con un campo de texto para que el atleta
  /// introduzca el código del grupo al que quiere solicitar unirse.
  ///
  /// Llama a [GruposController.solicitarUnirseAGrupo] y muestra el resultado
  /// (éxito o mensaje de error) en un [SnackBar].
  void _mostrarDialogoUnirse() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unirse a un grupo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Introduce el código del grupo que te ha compartido tu entrenador.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Código del grupo',
                hintText: '#000001',
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            onPressed: () async {
              final codigo = ctrl.text;
              Navigator.of(ctx).pop();

              final atletaId =
                  context.read<AuthController>().usuario!.uid;
              final error = await context
                  .read<GruposController>()
                  .solicitarUnirseAGrupo(
                    codigoGrupo: codigo,
                    atletaUid: atletaId,
                  );

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  error ?? 'Solicitud enviada. Espera la aprobación del entrenador.',
                ),
                backgroundColor:
                    error != null ? AppColors.error : AppColors.success,
              ));
            },
            child: const Text('Solicitar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final atletaId = context.read<AuthController>().usuario!.uid;

    return AppScaffold(
      title: 'Mis grupos',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoUnirse,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add_outlined),
        label: const Text('Unirme a un grupo'),
      ),
      body: StreamBuilder<List<Grupo>>(
        stream:
            context.read<GruposController>().gruposDelAtleta(atletaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error al cargar los grupos.'));
          }

          final grupos = snapshot.data ?? [];

          if (grupos.isNotEmpty) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _cargarEntrenadores(grupos));
          }

          if (grupos.isEmpty) {
            return const _EstadoVacio();
          }

          return ListView.separated(
            padding: const EdgeInsets.only(
                left: 16, right: 16, top: 16, bottom: 88),
            itemCount: grupos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final grupo = grupos[index];
              final entrenador = _entrenadores[grupo.entrenadorId];
              return _TarjetaGrupoAtleta(
                grupo: grupo,
                entrenador: entrenador,
              );
            },
          );
        },
      ),
    );
  }
}

/// Tarjeta que muestra la información de un grupo al que pertenece el atleta,
/// incluyendo el nombre del entrenador (cargado asíncronamente).
class _TarjetaGrupoAtleta extends StatelessWidget {
  final Grupo grupo;

  /// Objeto [Usuario] del entrenador. Puede ser null mientras se carga.
  final Usuario? entrenador;

  const _TarjetaGrupoAtleta({
    required this.grupo,
    required this.entrenador,
  });

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
            if (entrenador != null)
              Text(
                'Entrenador: ${entrenador!.nombreCompleto}',
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
      ),
    );
  }
}

/// Indicador compacto con icono y texto para mostrar metadatos del grupo.
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

/// Vista que se muestra cuando el atleta todavía no pertenece a ningún grupo.
/// Indica al usuario cómo solicitar unirse a uno mediante el FAB.
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
            Icon(Icons.group_work_outlined,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Sin grupos',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'Pulsa el botón para unirte a un grupo\ncon el código que te dé tu entrenador.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
