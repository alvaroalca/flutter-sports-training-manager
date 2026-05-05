/// Pantalla de detalle de un entrenamiento.
///
/// Muestra el nombre, descripción, fecha programada y la lista ordenada
/// de ejercicios con sus parámetros de temporización.
///
/// Para el modo atleta, ofrece el botón "Iniciar entrenamiento" que
/// navega a la pantalla de tracking con el primer ejercicio.
/// Para el modo entrenador, muestra la información de solo lectura.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/controllers/entrenamiento_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/constants/app_routes.dart';
import 'package:tfg/models/ejercicio.dart';
import 'package:tfg/models/entrenamiento.dart';
import 'package:tfg/shared/widgets/app_scaffold.dart';

class DetalleEntrenamientoView extends StatefulWidget {
  /// ID del entrenamiento a mostrar, recibido como parámetro de ruta.
  final String entrenamientoId;

  const DetalleEntrenamientoView({super.key, required this.entrenamientoId});

  @override
  State<DetalleEntrenamientoView> createState() =>
      _DetalleEntrenamientoViewState();
}

class _DetalleEntrenamientoViewState extends State<DetalleEntrenamientoView> {
  Entrenamiento? _entrenamiento;
  List<Ejercicio> _ejercicios = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Carga el entrenamiento y sus ejercicios desde Firestore.
  Future<void> _cargar() async {
    final resultado = await context
        .read<EntrenamientoController>()
        .cargarEntrenamientoConEjercicios(widget.entrenamientoId);

    setState(() {
      _cargando = false;
      if (resultado != null) {
        // Los record patterns solo funcionan con variables locales;
        // se desestructura primero en locales y luego se asigna a los campos.
        final (ent, ejs) = resultado;
        _entrenamiento = ent;
        _ejercicios = ejs;
      } else {
        _error = 'No se pudo cargar el entrenamiento.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const AppScaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _entrenamiento == null) {
      return AppScaffold(
        title: 'Detalle',
        body: Center(child: Text(_error ?? 'Error desconocido')),
      );
    }

    final entrenamiento = _entrenamiento!;
    final esAtleta =
        context.read<AuthController>().modoVista == ModoVista.atleta;

    return AppScaffold(
      title: entrenamiento.nombre,
      // Botón "Iniciar" visible solo para el atleta si hay ejercicios — se incluye al final del body
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Descripción ────────────────────────────
          Text(
            entrenamiento.descripcion,
            style: const TextStyle(
                fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          // ── Fecha programada ───────────────────────
          if (entrenamiento.fechaProgramada != null) ...[
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Programado: ${_formatFecha(entrenamiento.fechaProgramada!)}',
                  style:
                      const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // ── Resumen ────────────────────────────────
          _ResumenChips(ejercicios: _ejercicios),
          const SizedBox(height: 20),
          const Divider(),

          // ── Lista de ejercicios ────────────────────
          Text(
            'Ejercicios (${_ejercicios.length})',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._ejercicios.asMap().entries.map(
                (entry) => _TarjetaEjercicio(
                  numero: entry.key + 1,
                  ejercicio: entry.value,
                ),
              ),

          // ── Acciones del atleta ──────────────────────
          if (esAtleta) ...[
            const SizedBox(height: 16),
            if (entrenamiento.estado == EstadoEntrenamiento.completado)
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Entrenamiento completado',
                          style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
            else ...[
              if (_ejercicios.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => context.push(
                    AppRoutes.tracking
                        .replaceFirst(':id', entrenamiento.id),
                  ),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar entrenamiento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              const SizedBox(height: 8),
              SafeArea(
                child: OutlinedButton.icon(
                  onPressed: _marcarComoTerminado,
                  icon: const Icon(Icons.check),
                  label: const Text('Marcar como terminado'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatFecha(DateTime fecha) =>
      '${fecha.day}/${fecha.month}/${fecha.year}';

  /// Pide confirmación y marca el entrenamiento como completado.
  Future<void> _marcarComoTerminado() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como terminado'),
        content: const Text(
            '¿Confirmas que has terminado este entrenamiento? Esto lo marcará como completado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    await context
        .read<EntrenamientoController>()
        .actualizarEstado(widget.entrenamientoId, EstadoEntrenamiento.completado);

    if (!mounted) return;
    setState(() {
      _entrenamiento = Entrenamiento(
        id: _entrenamiento!.id,
        nombre: _entrenamiento!.nombre,
        descripcion: _entrenamiento!.descripcion,
        entrenadorId: _entrenamiento!.entrenadorId,
        atletaId: _entrenamiento!.atletaId,
        ejerciciosIds: _entrenamiento!.ejerciciosIds,
        fechaCreacion: _entrenamiento!.fechaCreacion,
        fechaProgramada: _entrenamiento!.fechaProgramada,
        estado: EstadoEntrenamiento.completado,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Entrenamiento marcado como completado.'),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets internos
// ─────────────────────────────────────────────────────────────────────────────

/// Fila de chips con el resumen numérico del entrenamiento completo.
class _ResumenChips extends StatelessWidget {
  final List<Ejercicio> ejercicios;
  const _ResumenChips({required this.ejercicios});

  @override
  Widget build(BuildContext context) {
    final totalDisparos = ejercicios.fold(
        0, (acc, e) => acc + e.numDisparos * e.repeticiones);
    final totalMin = ejercicios.fold(
            0, (acc, e) => acc + e.duracionEstimadaTotal) ~/
        60;

    return Wrap(
      spacing: 8,
      children: [
        _Chip(Icons.fitness_center, '${ejercicios.length} ejercicios'),
        _Chip(Icons.gps_fixed, '$totalDisparos disparos'),
        _Chip(Icons.timer, '≈ $totalMin min'),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.primaryLightAlpha15,
      side: const BorderSide(color: AppColors.primaryAlpha30),
    );
  }
}

/// Tarjeta expandible con los detalles de temporización de un ejercicio.
class _TarjetaEjercicio extends StatelessWidget {
  final int numero;
  final Ejercicio ejercicio;
  const _TarjetaEjercicio(
      {required this.numero, required this.ejercicio});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Text('$numero',
              style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 13)),
        ),
        title: Text(ejercicio.nombre,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${ejercicio.numDisparos} disparos × ${ejercicio.repeticiones} series',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ejercicio.descripcion,
                    style: const TextStyle(
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                // Fila con los tiempos de cada fase
                Row(
                  children: [
                    _InfoTiempo('Preparación',
                        '${ejercicio.tiempoPreparacion}s', Icons.hourglass_top),
                    const SizedBox(width: 16),
                    _InfoTiempo('Apuntado',
                        '${ejercicio.tiempoApuntado}s', Icons.gps_fixed),
                    const SizedBox(width: 16),
                    _InfoTiempo('Total',
                        '≈ ${ejercicio.duracionEstimadaTotal ~/ 60}min',
                        Icons.timer),
                  ],
                ),
                if (ejercicio.notas != null) ...[
                  const SizedBox(height: 8),
                  Text('📝 ${ejercicio.notas}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pequeño bloque de información de temporización.
class _InfoTiempo extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  const _InfoTiempo(this.label, this.valor, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 2),
        Text(valor,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}
