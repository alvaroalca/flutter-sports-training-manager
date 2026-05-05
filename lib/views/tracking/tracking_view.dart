/// Pantalla de ejecución de un entrenamiento en tiempo real.
///
/// Guía al atleta a través de cada ejercicio mostrando:
///   - Cuenta atrás visual de la fase actual (preparación / apuntado).
///   - Indicador de serie y disparo actuales.
///   - Formulario para introducir la puntuación tras cada disparo.
///   - Resumen de series completadas al finalizar.
///
/// Al completar todos los disparos ofrece guardar el resultado en Firestore
/// con observaciones opcionales del atleta.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tfg/controllers/auth_controller.dart';
import 'package:tfg/controllers/entrenamiento_controller.dart';
import 'package:tfg/controllers/tracking_controller.dart';
import 'package:tfg/core/theme/app_colors.dart';
import 'package:tfg/core/theme/app_text_styles.dart';
import 'package:tfg/models/ejercicio.dart';
import 'package:tfg/models/entrenamiento.dart';

class TrackingView extends StatefulWidget {
  /// ID del entrenamiento que se va a ejecutar, recibido como parámetro de ruta.
  final String entrenamientoId;

  const TrackingView({super.key, required this.entrenamientoId});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  Entrenamiento? _entrenamiento;
  List<Ejercicio> _ejercicios = [];

  /// Índice del ejercicio que se está ejecutando actualmente.
  int _ejercicioIndex = 0;

  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final resultado = await context
        .read<EntrenamientoController>()
        .cargarEntrenamientoConEjercicios(widget.entrenamientoId);

    if (!mounted) return;

    setState(() {
      _cargando = false;
      if (resultado != null) {
        final (ent, ejs) = resultado;
        _entrenamiento = ent;
        _ejercicios = ejs;
        // Cargar el primer ejercicio en el TrackingController
        if (ejs.isNotEmpty) {
          context.read<TrackingController>().cargarEjercicio(
                ejercicio: ejs[0],
                atletaId: context.read<AuthController>().usuario!.uid,
                entrenamientoId: widget.entrenamientoId,
              );
        }
      } else {
        _error = 'No se pudo cargar el entrenamiento.';
      }
    });
  }

  /// Carga el siguiente ejercicio de la lista en el TrackingController.
  void _cargarSiguienteEjercicio() {
    final siguiente = _ejercicioIndex + 1;
    if (siguiente >= _ejercicios.length) return;

    setState(() => _ejercicioIndex = siguiente);
    context.read<TrackingController>().cargarEjercicio(
          ejercicio: _ejercicios[siguiente],
          atletaId: context.read<AuthController>().usuario!.uid,
          entrenamientoId: widget.entrenamientoId,
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(_error!)),
      );
    }

    final trackCtrl = context.watch<TrackingController>();
    final ejercicio = trackCtrl.ejercicio;

    return Scaffold(
      appBar: AppBar(
        title: Text(_entrenamiento?.nombre ?? 'Entrenamiento'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        // Confirmación antes de salir para evitar pérdida de datos
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _confirmarSalida(context),
        ),
      ),
      body: ejercicio == null
          ? const Center(child: Text('Sin ejercicios disponibles.'))
          : _buildContenido(context, trackCtrl, ejercicio),
    );
  }

  Widget _buildContenido(
      BuildContext context, TrackingController ctrl, Ejercicio ejercicio) {
    return switch (ctrl.fase) {
      FaseEjercicio.idle => _PantallaInicio(
          ejercicio: ejercicio,
          numeroEjercicio: _ejercicioIndex + 1,
          totalEjercicios: _ejercicios.length,
          onIniciar: ctrl.iniciar,
        ),
      FaseEjercicio.preparacion || FaseEjercicio.apuntado => _PantallaTemporizador(
          ctrl: ctrl,
          ejercicio: ejercicio,
        ),
      FaseEjercicio.registro => _PantallaRegistro(
          ctrl: ctrl,
          ejercicio: ejercicio,
        ),
      FaseEjercicio.completado => _PantallaCompletado(
          ctrl: ctrl,
          entrenamientoId: widget.entrenamientoId,
          hayMasEjercicios: _ejercicioIndex + 1 < _ejercicios.length,
          onSiguienteEjercicio: _cargarSiguienteEjercicio,
        ),
    };
  }

  /// Muestra un diálogo de confirmación antes de abandonar el entrenamiento.
  void _confirmarSalida(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Salir del entrenamiento?'),
        content: const Text(
            'Se perderá el progreso no guardado del ejercicio actual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pantallas de cada fase
// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla inicial antes de empezar el ejercicio.
/// Muestra un resumen del ejercicio y el botón para iniciar.
class _PantallaInicio extends StatelessWidget {
  final Ejercicio ejercicio;
  final int numeroEjercicio;
  final int totalEjercicios;
  final VoidCallback onIniciar;

  const _PantallaInicio({
    required this.ejercicio,
    required this.numeroEjercicio,
    required this.totalEjercicios,
    required this.onIniciar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ejercicio $numeroEjercicio / $totalEjercicios',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            ejercicio.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            ejercicio.descripcion,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          // Resumen de parámetros
          _FilaParametro('Disparos por serie', '${ejercicio.numDisparos}'),
          _FilaParametro('Series', '${ejercicio.repeticiones}'),
          _FilaParametro('Preparación', '${ejercicio.tiempoPreparacion}s'),
          _FilaParametro('Apuntado', '${ejercicio.tiempoApuntado}s'),
          if (ejercicio.notas != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '📝 ${ejercicio.notas}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: onIniciar,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar ejercicio',
                style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaParametro extends StatelessWidget {
  final String label;
  final String valor;
  const _FilaParametro(this.label, this.valor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          Text(valor,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla del temporizador (preparación o apuntado).
///
/// Muestra la cuenta atrás en grande con el color de la fase actual y
/// los indicadores de progreso (serie, disparo).
class _PantallaTemporizador extends StatelessWidget {
  final TrackingController ctrl;
  final Ejercicio ejercicio;

  const _PantallaTemporizador(
      {required this.ctrl, required this.ejercicio});

  @override
  Widget build(BuildContext context) {
    final esPreparacion = ctrl.fase == FaseEjercicio.preparacion;
    final color = esPreparacion ? AppColors.primary : AppColors.error;
    final label = esPreparacion ? 'PREPARACIÓN' : 'APUNTA';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Indicador de progreso: serie y disparo
          Text(
            'Serie ${ctrl.serieActual}/${ejercicio.repeticiones}  ·  Disparo ${ctrl.disparoActual}/${ejercicio.numDisparos}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),

          // Etiqueta de fase
          Text(
            label,
            style: AppTextStyles.timerLabel.copyWith(color: color),
          ),
          const SizedBox(height: 16),

          // Cuenta atrás principal
          Text(
            '${ctrl.segundosRestantes}',
            style: AppTextStyles.timerDisplay.copyWith(color: color),
          ),
          const SizedBox(height: 8),
          Text(
            'segundos',
            style: AppTextStyles.bodyLarge.copyWith(
                color: color.withValues(alpha: 0.7)),
          ),

          const SizedBox(height: 60),

          // Barra de progreso
          _BarraProgreso(
            ctrl: ctrl,
            ejercicio: ejercicio,
          ),
        ],
      ),
    );
  }
}

/// Barra de progreso que muestra disparos completados en la serie actual.
class _BarraProgreso extends StatelessWidget {
  final TrackingController ctrl;
  final Ejercicio ejercicio;

  const _BarraProgreso({required this.ctrl, required this.ejercicio});

  @override
  Widget build(BuildContext context) {
    // Tamaño y espaciado se reducen cuando hay muchos disparos para que quepan
    // varias filas sin saturar la pantalla (p.ej. ejercicios de 50 disparos/serie).
    final muchos = ejercicio.numDisparos > 20;
    final size = muchos ? 10.0 : 16.0;
    final spacing = muchos ? 4.0 : 8.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(
          ejercicio.numDisparos,
          (i) => Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < ctrl.disparoActual - 1
                  ? AppColors.success
                  : i == ctrl.disparoActual - 1
                      ? AppColors.primary
                      : Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla de registro de puntuación tras el disparo.
class _PantallaRegistro extends StatefulWidget {
  final TrackingController ctrl;
  final Ejercicio ejercicio;

  const _PantallaRegistro({required this.ctrl, required this.ejercicio});

  @override
  State<_PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<_PantallaRegistro> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) return;
    final puntuacion = double.parse(_ctrl.text.replaceAll(',', '.'));
    widget.ctrl.registrarDisparo(puntuacion);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.gps_fixed, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Serie ${widget.ctrl.serieActual}/${widget.ejercicio.repeticiones}  ·  Disparo ${widget.ctrl.disparoActual}/${widget.ejercicio.numDisparos}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Introduce la puntuación',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),

          // Campo de puntuación
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '0.0',
                border: OutlineInputBorder(),
                suffixText: 'pts',
              ),
              onFieldSubmitted: (_) => _confirmar(),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Introduce la puntuación';
                final n = double.tryParse(v.replaceAll(',', '.'));
                if (n == null) return 'Número no válido';
                if (n < 0 || n > 10.9) return 'Entre 0 y 10.9';
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _confirmar,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Confirmar disparo',
                style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Pantalla de resumen al completar todos los disparos del ejercicio.
/// Muestra la puntuación total, la media y las series registradas.
class _PantallaCompletado extends StatefulWidget {
  final TrackingController ctrl;
  final String entrenamientoId;
  final bool hayMasEjercicios;
  final VoidCallback onSiguienteEjercicio;

  const _PantallaCompletado({
    required this.ctrl,
    required this.entrenamientoId,
    required this.hayMasEjercicios,
    required this.onSiguienteEjercicio,
  });

  @override
  State<_PantallaCompletado> createState() => _PantallaCompletadoState();
}

class _PantallaCompletadoState extends State<_PantallaCompletado> {
  final _obsCtrl = TextEditingController();
  bool _guardado = false;

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final id = await widget.ctrl.guardarResultado(
      observacionesAtleta:
          _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
    );
    if (id != null && mounted) {
      setState(() => _guardado = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final series = widget.ctrl.seriesCompletadas;
    // Cálculo de totales para mostrar en el resumen
    final totalPuntos = series.fold(0.0, (acc, s) => acc + s.total);
    final totalDisparos = series.fold(0, (acc, s) => acc + s.numDisparos);
    final media = totalDisparos > 0 ? totalPuntos / totalDisparos : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Encabezado ─────────────────────────────
          const Icon(Icons.check_circle_outline,
              size: 64, color: AppColors.success),
          const SizedBox(height: 12),
          const Text(
            '¡Ejercicio completado!',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // ── Resumen de puntuación ──────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBox('Total', totalPuntos.toStringAsFixed(1), 'pts'),
              _StatBox('Media', media.toStringAsFixed(2), 'pts/disp'),
              _StatBox('Disparos', '$totalDisparos', ''),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),

          // ── Detalle por series ─────────────────────
          const Text('Detalle por series',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          ...series.map((s) => _FilaSerie(serie: s)),
          const SizedBox(height: 16),

          // ── Observaciones del atleta ───────────────
          if (!_guardado) ...[
            TextField(
              controller: _obsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                hintText: 'Sensaciones, aspectos a mejorar…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.ctrl.guardando ? null : _guardar,
              icon: widget.ctrl.guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: const Text('Guardar resultado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ] else
            // Confirmación de guardado exitoso
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  SizedBox(width: 8),
                  Text('Resultado guardado',
                      style: TextStyle(color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // ── Navegación ─────────────────────────────
          if (widget.hayMasEjercicios)
            OutlinedButton.icon(
              onPressed: widget.onSiguienteEjercicio,
              icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
              label: const Text('Siguiente ejercicio',
                  style: TextStyle(color: AppColors.primary)),
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Volver al entrenamiento'),
          ),
        ],
      ),
    );
  }
}

/// Caja de estadística para el resumen final.
class _StatBox extends StatelessWidget {
  final String titulo;
  final String valor;
  final String unidad;

  const _StatBox(this.titulo, this.valor, this.unidad);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold,
                color: AppColors.primary)),
        if (unidad.isNotEmpty)
          Text(unidad,
              style: AppTextStyles.caption),
        Text(titulo,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Fila con el resumen de una serie: número, disparos y total.
class _FilaSerie extends StatelessWidget {
  // Serie tipada con dynamic para evitar importar el modelo en este widget
  // ya que el acceso a sus campos se hace directamente en el build.
  final dynamic serie;
  const _FilaSerie({required this.serie});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primary,
              child: Text('${serie.numSerie}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                serie.disparos
                    .map((d) => d.toStringAsFixed(1))
                    .join('  '),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Text(
              serie.total.toStringAsFixed(1),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
