/// Pantalla de detalle de un recurso de la biblioteca técnica.
///
/// Muestra el contenido completo del recurso con una cabecera que incluye
/// la categoría, el título y el autor, seguida del texto del artículo
/// dividido en párrafos para facilitar la lectura.
import 'package:flutter/material.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/models/recurso.dart';
import 'package:tfg/services/firestore_service.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class DetalleRecursoView extends StatefulWidget {
  /// ID del recurso a mostrar, recibido como parámetro de ruta.
  final String recursoId;

  const DetalleRecursoView({super.key, required this.recursoId});

  @override
  State<DetalleRecursoView> createState() => _DetalleRecursoViewState();
}

class _DetalleRecursoViewState extends State<DetalleRecursoView> {
  final FirestoreService _firestoreService = FirestoreService();
  Recurso? _recurso;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final recurso = await _firestoreService.obtenerRecurso(widget.recursoId);

      if (!mounted) return;

      if (recurso == null) {
        setState(() {
          _cargando = false;
          _error = 'Recurso no encontrado.';
        });
        return;
      }

      setState(() {
        _cargando = false;
        _recurso = recurso;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar el recurso.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const AppScaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _recurso == null) {
      return AppScaffold(
        title: 'Recurso',
        body: Center(child: Text(_error ?? 'Error desconocido')),
      );
    }

    final recurso = _recurso!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Cabecera ───────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: _CabeceraRecurso(recurso: recurso),
            ),
            title: Text(
              recurso.categoria.etiqueta,
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // ── Contenido del artículo ─────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título completo
                  Text(
                    recurso.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Metadatos: autor y fecha
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        recurso.autor,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.calendar_today_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _formatFecha(recurso.fechaPublicacion),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Resumen destacado
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightAlpha10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryAlpha20),
                    ),
                    child: Text(
                      recurso.resumen,
                      style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textPrimary,
                          height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Contenido completo dividido en párrafos
                  _ContenidoArticulo(contenido: recurso.contenido),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) =>
      '${fecha.day}/${fecha.month}/${fecha.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internos
// ─────────────────────────────────────────────────────────────────────────────

/// Fondo de la SliverAppBar con degradado y el icono de la categoría.
class _CabeceraRecurso extends StatelessWidget {
  final Recurso recurso;
  const _CabeceraRecurso({required this.recurso});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.accent, AppColors.primary],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // Icono grande de la categoría
            Text(
              recurso.categoria.icono,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlpha20,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                recurso.categoria.etiqueta,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renderiza el contenido del artículo distinguiendo secciones en MAYÚSCULAS
/// (tratadas como subtítulos) del resto de párrafos.
class _ContenidoArticulo extends StatelessWidget {
  final String contenido;
  const _ContenidoArticulo({required this.contenido});

  @override
  Widget build(BuildContext context) {
    // Dividir el contenido por líneas vacías para obtener párrafos
    final parrafos = contenido
        .split('\n')
        .map((l) => l.trim())
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parrafos.map((parrafo) {
        if (parrafo.isEmpty) return const SizedBox(height: 12);

        // Las líneas en MAYÚSCULAS se muestran como subtítulo de sección
        final esSubtitulo = parrafo == parrafo.toUpperCase() &&
            parrafo.length > 3 &&
            !parrafo.startsWith('-');

        if (esSubtitulo) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 6),
            child: Text(
              parrafo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
          );
        }

        // Párrafo normal
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            parrafo,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        );
      }).toList(),
    );
  }
}
