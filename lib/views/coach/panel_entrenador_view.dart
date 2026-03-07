/// Pantalla del panel principal del entrenador.
///
/// Muestra la lista de atletas vinculados al entrenador autenticado.
/// Cada tarjeta de atleta indica su nombre, categoría, modalidad y
/// un resumen rápido del número de entrenamientos completados.
///
/// Desde aquí el entrenador puede acceder al perfil detallado de cada atleta
/// para revisar su historial de resultados y añadir observaciones.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/controllers/coach_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/theme/app_dimensions.dart';
import 'package:tfg/core/theme/app_text_styles.dart';
import 'package:tfg/core/constants/app_routes.dart';
import 'package:tfg/models/atleta.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class PanelEntrenadorView extends StatefulWidget {
  const PanelEntrenadorView({super.key});

  @override
  State<PanelEntrenadorView> createState() => _PanelEntrenadorViewState();
}

class _PanelEntrenadorViewState extends State<PanelEntrenadorView> {
  /// Mapeo de UID de atleta a su nombre completo, cargado asíncronamente.
  /// Se rellena una vez que llegan los atletas del stream.
  final Map<String, AtletaConPerfil> _perfiles = {};
  bool _cargandoPerfiles = false;

  /// Carga los perfiles (Usuario + Atleta) de la lista de atletas recibida.
  Future<void> _cargarPerfiles(List<Atleta> atletas) async {
    // Evitar recargas si ya están todos en caché
    final nuevos = atletas.where((a) => !_perfiles.containsKey(a.uid)).toList();
    if (nuevos.isEmpty || _cargandoPerfiles) return;

    setState(() => _cargandoPerfiles = true);
    final perfiles =
        await context.read<CoachController>().cargarPerfilesAtletas(nuevos);
    if (!mounted) return;
    setState(() {
      for (final p in perfiles) {
        _perfiles[p.usuario.uid] = p;
      }
      _cargandoPerfiles = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entrenadorId = context.read<AuthController>().usuario!.uid;

    return AppScaffold(
      title: 'Mis atletas',
      body: StreamBuilder<List<Atleta>>(
        stream: context
            .read<CoachController>()
            .atletasPorEntrenador(entrenadorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error al cargar los atletas.'));
          }

          final atletas = snapshot.data ?? [];

          // Cargar perfiles en segundo plano cuando llegan nuevos atletas
          if (atletas.isNotEmpty) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _cargarPerfiles(atletas));
          }

          if (atletas.isEmpty) {
            return _EstadoVacio();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: atletas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final atleta = atletas[index];
              final perfil = _perfiles[atleta.uid];
              return _TarjetaAtleta(
                atleta: atleta,
                perfil: perfil,
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internos
// ─────────────────────────────────────────────────────────────────────────────

/// Tarjeta que resume la información de un atleta en la lista del entrenador.
class _TarjetaAtleta extends StatelessWidget {
  final Atleta atleta;

  /// Perfil completo del atleta (puede ser null mientras carga).
  final AtletaConPerfil? perfil;

  const _TarjetaAtleta({required this.atleta, this.perfil});

  @override
  Widget build(BuildContext context) {
    final nombre = perfil?.usuario.nombreCompleto ?? '...';

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          radius: AppDimensions.avatarRadiusM,
          child: Text(
            // Iniciales del atleta como avatar
            perfil != null && perfil!.usuario.nombre.isNotEmpty && perfil!.usuario.apellidos.isNotEmpty
                ? '${perfil!.usuario.nombre[0]}${perfil!.usuario.apellidos[0]}'
                : '?',
            style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
        title: Text(
          nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _ChipInfo(atleta.modalidad, Icons.gps_fixed),
                const SizedBox(width: 8),
                _ChipInfo(atleta.categoria, Icons.category_outlined),
              ],
            ),
            if (atleta.licenciaFederativa != null) ...[
              const SizedBox(height: 4),
              Text(
                'Licencia: ${atleta.licenciaFederativa}',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.primary),
        isThreeLine: true,
        onTap: () => context.push(
          AppRoutes.perfilAtleta.replaceFirst(':id', atleta.uid),
        ),
      ),
    );
  }
}

/// Pequeño chip informativo con icono y texto.
class _ChipInfo extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ChipInfo(this.label, this.icon);

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

/// Vista de estado vacío cuando el entrenador aún no tiene atletas vinculados.
class _EstadoVacio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_outlined,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'Sin atletas vinculados',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'Los atletas que se registren con tu código de entrenador\naparecerán aquí automáticamente.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
