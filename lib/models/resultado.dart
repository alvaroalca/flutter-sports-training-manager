/// Modelos que representan los resultados obtenidos en una sesión de entrenamiento.
///
/// La estructura jerárquica es:
///   [Resultado] → contiene varias [Serie] → cada serie contiene los disparos
///
/// En tiro olímpico de pistola a 10 metros, cada disparo puntúa entre 0 y 10.9
/// en competición electrónica. Un [Resultado] agrupa todas las series de un
/// [Ejercicio] concreto ejecutado por un [Atleta] en una sesión de entrenamiento.
///
/// Se almacena en la colección 'resultados' de Firestore.
import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa una serie de disparos dentro de un ejercicio.
///
/// Una serie es la unidad mínima de repetición: el atleta realiza [numDisparos]
/// disparos consecutivos y cada uno genera una puntuación decimal.
class Serie {
  /// Número de orden de la serie dentro del ejercicio (empieza en 1).
  final int numSerie;

  /// Lista de puntuaciones de cada disparo (valor entre 0.0 y 10.9).
  final List<double> disparos;

  Serie({
    required this.numSerie,
    required this.disparos,
  });

  /// Suma total de puntos de todos los disparos de la serie.
  double get total => disparos.fold(0.0, (acc, d) => acc + d);

  /// Puntuación media por disparo en esta serie.
  double get media => disparos.isEmpty ? 0.0 : total / disparos.length;

  /// Número real de disparos registrados en esta serie.
  int get numDisparos => disparos.length;

  /// Crea una [Serie] a partir de un mapa anidado en un documento de Firestore.
  factory Serie.fromMap(Map<String, dynamic> map) {
    return Serie(
      numSerie: map['numSerie'] ?? 0,
      disparos: List<double>.from(
        (map['disparos'] as List).map((d) => (d as num).toDouble()),
      ),
    );
  }

  /// Convierte la serie a un mapa para almacenarla como campo anidado en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'numSerie': numSerie,
      'disparos': disparos,
    };
  }
}

/// Representa el resultado completo de un ejercicio realizado por un atleta.
///
/// Contiene todas las [Series] del ejercicio, la puntuación agregada y
/// observaciones tanto del atleta como del entrenador para el seguimiento técnico.
class Resultado {
  /// Identificador único del resultado en Firestore.
  final String id;

  /// ID del entrenamiento al que pertenece este resultado.
  final String entrenamientoId;

  /// UID del atleta que realizó el ejercicio.
  final String atletaId;

  /// ID del ejercicio ejecutado.
  final String ejercicioId;

  /// Fecha y hora en la que se registró el resultado.
  final DateTime fecha;

  /// Lista de series realizadas en el ejercicio.
  final List<Serie> series;

  /// Observaciones libres escritas por el propio atleta tras el ejercicio (opcional).
  final String? observacionesAtleta;

  /// Observaciones técnicas del entrenador sobre la ejecución (opcional).
  final String? observacionesEntrenador;

  Resultado({
    required this.id,
    required this.entrenamientoId,
    required this.atletaId,
    required this.ejercicioId,
    required this.fecha,
    required this.series,
    this.observacionesAtleta,
    this.observacionesEntrenador,
  });

  /// Suma total de puntos de todas las series del ejercicio.
  double get puntuacionTotal =>
      series.fold(0.0, (acc, s) => acc + s.total);

  /// Puntuación media por disparo considerando todas las series.
  double get mediaPorDisparo {
    final totalDisparos = series.fold(0, (acc, s) => acc + s.numDisparos);
    return totalDisparos == 0 ? 0.0 : puntuacionTotal / totalDisparos;
  }

  /// Número total de disparos registrados en todas las series.
  int get totalDisparos =>
      series.fold(0, (acc, s) => acc + s.numDisparos);

  /// Crea un [Resultado] a partir de un documento de Firestore.
  factory Resultado.fromMap(Map<String, dynamic> map, String id) {
    return Resultado(
      id: id,
      entrenamientoId: map['entrenamientoId'] ?? '',
      atletaId: map['atletaId'] ?? '',
      ejercicioId: map['ejercicioId'] ?? '',
      fecha: (map['fecha'] as Timestamp).toDate(),
      series: (map['series'] as List)
          .map((s) => Serie.fromMap(s as Map<String, dynamic>))
          .toList(),
      observacionesAtleta: map['observacionesAtleta'],
      observacionesEntrenador: map['observacionesEntrenador'],
    );
  }

  /// Convierte el modelo a un mapa para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'entrenamientoId': entrenamientoId,
      'atletaId': atletaId,
      'ejercicioId': ejercicioId,
      'fecha': Timestamp.fromDate(fecha),
      'series': series.map((s) => s.toMap()).toList(),
      'observacionesAtleta': observacionesAtleta,
      'observacionesEntrenador': observacionesEntrenador,
    };
  }

}
