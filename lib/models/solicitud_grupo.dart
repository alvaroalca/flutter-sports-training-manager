/// Modelo que representa una solicitud de un atleta para unirse a un grupo.
///
/// Cuando un atleta introduce el código de un grupo, se crea una solicitud
/// en estado [EstadoSolicitud.pendiente]. El entrenador la aprueba o rechaza
/// desde el panel de detalle del grupo.
import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado actual de una solicitud de ingreso a un grupo.
enum EstadoSolicitud { pendiente, aprobada, rechazada }

class SolicitudGrupo {
  /// ID del documento en Firestore.
  final String id;

  /// ID del grupo al que se solicita acceso.
  final String grupoId;

  /// UID del atleta que realiza la solicitud.
  final String atletaId;

  /// Estado actual de la solicitud.
  final EstadoSolicitud estado;

  /// Fecha en que se envió la solicitud.
  final DateTime fechaSolicitud;

  /// Fecha en que el entrenador resolvió la solicitud (null si pendiente).
  final DateTime? fechaResolucion;

  SolicitudGrupo({
    required this.id,
    required this.grupoId,
    required this.atletaId,
    required this.estado,
    required this.fechaSolicitud,
    this.fechaResolucion,
  });

  /// Crea una [SolicitudGrupo] a partir de un documento de Firestore.
  factory SolicitudGrupo.fromMap(Map<String, dynamic> map, String id) {
    return SolicitudGrupo(
      id: id,
      grupoId: map['grupoId'] ?? '',
      atletaId: map['atletaId'] ?? '',
      estado: EstadoSolicitud.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoSolicitud.pendiente,
      ),
      fechaSolicitud: (map['fechaSolicitud'] as Timestamp).toDate(),
      fechaResolucion: map['fechaResolucion'] != null
          ? (map['fechaResolucion'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convierte el modelo a un mapa para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'grupoId': grupoId,
      'atletaId': atletaId,
      'estado': estado.name,
      'fechaSolicitud': Timestamp.fromDate(fechaSolicitud),
      'fechaResolucion':
          fechaResolucion != null ? Timestamp.fromDate(fechaResolucion!) : null,
    };
  }
}
