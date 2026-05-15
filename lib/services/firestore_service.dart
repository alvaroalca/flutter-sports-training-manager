/// Servicio que centraliza todas las operaciones de lectura y escritura
/// contra Cloud Firestore.
///
/// Organiza las operaciones por entidad (usuarios, atletas, ejercicios,
/// entrenamientos y resultados), siguiendo la estructura de colecciones
/// definida en la base de datos:
///
///   usuarios/          → documentos [Usuario]
///   atletas/           → documentos [Atleta]
///   ejercicios/        → documentos [Ejercicio]
///   entrenamientos/    → documentos [Entrenamiento]
///   resultados/        → documentos [Resultado]
///
/// Este servicio es consumido por [AuthService] y por los controllers
/// de la capa de presentación a través de [Provider].
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tfg/models/usuario.dart';
import 'package:tfg/models/atleta.dart';
import 'package:tfg/models/ejercicio.dart';
import 'package:tfg/models/entrenamiento.dart';
import 'package:tfg/models/resultado.dart';
import 'package:tfg/models/recurso.dart';
import 'package:tfg/models/grupo.dart';
import 'package:tfg/models/solicitud_grupo.dart';

class FirestoreService {
  /// Instancia de Cloud Firestore.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // USUARIOS
  // ─────────────────────────────────────────────

  /// Crea el documento de un nuevo usuario en la colección 'usuarios'.
  ///
  /// Se llama automáticamente desde [AuthService.registrar] después de
  /// crear la cuenta en Firebase Auth.
  Future<void> crearUsuario(Usuario usuario) async {
    await _db
        .collection('usuarios')
        .doc(usuario.uid)
        .set(usuario.toMap());
  }

  /// Recupera el documento de un usuario por su UID.
  ///
  /// Devuelve null si el documento no existe en Firestore.
  Future<Usuario?> obtenerUsuario(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (!doc.exists) return null;
    return Usuario.fromMap(doc.data()!, doc.id);
  }

  /// Actualiza los campos de un usuario existente.
  ///
  /// Solo actualiza los campos presentes en [datos]; el resto permanece igual.
  Future<void> actualizarUsuario(String uid, Map<String, dynamic> datos) async {
    await _db.collection('usuarios').doc(uid).update(datos);
  }

  /// Guarda la URL de la foto de perfil en el documento del usuario.
  Future<void> actualizarFotoPerfil(String uid, String url) async {
    await _db.collection('usuarios').doc(uid).update({'fotoPerfil': url});
  }

  /// Asigna un código único (#000001) al usuario si todavía no tiene uno.
  ///
  /// Usa una transacción sobre el documento [contadores/codigos] para
  /// incrementar el contador de forma atómica y evitar duplicados.
  /// Devuelve el código asignado o el existente si ya tenía uno.
  Future<String> asignarCodigoUsuarioSiNoTiene(String uid) async {
    return _db.runTransaction((tx) async {
      final usuarioRef = _db.collection('usuarios').doc(uid);
      final contadorRef = _db.collection('contadores').doc('codigos');

      final usuarioSnap = await tx.get(usuarioRef);
      final codigoExistente = usuarioSnap.data()?['codigoUsuario'];
      if (codigoExistente != null) return codigoExistente as String;

      final contadorSnap = await tx.get(contadorRef);
      final siguiente = (contadorSnap.data()?['ultimoUsuario'] ?? 0) + 1;

      final codigo = '#${siguiente.toString().padLeft(6, '0')}';
      tx.set(contadorRef, {'ultimoUsuario': siguiente}, SetOptions(merge: true));
      tx.update(usuarioRef, {'codigoUsuario': codigo});
      return codigo;
    });
  }

  /// Busca un usuario por su código único (#000001).
  ///
  /// Devuelve null si no existe ningún usuario con ese código.
  Future<Usuario?> buscarUsuarioPorCodigo(String codigoUsuario) async {
    final snap = await _db
        .collection('usuarios')
        .where('codigoUsuario', isEqualTo: codigoUsuario)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Usuario.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  // ─────────────────────────────────────────────
  // ATLETAS
  // ─────────────────────────────────────────────

  /// Recupera los datos específicos de atleta de un usuario.
  ///
  /// Devuelve null si el usuario no tiene documento en la colección 'atletas'.
  Future<Atleta?> obtenerAtleta(String uid) async {
    final doc = await _db.collection('atletas').doc(uid).get();
    if (!doc.exists) return null;
    return Atleta.fromMap(doc.data()!, doc.id);
  }

  /// Devuelve un stream con todos los atletas vinculados a un entrenador.
  ///
  /// El stream se actualiza en tiempo real cuando se añaden o eliminan atletas.
  Stream<List<Atleta>> atletasPorEntrenador(String entrenadorId) {
    return _db
        .collection('atletas')
        .where('entrenadorId', isEqualTo: entrenadorId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Atleta.fromMap(d.data(), d.id)).toList());
  }

  // ─────────────────────────────────────────────
  // EJERCICIOS
  // ─────────────────────────────────────────────

  /// Crea un nuevo ejercicio en la colección 'ejercicios'.
  ///
  /// Firestore genera el ID automáticamente y lo devuelve en el documento.
  Future<String> crearEjercicio(Ejercicio ejercicio) async {
    final ref = await _db
        .collection('ejercicios')
        .add(ejercicio.toMap());
    return ref.id;
  }

  /// Recupera un ejercicio por su ID.
  Future<Ejercicio?> obtenerEjercicio(String id) async {
    final doc = await _db.collection('ejercicios').doc(id).get();
    if (!doc.exists) return null;
    return Ejercicio.fromMap(doc.data()!, doc.id);
  }

  /// Devuelve la lista de ejercicios correspondientes a una lista de IDs.
  ///
  /// Útil para cargar todos los ejercicios de un entrenamiento de una vez.
  Future<List<Ejercicio>> obtenerEjercicios(List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures = ids.map((id) => obtenerEjercicio(id));
    final resultados = await Future.wait(futures);
    // Filtra los posibles nulos en caso de documentos eliminados
    return resultados.whereType<Ejercicio>().toList();
  }

  // ─────────────────────────────────────────────
  // ENTRENAMIENTOS
  // ─────────────────────────────────────────────

  /// Crea un nuevo entrenamiento en la colección 'entrenamientos'.
  ///
  /// Devuelve el ID generado por Firestore para el nuevo documento.
  Future<String> crearEntrenamiento(Entrenamiento entrenamiento) async {
    final ref = await _db
        .collection('entrenamientos')
        .add(entrenamiento.toMap());
    return ref.id;
  }

  /// Recupera un entrenamiento por su ID.
  Future<Entrenamiento?> obtenerEntrenamiento(String id) async {
    final doc = await _db.collection('entrenamientos').doc(id).get();
    if (!doc.exists) return null;
    return Entrenamiento.fromMap(doc.data()!, doc.id);
  }

  /// Stream con los entrenamientos asignados a un atleta concreto.
  ///
  /// Incluye todos los estados (pendiente, en progreso, completado).
  Stream<List<Entrenamiento>> entrenamientosPorAtleta(String atletaId) {
    return _db
        .collection('entrenamientos')
        .where('atletaId', isEqualTo: atletaId)
        .orderBy('fechaProgramada', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Entrenamiento.fromMap(d.data(), d.id))
            .toList());
  }

  /// Stream con las plantillas de entrenamiento creadas por un entrenador.
  ///
  /// Una plantilla es un entrenamiento sin atleta asignado ([atletaId] == null).
  Stream<List<Entrenamiento>> plantillasPorEntrenador(String entrenadorId) {
    return _db
        .collection('entrenamientos')
        .where('entrenadorId', isEqualTo: entrenadorId)
        .where('atletaId', isNull: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Entrenamiento.fromMap(d.data(), d.id))
            .toList());
  }

  /// Actualiza el estado de un entrenamiento (ej. de pendiente a completado).
  Future<void> actualizarEstadoEntrenamiento(
      String id, EstadoEntrenamiento estado) async {
    await _db
        .collection('entrenamientos')
        .doc(id)
        .update({'estado': estado.name});
  }

  /// Crea una asignación nueva de la [plantilla] para cada uno de los [atletasIds].
  ///
  /// Cada documento generado es una copia con [atletaId] específico y estado pendiente.
  /// Devuelve el número de asignaciones creadas.
  Future<int> asignarPlantillaAAtletas({
    required Entrenamiento plantilla,
    required List<String> atletasIds,
  }) async {
    if (atletasIds.isEmpty) return 0;
    final batch = _db.batch();
    final ahora = Timestamp.fromDate(DateTime.now());
    for (final atletaId in atletasIds) {
      final ref = _db.collection('entrenamientos').doc();
      batch.set(ref, {
        'nombre': plantilla.nombre,
        'descripcion': plantilla.descripcion,
        'entrenadorId': plantilla.entrenadorId,
        'atletaId': atletaId,
        'ejerciciosIds': plantilla.ejerciciosIds,
        'fechaCreacion': ahora,
        'fechaProgramada': plantilla.fechaProgramada != null
            ? Timestamp.fromDate(plantilla.fechaProgramada!)
            : null,
        'estado': EstadoEntrenamiento.pendiente.name,
      });
    }
    await batch.commit();
    return atletasIds.length;
  }

  /// Stream de los entrenamientos que un entrenador ha asignado a un atleta concreto.
  ///
  /// Filtra por entrenadorId en Firestore (regla satisfecha) y por atletaId en memoria
  /// para evitar índices compuestos.
  Stream<List<Entrenamiento>> entrenamientosAsignadosAAtletaPorEntrenador({
    required String entrenadorId,
    required String atletaId,
  }) {
    return _db
        .collection('entrenamientos')
        .where('entrenadorId', isEqualTo: entrenadorId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Entrenamiento.fromMap(d.data(), d.id))
            .where((e) => e.atletaId == atletaId)
            .toList());
  }

  // ─────────────────────────────────────────────
  // RESULTADOS
  // ─────────────────────────────────────────────

  /// Guarda un nuevo resultado en la colección 'resultados'.
  ///
  /// Devuelve el ID generado por Firestore.
  Future<String> guardarResultado(Resultado resultado) async {
    final ref = await _db
        .collection('resultados')
        .add(resultado.toMap());
    return ref.id;
  }

  /// Actualiza las observaciones del entrenador en un resultado existente.
  Future<void> actualizarObservacionesEntrenador(
      String resultadoId, String observaciones) async {
    await _db.collection('resultados').doc(resultadoId).update({
      'observacionesEntrenador': observaciones,
    });
  }

  /// Stream con todos los resultados de un atleta, ordenados por fecha descendente.
  ///
  /// Permite al entrenador visualizar la evolución del atleta en tiempo real.
  Stream<List<Resultado>> resultadosPorAtleta({
    required String entrenadorId,
    required String atletaId,
  }) {
    return _db
        .collection('resultados')
        .where('entrenadorId', isEqualTo: entrenadorId)
        .snapshots()
        .map((snap) {
      final lista = snap.docs
          .map((d) => Resultado.fromMap(d.data(), d.id))
          .where((r) => r.atletaId == atletaId)
          .toList();
      lista.sort((a, b) => b.fecha.compareTo(a.fecha));
      return lista;
    });
  }

  // ─────────────────────────────────────────────
  // RECURSOS (BIBLIOTECA)
  // ─────────────────────────────────────────────

  /// Recupera un recurso de la biblioteca por su ID.
  ///
  /// Devuelve null si el documento no existe en Firestore.
  Future<Recurso?> obtenerRecurso(String id) async {
    final doc = await _db.collection('recursos').doc(id).get();
    if (!doc.exists) return null;
    return Recurso.fromMap(doc.data()!, doc.id);
  }

  /// Stream con todos los recursos de la biblioteca, ordenados por fecha.
  ///
  /// La UI se suscribe para mostrar siempre el contenido actualizado.
  Stream<List<Recurso>> obtenerRecursos() {
    return _db
        .collection('recursos')
        .orderBy('fechaPublicacion', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Recurso.fromMap(d.data(), d.id)).toList());
  }

  /// Stream con los recursos filtrados por categoría.
  ///
  /// El ordenado se aplica en memoria para evitar el índice compuesto
  /// (categoria + fechaPublicacion) que requeriría un índice manual en Firestore.
  Stream<List<Recurso>> recursosPorCategoria(CategoriaRecurso categoria) {
    return _db
        .collection('recursos')
        .where('categoria', isEqualTo: categoria.name)
        .snapshots()
        .map((snap) {
      final lista =
          snap.docs.map((d) => Recurso.fromMap(d.data(), d.id)).toList();
      lista.sort((a, b) => b.fechaPublicacion.compareTo(a.fechaPublicacion));
      return lista;
    });
  }

  /// Crea un nuevo recurso en la colección 'recursos'.
  ///
  /// Devuelve el ID generado por Firestore.
  Future<String> crearRecurso(Recurso recurso) async {
    final ref = await _db.collection('recursos').add(recurso.toMap());
    return ref.id;
  }

  // ─────────────────────────────────────────────
  // GRUPOS DE ENTRENAMIENTO
  // ─────────────────────────────────────────────

  /// Crea un nuevo grupo en la colección 'grupos'.
  ///
  /// Devuelve el ID generado por Firestore.
  Future<String> crearGrupo(Grupo grupo) async {
    final ref = await _db.collection('grupos').add(grupo.toMap());
    return ref.id;
  }

  /// Asigna un código único (#000001) al grupo recién creado.
  ///
  /// Usa una transacción atómica sobre [contadores/codigos.ultimoGrupo].
  /// Devuelve el código asignado.
  Future<String> asignarCodigoGrupo(String grupoId) async {
    return _db.runTransaction((tx) async {
      final grupoRef = _db.collection('grupos').doc(grupoId);
      final contadorRef = _db.collection('contadores').doc('codigos');

      final contadorSnap = await tx.get(contadorRef);
      final siguiente = (contadorSnap.data()?['ultimoGrupo'] ?? 0) + 1;

      final codigo = '#${siguiente.toString().padLeft(6, '0')}';
      tx.set(contadorRef, {'ultimoGrupo': siguiente}, SetOptions(merge: true));
      tx.update(grupoRef, {'codigoGrupo': codigo});
      return codigo;
    });
  }

  /// Recupera un grupo por su ID.
  Future<Grupo?> obtenerGrupo(String grupoId) async {
    final doc = await _db.collection('grupos').doc(grupoId).get();
    if (!doc.exists) return null;
    return Grupo.fromMap(doc.data()!, doc.id);
  }

  /// Busca un grupo por su código único (#000001).
  Future<Grupo?> buscarGrupoPorCodigo(String codigoGrupo) async {
    final snap = await _db
        .collection('grupos')
        .where('codigoGrupo', isEqualTo: codigoGrupo)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Grupo.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  /// Stream con los grupos creados por un entrenador, en tiempo real.
  Stream<List<Grupo>> gruposPorEntrenador(String entrenadorId) {
    return _db
        .collection('grupos')
        .where('entrenadorId', isEqualTo: entrenadorId)
        .orderBy('fechaCreacion', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Grupo.fromMap(d.data(), d.id)).toList());
  }

  /// Stream con los grupos en los que el atleta es miembro, en tiempo real.
  Stream<List<Grupo>> gruposDelAtleta(String atletaId) {
    return _db
        .collection('grupos')
        .where('miembrosIds', arrayContains: atletaId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Grupo.fromMap(d.data(), d.id)).toList());
  }

  /// Guarda la URL de la foto de portada en el documento del grupo.
  Future<void> actualizarFotoGrupo(String grupoId, String url) async {
    await _db.collection('grupos').doc(grupoId).update({'fotoGrupo': url});
  }

  /// Añade un atleta a la lista de miembros de un grupo.
  Future<void> agregarMiembroAlGrupo(String grupoId, String atletaUid) async {
    await _db.collection('grupos').doc(grupoId).update({
      'miembrosIds': FieldValue.arrayUnion([atletaUid]),
    });
  }

  /// Elimina un atleta de la lista de miembros de un grupo.
  Future<void> eliminarMiembroDelGrupo(
      String grupoId, String atletaUid) async {
    await _db.collection('grupos').doc(grupoId).update({
      'miembrosIds': FieldValue.arrayRemove([atletaUid]),
    });
  }

  // ─────────────────────────────────────────────
  // SOLICITUDES DE INGRESO A GRUPOS
  // ─────────────────────────────────────────────

  /// Crea una nueva solicitud de ingreso a un grupo.
  ///
  /// Devuelve el ID del documento creado.
  Future<String> crearSolicitud(SolicitudGrupo solicitud) async {
    final ref =
        await _db.collection('solicitudes').add(solicitud.toMap());
    return ref.id;
  }

  /// Stream con las solicitudes pendientes de un grupo, en tiempo real.
  Stream<List<SolicitudGrupo>> solicitudesPendientesPorGrupo(String grupoId) {
    return _db
        .collection('solicitudes')
        .where('grupoId', isEqualTo: grupoId)
        .where('estado', isEqualTo: EstadoSolicitud.pendiente.name)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SolicitudGrupo.fromMap(d.data(), d.id))
            .toList());
  }

  /// Comprueba si ya existe una solicitud pendiente de un atleta para un grupo.
  ///
  /// Usa un único filtro (atletaId) para evitar índices compuestos. Los filtros
  /// de grupoId y estado se aplican en memoria sobre los resultados.
  Future<bool> tieneSolicitudPendiente(
      String grupoId, String atletaId) async {
    final snap = await _db
        .collection('solicitudes')
        .where('atletaId', isEqualTo: atletaId)
        .get();
    return snap.docs.any(
      (d) =>
          d.data()['grupoId'] == grupoId &&
          d.data()['estado'] == EstadoSolicitud.pendiente.name,
    );
  }

  /// Resuelve (aprueba o rechaza) una solicitud de ingreso.
  ///
  /// Si [aprobada] es true, añade al atleta a los miembros del grupo.
  Future<void> resolverSolicitud({
    required String solicitudId,
    required String grupoId,
    required String atletaId,
    required bool aprobada,
  }) async {
    final batch = _db.batch();

    batch.update(_db.collection('solicitudes').doc(solicitudId), {
      'estado': aprobada
          ? EstadoSolicitud.aprobada.name
          : EstadoSolicitud.rechazada.name,
      'fechaResolucion': Timestamp.fromDate(DateTime.now()),
    });

    if (aprobada) {
      batch.update(_db.collection('grupos').doc(grupoId), {
        'miembrosIds': FieldValue.arrayUnion([atletaId]),
      });
    }

    await batch.commit();
  }

  // ─────────────────────────────────────────────
  // VINCULACIÓN ATLETA ↔ ENTRENADOR
  // ─────────────────────────────────────────────

  /// Crea o actualiza el documento de atleta vinculando al entrenador indicado.
  ///
  /// Usa merge para preservar [licenciaFederativa] si ya existía.
  Future<void> vincularEntrenador({
    required String atletaUid,
    required String entrenadorId,
    required String categoria,
    required String modalidad,
  }) async {
    await _db.collection('atletas').doc(atletaUid).set(
      {
        'entrenadorId': entrenadorId,
        'categoria': categoria,
        'modalidad': modalidad,
        'fechaVinculacion': Timestamp.fromDate(DateTime.now()),
      },
      SetOptions(merge: true),
    );
  }
}
