/// Pantalla de detalle de un grupo de entrenamiento (vista del entrenador).
///
/// Presenta dos pestañas:
///   - "Miembros": lista de atletas actuales con opción de añadir por código
///     o eliminar a uno existente.
///   - "Solicitudes": lista de solicitudes pendientes con botones de
///     aprobar o rechazar.
///
/// El código del grupo se muestra en el AppBar y puede ampliarse en un
/// diálogo para compartirlo fácilmente con los atletas.
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/controllers/entrenamiento_controller.dart';
import 'package:tfg/controllers/grupos_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/models/entrenamiento.dart';
import 'package:tfg/models/grupo.dart';
import 'package:tfg/models/solicitud_grupo.dart';
import 'package:tfg/models/usuario.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class DetalleGrupoView extends StatefulWidget {
  final String grupoId;
  const DetalleGrupoView({super.key, required this.grupoId});

  @override
  State<DetalleGrupoView> createState() => _DetalleGrupoViewState();
}

class _DetalleGrupoViewState extends State<DetalleGrupoView> {
  Grupo? _grupo;
  bool _cargando = true;

  /// Caché de perfiles cargados: UID → Usuario.
  final Map<String, Usuario> _perfiles = {};

  @override
  void initState() {
    super.initState();
    _cargarGrupo();
  }

  Future<void> _cargarGrupo() async {
    final grupo = await context
        .read<GruposController>()
        .obtenerGrupo(widget.grupoId);
    if (!mounted) return;
    setState(() {
      _grupo = grupo;
      _cargando = false;
    });
    if (grupo != null) {
      _cargarPerfilesNuevos(grupo.miembrosIds);
    }
  }

  Future<void> _cargarPerfilesNuevos(List<String> uids) async {
    final nuevos = uids.where((uid) => !_perfiles.containsKey(uid)).toList();
    if (nuevos.isEmpty) return;
    final usuarios =
        await context.read<GruposController>().cargarUsuarios(nuevos);
    if (!mounted) return;
    setState(() {
      for (final u in usuarios) {
        _perfiles[u.uid] = u;
      }
    });
  }

  /// Abre el selector de imágenes y sube la nueva foto de portada del grupo.
  Future<void> _cambiarFoto() async {
    // Capturar el controller antes de cualquier await
    final ctrl = context.read<GruposController>();

    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;

    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();

    final url = await ctrl.subirFotoGrupo(
      grupoId: widget.grupoId,
      bytes: bytes,
      extension: ext.isEmpty ? 'jpg' : ext,
    );

    if (!mounted) return;
    if (url != null) {
      _cargarGrupo();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo subir la foto. Inténtalo de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Diálogo para asignar plantillas (entrenamientos) a todos los miembros del grupo.
  Future<void> _mostrarDialogoAsignarEntrenamientos(Grupo grupo) async {
    if (grupo.miembrosIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El grupo no tiene miembros todavía.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final entrenadorId = context.read<AuthController>().usuario!.uid;
    final entrenamientoCtrl = context.read<EntrenamientoController>();
    final selecionadas = <String>{};
    var ultimoSnapshot = <Entrenamiento>[];

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Asignar entrenamientos'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<List<Entrenamiento>>(
              stream:
                  entrenamientoCtrl.plantillasPorEntrenador(entrenadorId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final plantillas = snapshot.data ?? [];
                ultimoSnapshot = plantillas;
                if (plantillas.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No tienes plantillas todavía. Créalas primero en "Mis plantillas".',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Se asignará a los ${grupo.miembrosIds.length} miembros del grupo.',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: plantillas.length,
                        itemBuilder: (_, i) {
                          final p = plantillas[i];
                          final marcada = selecionadas.contains(p.id);
                          return CheckboxListTile(
                            title: Text(p.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              '${p.ejerciciosIds.length} ejercicios',
                              style: const TextStyle(fontSize: 12),
                            ),
                            value: marcada,
                            onChanged: (v) {
                              setStateDialog(() {
                                if (v == true) {
                                  selecionadas.add(p.id);
                                } else {
                                  selecionadas.remove(p.id);
                                }
                              });
                            },
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            dense: true,
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: selecionadas.isEmpty
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: Text('Asignar (${selecionadas.length})'),
            ),
          ],
        ),
      ),
    );

    if (confirmar != true || !mounted) return;

    final plantillasSeleccionadas = ultimoSnapshot
        .where((p) => selecionadas.contains(p.id))
        .toList();
    if (plantillasSeleccionadas.isEmpty) return;

    final total = await entrenamientoCtrl.asignarPlantillasAGrupo(
      plantillas: plantillasSeleccionadas,
      atletasIds: grupo.miembrosIds,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(total != null
          ? 'Asignados $total entrenamientos.'
          : 'Error al asignar entrenamientos.'),
      backgroundColor: total != null ? AppColors.success : AppColors.error,
    ));
  }

  void _mostrarDialogoAnadirAtleta() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir atleta por código'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Código del atleta',
            hintText: '#000001',
          ),
          textCapitalization: TextCapitalization.characters,
          autofocus: true,
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
              final error = await context
                  .read<GruposController>()
                  .agregarAtletaPorCodigo(
                    codigoUsuario: codigo,
                    grupoId: widget.grupoId,
                  );
              if (!mounted) return;
              // Recargar grupo para reflejar el nuevo miembro
              _cargarGrupo();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text(error ?? 'Atleta añadido correctamente.'),
                backgroundColor:
                    error != null ? AppColors.error : AppColors.success,
              ));
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _mostrarCodigoGrupo(String codigo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Código del grupo',
            textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              codigo,
              style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Comparte este código con tus atletas para que puedan solicitar unirse al grupo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const AppScaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_grupo == null) {
      return const AppScaffold(
        title: 'Grupo',
        body: Center(child: Text('Grupo no encontrado.')),
      );
    }

    final grupo = _grupo!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(grupo.nombre,
                  style: const TextStyle(fontSize: 16)),
              Text(
                grupo.codigoGrupo,
                style:
                    const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_a_photo_outlined),
              tooltip: 'Cambiar foto del grupo',
              onPressed: _cambiarFoto,
            ),
            IconButton(
              icon: const Icon(Icons.tag),
              tooltip: 'Ver código del grupo',
              onPressed: () => _mostrarCodigoGrupo(grupo.codigoGrupo),
            ),
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              tooltip: 'Añadir atleta',
              onPressed: _mostrarDialogoAnadirAtleta,
            ),
            IconButton(
              icon: const Icon(Icons.fitness_center),
              tooltip: 'Asignar entrenamientos',
              onPressed: () => _mostrarDialogoAsignarEntrenamientos(grupo),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.people_outline), text: 'Miembros'),
              Tab(
                  icon: Icon(Icons.pending_outlined),
                  text: 'Solicitudes'),
            ],
          ),
        ),
        body: Column(
          children: [
            // ── Foto de portada (si existe) ────────────────
            if (grupo.fotoGrupo != null)
              SizedBox(
                width: double.infinity,
                height: 140,
                child: Image.network(
                  grupo.fotoGrupo!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
            _TabMiembros(
              grupo: grupo,
              perfiles: _perfiles,
              onEliminar: (atletaUid) async {
                final messenger = ScaffoldMessenger.of(context);
                final ok = await context
                    .read<GruposController>()
                    .eliminarMiembro(
                        grupoId: grupo.id, atletaUid: atletaUid);
                if (!mounted) return;
                _cargarGrupo();
                messenger.showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Miembro eliminado.'
                      : 'Error al eliminar el miembro.'),
                  backgroundColor:
                      ok ? AppColors.success : AppColors.error,
                ));
              },
            ),
            _TabSolicitudes(
              grupoId: grupo.id,
              perfiles: _perfiles,
              onCargarPerfil: (uid) => _cargarPerfilesNuevos([uid]),
              onResolver: (solicitudId, atletaId, aprobada) async {
                await context
                    .read<GruposController>()
                    .resolverSolicitud(
                      solicitudId: solicitudId,
                      grupoId: grupo.id,
                      atletaId: atletaId,
                      aprobada: aprobada,
                    );
                if (!mounted) return;
                // Si se aprobó, recargar grupo para mostrar nuevo miembro
                if (aprobada) {
                  _cargarGrupo();
                }
              },
            ),
                ],          // children TabBarView
              ),            // TabBarView
            ),              // Expanded
          ],                // children Column
        ),                  // Column (body)
      ),                    // Scaffold
    );                      // DefaultTabController
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Miembros
// ─────────────────────────────────────────────────────────────────────────────

/// Pestaña que lista los atletas actualmente miembros del grupo.
///
/// Cada miembro se muestra con su avatar, nombre completo y código de usuario.
/// El entrenador puede eliminarlo con el botón de la derecha (previa confirmación).
class _TabMiembros extends StatelessWidget {
  final Grupo grupo;

  /// Caché de perfiles ya cargados, indexada por UID.
  final Map<String, Usuario> perfiles;

  /// Callback que se invoca con el UID del atleta a eliminar.
  final void Function(String atletaUid) onEliminar;

  const _TabMiembros({
    required this.grupo,
    required this.perfiles,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    if (grupo.miembrosIds.isEmpty) {
      return const Center(
        child: Text(
          'Sin miembros.\nUsa el botón + para añadir atletas por código.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: grupo.miembrosIds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final uid = grupo.miembrosIds[index];
        final perfil = perfiles[uid];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Text(
                perfil != null &&
                        perfil.nombre.isNotEmpty &&
                        perfil.apellidos.isNotEmpty
                    ? '${perfil.nombre[0]}${perfil.apellidos[0]}'
                    : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              perfil?.nombreCompleto ?? '...',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: perfil?.codigoUsuario != null
                ? Text(perfil!.codigoUsuario!,
                    style: const TextStyle(
                        color: AppColors.textSecondary))
                : null,
            trailing: IconButton(
              icon: const Icon(Icons.person_remove_outlined,
                  color: AppColors.error),
              tooltip: 'Eliminar del grupo',
              onPressed: () =>
                  _confirmarEliminar(context, uid, perfil),
            ),
          ),
        );
      },
    );
  }

  void _confirmarEliminar(
      BuildContext context, String uid, Usuario? perfil) {
    final nombre = perfil?.nombreCompleto ?? 'este atleta';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar miembro'),
        content: Text('¿Eliminar a $nombre del grupo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
              onEliminar(uid);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Solicitudes
// ─────────────────────────────────────────────────────────────────────────────

/// Pestaña que muestra las solicitudes de ingreso pendientes de un grupo.
///
/// Se suscribe a un stream de Firestore para mostrar cambios en tiempo real.
/// Cada solicitud ofrece botones para aprobarla (añade al atleta como miembro)
/// o rechazarla (cierra la solicitud sin modificar los miembros).
class _TabSolicitudes extends StatelessWidget {
  final String grupoId;

  /// Caché de perfiles ya cargados, indexada por UID.
  final Map<String, Usuario> perfiles;

  /// Callback para disparar la carga del perfil de un atleta aún no cacheado.
  final void Function(String uid) onCargarPerfil;

  /// Callback invocado al resolver una solicitud:
  /// [solicitudId], [atletaId] y [aprobada] = true/false.
  final void Function(String solicitudId, String atletaId, bool aprobada)
      onResolver;

  const _TabSolicitudes({
    required this.grupoId,
    required this.perfiles,
    required this.onCargarPerfil,
    required this.onResolver,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SolicitudGrupo>>(
      stream: context
          .read<GruposController>()
          .solicitudesPendientes(grupoId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final solicitudes = snapshot.data ?? [];

        if (solicitudes.isEmpty) {
          return const Center(
            child: Text(
              'Sin solicitudes pendientes.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final s in solicitudes) {
            if (!perfiles.containsKey(s.atletaId)) {
              onCargarPerfil(s.atletaId);
            }
          }
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: solicitudes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final solicitud = solicitudes[index];
            final perfil = perfiles[solicitud.atletaId];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    perfil != null &&
                            perfil.nombre.isNotEmpty &&
                            perfil.apellidos.isNotEmpty
                        ? '${perfil.nombre[0]}${perfil.apellidos[0]}'
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  perfil?.nombreCompleto ?? '...',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: perfil?.codigoUsuario != null
                    ? Text(perfil!.codigoUsuario!,
                        style: const TextStyle(
                            color: AppColors.textSecondary))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.error),
                      tooltip: 'Rechazar',
                      onPressed: () => onResolver(
                          solicitud.id, solicitud.atletaId, false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check,
                          color: AppColors.success),
                      tooltip: 'Aprobar',
                      onPressed: () => onResolver(
                          solicitud.id, solicitud.atletaId, true),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
