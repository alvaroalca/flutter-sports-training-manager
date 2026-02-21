/// Modelo que representa una sesión de entrenamiento.
///
/// Un entrenamiento agrupa una secuencia de [Ejercicio]s y puede estar
/// en tres estados: pendiente, en progreso o completado.
///
/// Cuando [atletaId] es null, el entrenamiento actúa como plantilla
/// genérica que el entrenador puede reutilizar y asignar a varios atletas.
/// Cuando tiene un [atletaId] asignado, es una sesión concreta para ese atleta.
///
/// Se almacena en la colección 'entrenamientos' de Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado del ciclo de vida de un entrenamiento.
/// - [pendiente]: creado pero no iniciado.
/// - [enProgreso]: el atleta ha comenzado la sesión.
/// - [completado]: la sesión ha finalizado y tiene resultados registrados.
enum EstadoEntrenamiento { pendiente, enProgreso, completado }

class Entrenamiento {
  /// Identificador único del entrenamiento en Firestore.
  final String id;

  /// Nombre de la sesión de entrenamiento (ej. "Sesión ritmo lento - semana 3").
  final String nombre;

  /// Descripción general de los objetivos de la sesión.
  final String descripcion;

  /// UID del entrenador que creó la sesión.
  final String entrenadorId;

  /// UID del atleta al que está asignado este entrenamiento.
  /// Si es null, se trata de una plantilla genérica reutilizable.
  final String? atletaId;

  /// Lista de IDs de los ejercicios que componen la sesión, en orden de ejecución.
  final List<String> ejerciciosIds;

  /// Fecha de creación del entrenamiento.
  final DateTime fechaCreacion;

  /// Fecha programada para realizar el entrenamiento (opcional).
  final DateTime? fechaProgramada;

  /// Estado actual del entrenamiento dentro de su ciclo de vida.
  final EstadoEntrenamiento estado;

  Entrenamiento({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.entrenadorId,
    this.atletaId,
    required this.ejerciciosIds,
    required this.fechaCreacion,
    this.fechaProgramada,
    required this.estado,
  });


  /// Crea un [Entrenamiento] a partir de un documento de Firestore.
  factory Entrenamiento.fromMap(Map<String, dynamic> map, String id) {
    return Entrenamiento(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      entrenadorId: map['entrenadorId'] ?? '',
      atletaId: map['atletaId'],
      ejerciciosIds: List<String>.from(map['ejerciciosIds'] ?? []),
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fechaProgramada: map['fechaProgramada'] != null
          ? (map['fechaProgramada'] as Timestamp).toDate()
          : null,
      estado: _estadoFromString(map['estado']),
    );
  }

  /// Convierte el modelo a un mapa para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'entrenadorId': entrenadorId,
      'atletaId': atletaId,
      'ejerciciosIds': ejerciciosIds,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaProgramada':
          fechaProgramada != null ? Timestamp.fromDate(fechaProgramada!) : null,
      'estado': estado.name,
    };
  }

  /// Convierte el string almacenado en Firestore al enum [EstadoEntrenamiento].
  static EstadoEntrenamiento _estadoFromString(String? value) {
    switch (value) {
      case 'enProgreso':
        return EstadoEntrenamiento.enProgreso;
      case 'completado':
        return EstadoEntrenamiento.completado;
      default:
        return EstadoEntrenamiento.pendiente;
    }
  }

}
