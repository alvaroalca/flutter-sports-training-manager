/// Modelo que representa los datos específicos de un atleta.
///
/// Complementa al modelo [Usuario] (que contiene los datos comunes)
/// con información propia del rol de atleta: entrenador asignado,
/// categoría de competición, modalidad y licencia federativa.
///
/// Se almacena en la subcolección 'atletas' de Firestore, usando el
/// mismo UID de Firebase Auth como identificador del documento.
import 'package:cloud_firestore/cloud_firestore.dart';

class Atleta {
  /// UID del atleta, coincide con el UID de Firebase Auth y con el
  /// documento en la colección 'usuarios'.
  final String uid;

  /// UID del entrenador al que está vinculado este atleta.
  final String entrenadorId;

  /// Categoría de competición del atleta (ej. "Juvenil", "Junior", "Absoluto").
  final String categoria;

  /// Modalidad de tiro practicada (ej. "Pistola 10m", "Pistola 25m").
  final String modalidad;

  /// Número de licencia federativa (opcional).
  final String? licenciaFederativa;

  /// Fecha en la que el atleta fue vinculado al entrenador.
  final DateTime fechaVinculacion;

  Atleta({
    required this.uid,
    required this.entrenadorId,
    required this.categoria,
    required this.modalidad,
    this.licenciaFederativa,
    required this.fechaVinculacion,
  });

  /// Crea un [Atleta] a partir de un documento de Firestore.
  factory Atleta.fromMap(Map<String, dynamic> map, String uid) {
    return Atleta(
      uid: uid,
      entrenadorId: map['entrenadorId'] ?? '',
      categoria: map['categoria'] ?? '',
      modalidad: map['modalidad'] ?? 'Pistola 10m',
      licenciaFederativa: map['licenciaFederativa'],
      fechaVinculacion: (map['fechaVinculacion'] as Timestamp).toDate(),
    );
  }

  /// Convierte el modelo a un mapa para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'entrenadorId': entrenadorId,
      'categoria': categoria,
      'modalidad': modalidad,
      'licenciaFederativa': licenciaFederativa,
      'fechaVinculacion': Timestamp.fromDate(fechaVinculacion),
    };
  }

}
