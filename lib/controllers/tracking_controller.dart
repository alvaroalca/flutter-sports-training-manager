/// Controller del módulo de tracking (ejecución de entrenamientos).
///
/// Implementa la máquina de estados del temporizador de tiro olímpico.
/// El ciclo de cada disparo tiene dos fases secuenciales:
///
///   [FaseEjercicio.preparacion] → cuenta atrás del tiempo de preparación
///   [FaseEjercicio.apuntado]    → cuenta atrás del tiempo de apuntado
///   [FaseEjercicio.registro]    → el atleta introduce la puntuación del disparo
///
/// Este ciclo se repite [numDisparos] veces por serie y [repeticiones] series.
/// Al finalizar todos los disparos de todas las series, pasa a [FaseEjercicio.completado]
/// y persiste el [Resultado] en Firestore mediante [FirestoreService].
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tfg/models/ejercicio.dart';
import 'package:tfg/models/resultado.dart';
import 'package:tfg/services/firestore_service.dart';

/// Fases del ciclo de vida del temporizador durante la ejecución de un ejercicio.
enum FaseEjercicio {
  /// El ejercicio no ha comenzado aún.
  idle,

  /// Cuenta atrás del tiempo de preparación antes de apuntar.
  preparacion,

  /// Cuenta atrás del tiempo de apuntado para realizar el disparo.
  apuntado,

  /// Tiempo de disparar ha expirado: el atleta introduce la puntuación obtenida.
  registro,

  /// Todos los disparos y series han finalizado.
  completado,
}

class TrackingController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // ── Estado del ejercicio actual ────────────────
  /// Ejercicio que se está ejecutando actualmente.
  Ejercicio? _ejercicio;
  Ejercicio? get ejercicio => _ejercicio;

  /// Fase actual del ciclo del temporizador.
  FaseEjercicio _fase = FaseEjercicio.idle;
  FaseEjercicio get fase => _fase;

  /// Segundos restantes en la cuenta atrás actual.
  int _segundosRestantes = 0;
  int get segundosRestantes => _segundosRestantes;

  /// Serie en curso (empieza en 1).
  int _serieActual = 1;
  int get serieActual => _serieActual;

  /// Número de disparo en curso dentro de la serie actual (empieza en 1).
  int _disparoActual = 1;
  int get disparoActual => _disparoActual;

  // ── Resultados acumulados ──────────────────────
  /// Puntuaciones de la serie en curso, se vacía al pasar a la siguiente serie.
  final List<double> _disparosSerie = [];

  /// Todas las series completadas del ejercicio.
  final List<Serie> _seriesCompletadas = [];
  List<Serie> get seriesCompletadas => List.unmodifiable(_seriesCompletadas);

  // ── Contexto de sesión ─────────────────────────
  String? _atletaId;
  String? _entrenadorId;
  String? _entrenamientoId;
  String? _ejercicioId;

  /// true mientras se persiste el resultado en Firestore.
  bool _guardando = false;
  bool get guardando => _guardando;

  /// Mensaje de error, o null si no hay error.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Timer interno para la cuenta atrás.
  Timer? _timer;

  // ─────────────────────────────────────────────
  // API pública
  // ─────────────────────────────────────────────

  /// Inicializa el tracking con el ejercicio y el contexto de sesión.
  ///
  /// Debe llamarse antes de [iniciar]. Resetea cualquier estado previo.
  void cargarEjercicio({
    required Ejercicio ejercicio,
    required String atletaId,
    required String entrenadorId,
    required String entrenamientoId,
  }) {
    _cancelarTimer();
    _ejercicio = ejercicio;
    _atletaId = atletaId;
    _entrenadorId = entrenadorId;
    _entrenamientoId = entrenamientoId;
    _ejercicioId = ejercicio.id;
    _fase = FaseEjercicio.idle;
    _serieActual = 1;
    _disparoActual = 1;
    _disparosSerie.clear();
    _seriesCompletadas.clear();
    _errorMessage = null;
    notifyListeners();
  }

  /// Inicia la cuenta atrás de preparación del primer disparo.
  void iniciar() {
    if (_ejercicio == null || _fase != FaseEjercicio.idle) return;
    _iniciarFasePreparacion();
  }

  /// Registra la puntuación del disparo actual y avanza al siguiente ciclo.
  ///
  /// [puntuacion] debe estar entre 0.0 y 10.9.
  /// Solo tiene efecto cuando [fase] == [FaseEjercicio.registro].
  void registrarDisparo(double puntuacion) {
    if (_fase != FaseEjercicio.registro) return;

    _disparosSerie.add(puntuacion);

    final ejercicio = _ejercicio!;
    final esUltimoDisparoSerie = _disparoActual >= ejercicio.numDisparos;
    final esUltimaSerie = _serieActual >= ejercicio.repeticiones;

    if (esUltimoDisparoSerie) {
      // Guardar la serie completada
      _seriesCompletadas.add(Serie(
        numSerie: _serieActual,
        disparos: List.from(_disparosSerie),
      ));
      _disparosSerie.clear();

      if (esUltimaSerie) {
        // Ejercicio completado
        _fase = FaseEjercicio.completado;
        notifyListeners();
        return;
      }

      // Pasar a la siguiente serie
      _serieActual++;
      _disparoActual = 1;
    } else {
      // Siguiente disparo dentro de la misma serie
      _disparoActual++;
    }

    // Continuar con el ciclo del siguiente disparo
    _iniciarFasePreparacion();
  }

  /// Guarda el resultado completo del ejercicio en Firestore.
  ///
  /// Solo tiene efecto cuando [fase] == [FaseEjercicio.completado].
  /// Devuelve el ID del resultado guardado, o null si falla.
  Future<String?> guardarResultado({String? observacionesAtleta}) async {
    if (_fase != FaseEjercicio.completado) return null;

    _guardando = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final resultado = Resultado(
        id: '',
        entrenamientoId: _entrenamientoId!,
        atletaId: _atletaId!,
        entrenadorId: _entrenadorId!,
        ejercicioId: _ejercicioId!,
        fecha: DateTime.now(),
        series: List.from(_seriesCompletadas),
        observacionesAtleta: observacionesAtleta,
      );
      return await _firestoreService.guardarResultado(resultado);
    } catch (_) {
      _errorMessage = 'No se pudo guardar el resultado. Inténtalo de nuevo.';
      return null;
    } finally {
      _guardando = false;
      notifyListeners();
    }
  }

  /// Libera los recursos del controller al destruir el widget.
  @override
  void dispose() {
    _cancelarTimer();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Máquina de estados interna
  // ─────────────────────────────────────────────

  /// Inicia la fase de preparación: cuenta atrás de [tiempoPreparacion] segundos.
  void _iniciarFasePreparacion() {
    _fase = FaseEjercicio.preparacion;
    _segundosRestantes = _ejercicio!.tiempoPreparacion;
    notifyListeners();
    _iniciarTimer(_finalizarPreparacion);
  }

  /// Inicia la fase de apuntado: cuenta atrás de [tiempoApuntado] segundos.
  void _iniciarFaseApuntado() {
    _fase = FaseEjercicio.apuntado;
    _segundosRestantes = _ejercicio!.tiempoApuntado;
    notifyListeners();
    _iniciarTimer(_finalizarApuntado);
  }

  /// Callback al terminar la fase de preparación: pasa a apuntado.
  void _finalizarPreparacion() {
    _iniciarFaseApuntado();
  }

  /// Callback al terminar la fase de apuntado: pasa a registro de puntuación.
  void _finalizarApuntado() {
    _cancelarTimer();
    _fase = FaseEjercicio.registro;
    notifyListeners();
  }

  /// Arranca un Timer.periodic de 1 segundo que decrementa [_segundosRestantes].
  ///
  /// Cuando llega a 0 cancela el timer y llama a [onComplete].
  void _iniciarTimer(VoidCallback onComplete) {
    _cancelarTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        _segundosRestantes--;
        notifyListeners();
      } else {
        timer.cancel();
        onComplete();
      }
    });
  }

  /// Cancela el timer activo si lo hay.
  void _cancelarTimer() {
    _timer?.cancel();
    _timer = null;
  }
}
