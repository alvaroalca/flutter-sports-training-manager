/// Controller que gestiona la lógica de negocio de los entrenamientos.
///
/// Expone streams en tiempo real de Firestore para que la UI reaccione
/// automáticamente a los cambios, y métodos para crear, asignar y
/// actualizar el estado de los entrenamientos.
///
/// Se registra en [MultiProvider] de [app.dart] y es accesible desde
/// cualquier widget del árbol mediante [context.read] o [context.watch].
import 'package:flutter/foundation.dart';
import 'package:tfg/models/ejercicio.dart';
import 'package:tfg/models/entrenamiento.dart';
import 'package:tfg/services/firestore_service.dart';

class EntrenamientoController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  /// Indica si hay una operación asíncrona en curso (crear, actualizar…).
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Mensaje del último error producido, o null si no hay error activo.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ─────────────────────────────────────────────
  // STREAMS (tiempo real)
  // ─────────────────────────────────────────────

  /// Stream con los entrenamientos asignados a un atleta concreto.
  ///
  /// La UI se suscribe a este stream para mostrar siempre la lista actualizada.
  Stream<List<Entrenamiento>> entrenamientosPorAtleta(String atletaId) =>
      _firestoreService.entrenamientosPorAtleta(atletaId);

  /// Stream con las plantillas creadas por un entrenador.
  Stream<List<Entrenamiento>> plantillasPorEntrenador(String entrenadorId) =>
      _firestoreService.plantillasPorEntrenador(entrenadorId);

  /// Stream con los entrenamientos que un entrenador ha asignado a un atleta.
  Stream<List<Entrenamiento>> entrenamientosAsignadosAAtletaPorEntrenador({
    required String entrenadorId,
    required String atletaId,
  }) =>
      _firestoreService.entrenamientosAsignadosAAtletaPorEntrenador(
        entrenadorId: entrenadorId,
        atletaId: atletaId,
      );

  // ─────────────────────────────────────────────
  // OPERACIONES DE ESCRITURA
  // ─────────────────────────────────────────────

  /// Crea un nuevo entrenamiento o plantilla en Firestore.
  ///
  /// Si [atletaId] es null, se crea como plantilla reutilizable.
  /// Devuelve el ID del documento creado, o null si falla.
  Future<String?> crearEntrenamiento({
    required String nombre,
    required String descripcion,
    required String entrenadorId,
    required List<String> ejerciciosIds,
    String? atletaId,
    DateTime? fechaProgramada,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      final entrenamiento = Entrenamiento(
        id: '',
        nombre: nombre,
        descripcion: descripcion,
        entrenadorId: entrenadorId,
        atletaId: atletaId,
        ejerciciosIds: ejerciciosIds,
        fechaCreacion: DateTime.now(),
        fechaProgramada: fechaProgramada,
        estado: EstadoEntrenamiento.pendiente,
      );
      final id = await _firestoreService.crearEntrenamiento(entrenamiento);
      return id;
    } catch (_) {
      _errorMessage = 'No se pudo crear el entrenamiento. Inténtalo de nuevo.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Asigna las [plantillas] indicadas a cada uno de los [atletasIds].
  ///
  /// Crea una copia del entrenamiento por cada par (plantilla, atleta).
  /// Devuelve el número total de asignaciones creadas, o null si falla.
  Future<int?> asignarPlantillasAGrupo({
    required List<Entrenamiento> plantillas,
    required List<String> atletasIds,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      var total = 0;
      for (final p in plantillas) {
        total += await _firestoreService.asignarPlantillaAAtletas(
          plantilla: p,
          atletasIds: atletasIds,
        );
      }
      return total;
    } catch (e) {
      _errorMessage = 'Error al asignar entrenamientos: ${e.toString()}';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Actualiza el estado de un entrenamiento (ej. pendiente → completado).
  Future<void> actualizarEstado(
      String id, EstadoEntrenamiento estado) async {
    try {
      await _firestoreService.actualizarEstadoEntrenamiento(id, estado);
    } catch (_) {
      _errorMessage = 'No se pudo actualizar el estado del entrenamiento.';
      notifyListeners();
    }
  }

  /// Carga un entrenamiento por ID junto con todos sus ejercicios resueltos.
  ///
  /// Devuelve una tupla [Entrenamiento, List<Ejercicio>] para que la vista
  /// pueda mostrar todos los detalles sin realizar múltiples llamadas.
  Future<(Entrenamiento, List<Ejercicio>)?> cargarEntrenamientoConEjercicios(
      String entrenamientoId) async {
    _setLoading(true);
    _clearError();
    try {
      final entrenamiento =
          await _firestoreService.obtenerEntrenamiento(entrenamientoId);
      if (entrenamiento == null) return null;

      final ejercicios =
          await _firestoreService.obtenerEjercicios(entrenamiento.ejerciciosIds);
      return (entrenamiento, ejercicios);
    } catch (_) {
      _errorMessage = 'No se pudo cargar el entrenamiento.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────────
  // Utilidades privadas
  // ─────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
