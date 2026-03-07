/// Controller del panel del entrenador.
///
/// Centraliza la lógica para:
///   - Obtener la lista de atletas vinculados al entrenador.
///   - Cargar el perfil completo de un atleta (datos [Usuario] + [Atleta]).
///   - Obtener el historial de resultados de un atleta para visualizar su evolución.
///   - Añadir observaciones del entrenador a un resultado existente.
///
/// Se expone mediante [ChangeNotifier] para que los widgets suscritos
/// se reconstruyan automáticamente cuando cambia el estado.
import 'package:flutter/foundation.dart';
import 'package:tfg/models/atleta.dart';
import 'package:tfg/models/resultado.dart';
import 'package:tfg/models/usuario.dart';
import 'package:tfg/services/firestore_service.dart';

/// Agrupa los datos de un atleta vinculado: datos de perfil ([Usuario])
/// y datos específicos de tiro ([Atleta]).
class AtletaConPerfil {
  final Usuario usuario;
  final Atleta atleta;

  const AtletaConPerfil({required this.usuario, required this.atleta});
}

class CoachController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  /// Indica si hay una operación asíncrona en curso.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Mensaje del último error producido, o null si no hay error activo.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ─────────────────────────────────────────────
  // STREAMS
  // ─────────────────────────────────────────────

  /// Stream con los documentos [Atleta] vinculados al entrenador en tiempo real.
  ///
  /// La UI lo usa para mantener la lista actualizada sin necesidad de recargar.
  Stream<List<Atleta>> atletasPorEntrenador(String entrenadorId) =>
      _firestoreService.atletasPorEntrenador(entrenadorId);

  /// Stream con el historial de resultados de un atleta, ordenados por fecha.
  ///
  /// Permite al entrenador ver la evolución del atleta en tiempo real.
  Stream<List<Resultado>> resultadosPorAtleta(String atletaId) =>
      _firestoreService.resultadosPorAtleta(atletaId);

  // ─────────────────────────────────────────────
  // OPERACIONES ASÍNCRONAS
  // ─────────────────────────────────────────────

  /// Carga el perfil completo de una lista de atletas.
  ///
  /// Para cada [Atleta] obtiene también su [Usuario] correspondiente,
  /// agrupando ambos en [AtletaConPerfil] para mostrar nombre y datos de tiro.
  Future<List<AtletaConPerfil>> cargarPerfilesAtletas(
      List<Atleta> atletas) async {
    _setLoading(true);
    _clearError();
    try {
      final perfiles = <AtletaConPerfil>[];
      for (final atleta in atletas) {
        final usuario = await _firestoreService.obtenerUsuario(atleta.uid);
        if (usuario != null) {
          perfiles.add(AtletaConPerfil(usuario: usuario, atleta: atleta));
        }
      }
      return perfiles;
    } catch (_) {
      _errorMessage = 'No se pudieron cargar los perfiles de los atletas.';
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Carga el perfil completo de un atleta individual por su UID.
  ///
  /// Devuelve null si el atleta o el usuario no se encuentran en Firestore.
  Future<AtletaConPerfil?> cargarPerfilAtleta(String atletaId) async {
    _setLoading(true);
    _clearError();
    try {
      final usuario = await _firestoreService.obtenerUsuario(atletaId);
      final atleta = await _firestoreService.obtenerAtleta(atletaId);
      if (usuario == null || atleta == null) return null;
      return AtletaConPerfil(usuario: usuario, atleta: atleta);
    } catch (_) {
      _errorMessage = 'No se pudo cargar el perfil del atleta.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Añade o actualiza las observaciones del entrenador en un resultado.
  ///
  /// Devuelve true si la operación tuvo éxito.
  Future<bool> guardarObservaciones(
      String resultadoId, String observaciones) async {
    _clearError();
    try {
      await _firestoreService.actualizarObservacionesEntrenador(
          resultadoId, observaciones);
      return true;
    } catch (_) {
      _errorMessage = 'No se pudieron guardar las observaciones.';
      notifyListeners();
      return false;
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
