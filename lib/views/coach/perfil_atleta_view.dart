/// Pantalla de detalle del progreso de un atleta específico.
///
/// Accesible desde el panel del entrenador. Muestra:
///   - Cabecera con el nombre, categoría, modalidad y licencia del atleta.
///   - Estadísticas globales: total de entrenamientos, disparos y media general.
///   - Historial de resultados en tiempo real (stream de Firestore), con la
///     puntuación total y media de cada sesión.
///   - Posibilidad de expandir cada resultado para ver el detalle por series
///     y añadir/editar observaciones del entrenador.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/coach_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/theme/app_text_styles.dart';
import 'package:tfg/models/resultado.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class PerfilAtletaView extends StatefulWidget {
  /// UID del atleta cuyo perfil se va a mostrar.
  final String atletaId;

  const PerfilAtletaView({super.key, required this.atletaId});

  @override
  State<PerfilAtletaView> createState() => _PerfilAtletaViewState();
}

class _PerfilAtletaViewState extends State<PerfilAtletaView> {
  AtletaConPerfil? _perfil;
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final perfil = await context
        .read<CoachController>()
        .cargarPerfilAtleta(widget.atletaId);
    if (!mounted) return;
    setState(() {
      _cargando = false;
      _perfil = perfil;
      if (perfil == null) _error = 'No se pudo cargar el perfil del atleta.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const AppScaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _perfil == null) {
      return AppScaffold(
        title: 'Perfil atleta',
        body: Center(child: Text(_error ?? 'Error desconocido')),
      );
    }

    final perfil = _perfil!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Cabecera con datos del atleta ──────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: _CabeceraAtleta(perfil: perfil),
            ),
            title: Text(perfil.usuario.nombreCompleto),
          ),

          // ── Contenido scrollable ───────────────────
          SliverToBoxAdapter(
            child: _CuerpoAtleta(
              atletaId: widget.atletaId,
              perfil: perfil,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cabecera expandible
// ─────────────────────────────────────────────────────────────────────────────

/// Cabecera de la SliverAppBar con el avatar y datos principales del atleta.
class _CabeceraAtleta extends StatelessWidget {
  final AtletaConPerfil perfil;
  const _CabeceraAtleta({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
      child: Row(
        children: [
          // Avatar con iniciales
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.surfaceAlpha25,
            child: Text(
              '${perfil.usuario.nombre[0]}${perfil.usuario.apellidos[0]}',
              style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perfil.usuario.nombreCompleto,
                  style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${perfil.atleta.modalidad} · ${perfil.atleta.categoria}',
                  style: const TextStyle(
                      color: AppColors.surfaceAlpha85,
                      fontSize: 13),
                ),
                if (perfil.atleta.licenciaFederativa != null)
                  Text(
                    'Licencia: ${perfil.atleta.licenciaFederativa}',
                    style: const TextStyle(
                        color: AppColors.surfaceAlpha70,
                        fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cuerpo con estadísticas e historial
// ─────────────────────────────────────────────────────────────────────────────

/// Sección principal: estadísticas globales e historial de resultados.
class _CuerpoAtleta extends StatelessWidget {
  final String atletaId;
  final AtletaConPerfil perfil;

  const _CuerpoAtleta({required this.atletaId, required this.perfil});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Resultado>>(
      stream:
          context.read<CoachController>().resultadosPorAtleta(atletaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final resultados = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Estadísticas globales ──────────────
              _TarjetaEstadisticas(resultados: resultados),
              const SizedBox(height: 20),

              // ── Historial ─────────────────────────
              const Text(
                'Historial de resultados',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              if (resultados.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text(
                      'Aún no hay resultados registrados.',
                      style:
                          TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...resultados.map((r) => _TarjetaResultado(resultado: r)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de estadísticas globales
// ─────────────────────────────────────────────────────────────────────────────

/// Tarjeta con las métricas agregadas de todo el historial del atleta.
class _TarjetaEstadisticas extends StatelessWidget {
  final List<Resultado> resultados;
  const _TarjetaEstadisticas({required this.resultados});

  @override
  Widget build(BuildContext context) {
    // Cálculo de métricas globales
    final totalEjercicios = resultados.length;
    final totalDisparos =
        resultados.fold(0, (acc, r) => acc + r.totalDisparos);
    final mediaGlobal = totalDisparos > 0
        ? resultados.fold(0.0, (acc, r) => acc + r.puntuacionTotal) /
            totalDisparos
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatGlobal('Ejercicios', '$totalEjercicios', Icons.fitness_center),
            _Divisor(),
            _StatGlobal('Disparos', '$totalDisparos', Icons.gps_fixed),
            _Divisor(),
            _StatGlobal(
                'Media', mediaGlobal.toStringAsFixed(2), Icons.bar_chart),
          ],
        ),
      ),
    );
  }
}

class _StatGlobal extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icon;
  const _StatGlobal(this.titulo, this.valor, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 6),
        Text(valor,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        Text(titulo,
            style: AppTextStyles.caption),
      ],
    );
  }
}

class _Divisor extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 40, width: 1, color: AppColors.border);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de resultado individual
// ─────────────────────────────────────────────────────────────────────────────

/// Tarjeta expandible con el detalle de un resultado: series, puntuaciones
/// y campo para que el entrenador añada sus observaciones.
class _TarjetaResultado extends StatefulWidget {
  final Resultado resultado;
  const _TarjetaResultado({required this.resultado});

  @override
  State<_TarjetaResultado> createState() => _TarjetaResultadoState();
}

class _TarjetaResultadoState extends State<_TarjetaResultado> {
  late final TextEditingController _obsCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Precarga las observaciones existentes del entrenador si las hay
    _obsCtrl = TextEditingController(
        text: widget.resultado.observacionesEntrenador ?? '');
  }

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarObservaciones() async {
    setState(() => _guardando = true);
    await context
        .read<CoachController>()
        .guardarObservaciones(widget.resultado.id, _obsCtrl.text.trim());
    if (mounted) setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resultado;
    final fecha =
        '${r.fecha.day}/${r.fecha.month}/${r.fecha.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        // ── Resumen en la cabecera de la tarjeta ───
        leading: const CircleAvatar(
          backgroundColor: AppColors.primaryAlpha20,
          child: Icon(Icons.gps_fixed, color: AppColors.primary),
        ),
        title: Text(
          'Sesión $fecha',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${r.totalDisparos} disparos · Total: ${r.puntuacionTotal.toStringAsFixed(1)} pts · '
          'Media: ${r.mediaPorDisparo.toStringAsFixed(2)} pts',
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        // ── Detalle al expandir ────────────────────
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Series con sus disparos
                const Text('Series:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ...r.series.map((s) => _FilaSerie(serie: s)),

                // Observaciones del atleta (solo lectura)
                if (r.observacionesAtleta != null) ...[
                  const SizedBox(height: 12),
                  const Text('Observaciones del atleta:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    r.observacionesAtleta!,
                    style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Campo de observaciones del entrenador (editable)
                const Text('Mis observaciones:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _obsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Notas técnicas, aspectos a trabajar…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardarObservaciones,
                    icon: _guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.textOnPrimary))
                        : const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila que muestra los disparos y el total de una serie.
class _FilaSerie extends StatelessWidget {
  final Serie serie;
  const _FilaSerie({required this.serie});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          // Número de serie
          SizedBox(
            width: 24,
            child: Text(
              '${serie.numSerie}.',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ),
          // Puntuaciones individuales
          Expanded(
            child: Wrap(
              spacing: 6,
              children: serie.disparos
                  .map((d) => _ChipDisparo(puntuacion: d))
                  .toList(),
            ),
          ),
          // Total de la serie
          Text(
            serie.total.toStringAsFixed(1),
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

/// Chip pequeño que muestra la puntuación de un disparo.
/// El color varía según si el disparo es bueno (≥9), regular o bajo.
class _ChipDisparo extends StatelessWidget {
  final double puntuacion;
  const _ChipDisparo({required this.puntuacion});

  @override
  Widget build(BuildContext context) {
    final color = puntuacion >= 9.5
        ? AppColors.success
        : puntuacion >= 8.0
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        puntuacion.toStringAsFixed(1),
        style: AppTextStyles.chipLabel.copyWith(color: color),
      ),
    );
  }
}
