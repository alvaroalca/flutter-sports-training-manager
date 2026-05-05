/// Controller de grupos de entrenamiento.
///
/// Actúa como intermediario entre [FirestoreService] y las vistas de grupos.
/// Gestiona la creación de grupos, la adición de miembros por código de usuario,
/// las solicitudes de ingreso y su resolución por parte del entrenador.
import 'package:flutter/foundation.dart';
import 'package:tfg/models/grupo.dart';
import 'package:tfg/models/solicitud_grupo.dart';
import 'package:tfg/models/usuario.dart';
import 'package:tfg/services/firestore_service.dart';
import 'package:tfg/services/storage_service.dart';

class GruposController extends ChangeNotifier {
  final FirestoreService _service = FirestoreService();
  final StorageService _storage = StorageService();
  static final RegExp _codigoRegex = RegExp(r'^#\d{6}$');

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ─────────────────────────────────────────────
  // Consultas de lectura directa
  // ─────────────────────────────────────────────

  /// Recupera un grupo por su ID (lectura puntual, no stream).
  Future<Grupo?> obtenerGrupo(String grupoId) =>
      _service.obtenerGrupo(grupoId);

  // ─────────────────────────────────────────────
  // Streams (delegados al servicio)
  // ─────────────────────────────────────────────

  /// Stream con los grupos creados por el entrenador, en tiempo real.
  Stream<List<Grupo>> gruposPorEntrenador(String entrenadorId) =>
      _service.gruposPorEntrenador(entrenadorId);

  /// Stream con los grupos en los que el atleta es miembro, en tiempo real.
  Stream<List<Grupo>> gruposDelAtleta(String atletaId) =>
      _service.gruposDelAtleta(atletaId);

  /// Stream con las solicitudes pendientes de un grupo, en tiempo real.
  Stream<List<SolicitudGrupo>> solicitudesPendientes(String grupoId) =>
      _service.solicitudesPendientesPorGrupo(grupoId);

  // ─────────────────────────────────────────────
  // Operaciones del entrenador
  // ─────────────────────────────────────────────

  /// Crea un nuevo grupo de entrenamiento y le asigna su código único.
  ///
  /// Devuelve el ID del grupo creado, o null si hubo un error.
  Future<String?> crearGrupo({
    required String nombre,
    required String descripcion,
    required String entrenadorId,
  }) async {
    if (nombre.trim().isEmpty) {
      _errorMessage = 'Introduce un nombre para el grupo.';
      return null;
    }
    _setLoading(true);
    _clearError();
    try {
      final grupo = Grupo(
        id: '',
        nombre: nombre.trim(),
        descripcion: descripcion.trim(),
        entrenadorId: entrenadorId,
        codigoGrupo: '',
        fechaCreacion: DateTime.now(),
        miembrosIds: [],
      );
      final grupoId = await _service.crearGrupo(grupo);
      await _service.asignarCodigoGrupo(grupoId);
      return grupoId;
    } catch (_) {
      _errorMessage = 'No se pudo crear el grupo. Inténtalo de nuevo.';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Busca un atleta por su código de usuario y lo añade al grupo.
  ///
  /// Devuelve null si se añadió correctamente, o un mensaje de error.
  Future<String?> agregarAtletaPorCodigo({
    required String codigoUsuario,
    required String grupoId,
  }) async {
    _clearError();
    try {
      final codigo = codigoUsuario.trim().toUpperCase();
      if (!_codigoRegex.hasMatch(codigo)) {
        return 'Código de atleta inválido. Usa el formato #000001.';
      }
      final atleta = await _service.buscarUsuarioPorCodigo(codigo);
      if (atleta == null) {
        return 'No existe ningún usuario con el código $codigo.';
      }

      // Verificar que no sea ya miembro
      final grupo = await _service.obtenerGrupo(grupoId);
      if (grupo == null) return 'Grupo no encontrado.';
      if (grupo.miembrosIds.contains(atleta.uid)) {
        return '${atleta.nombreCompleto} ya es miembro de este grupo.';
      }

      await _service.agregarMiembroAlGrupo(grupoId, atleta.uid);
      return null;
    } catch (_) {
      return 'Error al añadir el atleta. Inténtalo de nuevo.';
    }
  }

  /// Elimina un atleta del grupo.
  Future<bool> eliminarMiembro({
    required String grupoId,
    required String atletaUid,
  }) async {
    try {
      await _service.eliminarMiembroDelGrupo(grupoId, atletaUid);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Aprueba o rechaza una solicitud de ingreso al grupo.
  ///
  /// Si [aprobada] es true, el atleta pasa a ser miembro.
  Future<bool> resolverSolicitud({
    required String solicitudId,
    required String grupoId,
    required String atletaId,
    required bool aprobada,
  }) async {
    try {
      await _service.resolverSolicitud(
        solicitudId: solicitudId,
        grupoId: grupoId,
        atletaId: atletaId,
        aprobada: aprobada,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Operaciones del atleta
  // ─────────────────────────────────────────────

  /// Envía una solicitud de ingreso al grupo con el código indicado.
  ///
  /// Devuelve null si se envió correctamente, o un mensaje de error.
  Future<String?> solicitarUnirseAGrupo({
    required String codigoGrupo,
    required String atletaUid,
  }) async {
    _clearError();
    try {
      final codigo = codigoGrupo.trim().toUpperCase();
      if (!_codigoRegex.hasMatch(codigo)) {
        return 'Código de grupo inválido. Usa el formato #000001.';
      }
      final grupo = await _service.buscarGrupoPorCodigo(codigo);
      if (grupo == null) {
        return 'No existe ningún grupo con el código $codigo.';
      }
      if (grupo.miembrosIds.contains(atletaUid)) {
        return 'Ya eres miembro de este grupo.';
      }
      final yaTieneSolicitud =
          await _service.tieneSolicitudPendiente(grupo.id, atletaUid);
      if (yaTieneSolicitud) {
        return 'Ya tienes una solicitud pendiente para este grupo.';
      }

      final solicitud = SolicitudGrupo(
        id: '',
        grupoId: grupo.id,
        atletaId: atletaUid,
        estado: EstadoSolicitud.pendiente,
        fechaSolicitud: DateTime.now(),
      );
      await _service.crearSolicitud(solicitud);
      return null;
    } catch (e) {
      return 'Error al enviar la solicitud: ${e.toString()}';
    }
  }

  // ─────────────────────────────────────────────
  // Fotos de grupo
  // ─────────────────────────────────────────────

  /// Sube una foto de portada para el grupo y actualiza el documento en Firestore.
  ///
  /// [grupoId]   → ID del grupo al que pertenece la foto.
  /// [bytes]     → bytes de la imagen seleccionada.
  /// [extension] → extensión del archivo ('jpg', 'png', etc.).
  ///
  /// Devuelve la URL pública de la imagen, o null si hubo un error.
  Future<String?> subirFotoGrupo({
    required String grupoId,
    required Uint8List bytes,
    required String extension,
  }) async {
    try {
      final url = await _storage.subirFotoGrupo(grupoId, bytes, extension);
      await _service.actualizarFotoGrupo(grupoId, url);
      return url;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // Consultas auxiliares
  // ─────────────────────────────────────────────

  /// Carga los objetos [Usuario] para una lista de UIDs.
  ///
  /// Útil para mostrar nombres de miembros en la vista de detalle.
  Future<List<Usuario>> cargarUsuarios(List<String> uids) async {
    final futures = uids.map((uid) => _service.obtenerUsuario(uid));
    final resultados = await Future.wait(futures);
    return resultados.whereType<Usuario>().toList();
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
