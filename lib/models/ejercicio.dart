/// Modelo que representa un ejercicio de tiro dentro de una sesión de entrenamiento.
///
/// En tiro olímpico, cada ejercicio está formado por fases temporalizadas:
/// una fase de preparación (el tirador monta la pistola y se coloca) y una
/// fase de apuntado (tiempo para efectuar el disparo). Este ciclo se repite
/// [numDisparos] veces por serie y [repeticiones] series por ejercicio.
///
/// Los ejercicios se almacenan en la colección 'ejercicios' de Firestore
/// y son referenciados desde los documentos de [Entrenamiento].
class Ejercicio {
  /// Identificador único del ejercicio en Firestore.
  final String id;

  /// Nombre descriptivo del ejercicio (ej. "Ejercicio de ritmo lento").
  final String nombre;

  /// Descripción detallada del objetivo técnico del ejercicio.
  final String descripcion;

  /// Tiempo de preparación en segundos antes de cada disparo.
  final int tiempoPreparacion;

  /// Tiempo máximo de apuntado en segundos para efectuar el disparo.
  final int tiempoApuntado;

  /// Número de disparos por serie.
  final int numDisparos;

  /// Número de repeticiones (series) del ejercicio.
  final int repeticiones;

  /// Notas adicionales del entrenador sobre la ejecución del ejercicio (opcional).
  final String? notas;

  Ejercicio({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.tiempoPreparacion,
    required this.tiempoApuntado,
    required this.numDisparos,
    required this.repeticiones,
    this.notas,
  });

  /// Duración estimada en segundos de una sola serie del ejercicio.
  ///
  /// Calcula el tiempo total sumando preparación y apuntado por cada disparo.
  int get duracionEstimadaSerie =>
      (tiempoPreparacion + tiempoApuntado) * numDisparos;

  /// Duración estimada total en segundos considerando todas las repeticiones.
  int get duracionEstimadaTotal => duracionEstimadaSerie * repeticiones;

  /// Crea un [Ejercicio] a partir de un documento de Firestore.
  factory Ejercicio.fromMap(Map<String, dynamic> map, String id) {
    return Ejercicio(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      tiempoPreparacion: map['tiempoPreparacion'] ?? 0,
      tiempoApuntado: map['tiempoApuntado'] ?? 0,
      numDisparos: map['numDisparos'] ?? 0,
      repeticiones: map['repeticiones'] ?? 1,
      notas: map['notas'],
    );
  }

  /// Convierte el modelo a un mapa para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'tiempoPreparacion': tiempoPreparacion,
      'tiempoApuntado': tiempoApuntado,
      'numDisparos': numDisparos,
      'repeticiones': repeticiones,
      'notas': notas,
    };
  }

}
