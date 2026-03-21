/// Pantalla principal de la biblioteca técnica.
///
/// Muestra un listado de recursos organizados por categoría.
/// Incluye un selector de filtro horizontal en la cabecera para
/// navegar entre categorías (Todas, Técnica, Equipamiento, etc.).
///
/// Al entrar por primera vez, llama a [BibliotecaController.sembrarContenido]
/// para crear el contenido inicial en Firestore si la colección está vacía.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/biblioteca_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/theme/app_dimensions.dart';
import 'package:tfg/core/theme/app_text_styles.dart';
import 'package:tfg/core/constants/app_routes.dart';
import 'package:tfg/models/recurso.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class BibliotecaView extends StatefulWidget {
  const BibliotecaView({super.key});

  @override
  State<BibliotecaView> createState() => _BibliotecaViewState();
}

class _BibliotecaViewState extends State<BibliotecaView> {
  @override
  void initState() {
    super.initState();
    // Sembrar contenido inicial en segundo plano tras el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BibliotecaController>().sembrarContenido();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<BibliotecaController>();

    return AppScaffold(
      title: 'Biblioteca',
      // Selector de categorías como parte inferior del AppBar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: _FiltrosCategorias(
          seleccionada: ctrl.categoriaFiltro,
          onSeleccionar: ctrl.filtrarPorCategoria,
        ),
      ),
      body: ctrl.sembrando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando biblioteca…'),
                ],
              ),
            )
          : StreamBuilder<List<Recurso>>(
              stream: ctrl.recursos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error al cargar los recursos.'));
                }

                final recursos = snapshot.data ?? [];

                if (recursos.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay recursos en esta categoría.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: recursos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _TarjetaRecurso(recurso: recursos[index]),
                );
              },
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filtro horizontal de categorías
// ─────────────────────────────────────────────────────────────────────────────

/// Fila de chips scrollable para filtrar recursos por categoría.
class _FiltrosCategorias extends StatelessWidget {
  final CategoriaRecurso? seleccionada;
  final ValueChanged<CategoriaRecurso?> onSeleccionar;

  const _FiltrosCategorias({
    required this.seleccionada,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // Chip "Todas"
          _ChipFiltro(
            label: 'Todas',
            seleccionado: seleccionada == null,
            onTap: () => onSeleccionar(null),
          ),
          // Chip por cada categoría disponible
          ...CategoriaRecurso.values.map((cat) => _ChipFiltro(
                label: '${cat.icono} ${cat.etiqueta}',
                seleccionado: seleccionada == cat,
                onTap: () => onSeleccionar(cat),
              )),
        ],
      ),
    );
  }
}

/// Chip individual del filtro de categorías.
class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.label,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: seleccionado ? AppColors.surface : AppColors.surfaceAlpha20,
            borderRadius: BorderRadius.circular(AppDimensions.radiusChip),
            border: Border.all(
              color: seleccionado ? AppColors.primary : AppColors.surfaceAlpha20,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
              color: seleccionado ? AppColors.primary : AppColors.textOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de recurso
// ─────────────────────────────────────────────────────────────────────────────

/// Tarjeta que muestra el título, categoría, autor y resumen de un recurso.
class _TarjetaRecurso extends StatelessWidget {
  final Recurso recurso;
  const _TarjetaRecurso({required this.recurso});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          AppRoutes.detalleRecurso.replaceFirst(':id', recurso.id),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Categoría y fecha ──────────────────
              Row(
                children: [
                  _BadgeCategoria(categoria: recurso.categoria),
                  const Spacer(),
                  Text(
                    _formatFecha(recurso.fechaPublicacion),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── Título ─────────────────────────────
              Text(
                recurso.titulo,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),

              // ── Resumen ────────────────────────────
              Text(
                recurso.resumen,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),

              // ── Autor y enlace ─────────────────────
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
                  const Spacer(),
                  const Text(
                    'Leer más →',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) =>
      '${fecha.day}/${fecha.month}/${fecha.year}';
}

/// Badge de color con el icono y nombre de la categoría del recurso.
class _BadgeCategoria extends StatelessWidget {
  final CategoriaRecurso categoria;
  const _BadgeCategoria({required this.categoria});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLightAlpha15,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryAlpha30),
      ),
      child: Text(
        '${categoria.icono} ${categoria.etiqueta}',
        style: AppTextStyles.chipLabel.copyWith(color: AppColors.primary),
      ),
    );
  }
}
