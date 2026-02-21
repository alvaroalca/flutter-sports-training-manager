/// Modelo que representa un grupo de entrenamiento.
///
/// Un grupo es creado por un entrenador y puede tener múltiples atletas.
/// Los atletas se unen directamente (el entrenador los añade por código)
/// o mediante solicitud pendiente de aprobación.
///
/// Cada grupo tiene un código único (#000001) que el entrenador puede
/// compartir para que los atletas soliciten unirse.
import 'package:cloud_firestore/cloud_firestore.dart';

class Grupo {
  /// ID del documento en Firestore (generado automáticamente).
  final String id;

  /// Nombre descriptivo del grupo (p.ej. "Pistola 10m Juniors").
  final String nombre;

  /// Descripción opcional del grupo.
  final String descripcion;

  /// UID del entrenador que creó el grupo.
  final String entrenadorId;

  /// Código único asignado al grupo, formato #000001.
  /// Se genera mediante transacción en Firestore tras crear el documento.
  final String codigoGrupo;

  /// Fecha de creación del grupo.
  final DateTime fechaCreacion;

  /// Lista de UIDs de los atletas que son miembros activos del grupo.
  final List<String> miembrosIds;

  /// URL de la foto de portada del grupo almacenada en Firebase Storage (opcional).
  final String? fotoGrupo;

  Grupo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.entrenadorId,
    required this.codigoGrupo,
    required this.fechaCreacion,
    required this.miembrosIds,
    this.fotoGrupo,
  });

  /// Crea un [Grupo] a partir de un documento de Firestore.
  factory Grupo.fromMap(Map<String, dynamic> map, String id) {
    return Grupo(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      entrenadorId: map['entrenadorId'] ?? '',
      codigoGrupo: map['codigoGrupo'] ?? '',
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      miembrosIds: List<String>.from(map['miembrosIds'] ?? []),
      fotoGrupo: map['fotoGrupo'],
    );
  }

  /// Convierte el modelo a un mapa para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'entrenadorId': entrenadorId,
      'codigoGrupo': codigoGrupo,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'miembrosIds': miembrosIds,
      if (fotoGrupo != null) 'fotoGrupo': fotoGrupo,
    };
  }
}
