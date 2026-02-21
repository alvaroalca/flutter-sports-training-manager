/// Modelo que representa un recurso de la biblioteca técnica de tiro olímpico.
///
/// Los recursos son artículos, guías o fichas técnicas organizados por
/// categoría temática. Pueden incluir contenido de texto enriquecido
/// y una imagen ilustrativa almacenada en Firebase Storage.
///
/// Se almacenan en la colección 'recursos' de Firestore y son visibles
/// para todos los usuarios autenticados (entrenadores y atletas).
import 'package:cloud_firestore/cloud_firestore.dart';

/// Categorías temáticas disponibles en la biblioteca.
enum CategoriaRecurso {
  tecnica,
  equipamiento,
  reglamento,
  mentalidad,
  fisico,
}

/// Extensión para obtener la etiqueta legible de cada categoría.
extension CategoriaRecursoExt on CategoriaRecurso {
  String get etiqueta {
    switch (this) {
      case CategoriaRecurso.tecnica:
        return 'Técnica de tiro';
      case CategoriaRecurso.equipamiento:
        return 'Equipamiento';
      case CategoriaRecurso.reglamento:
        return 'Reglamento';
      case CategoriaRecurso.mentalidad:
        return 'Preparación mental';
      case CategoriaRecurso.fisico:
        return 'Condición física';
    }
  }

  /// Icono representativo de cada categoría para la UI.
  String get icono {
    switch (this) {
      case CategoriaRecurso.tecnica:
        return '🎯';
      case CategoriaRecurso.equipamiento:
        return '🔧';
      case CategoriaRecurso.reglamento:
        return '📋';
      case CategoriaRecurso.mentalidad:
        return '🧠';
      case CategoriaRecurso.fisico:
        return '💪';
    }
  }
}

class Recurso {
  /// Identificador único del recurso en Firestore.
  final String id;

  /// Título del recurso mostrado en el listado y la cabecera del detalle.
  final String titulo;

  /// Resumen breve del contenido, mostrado como subtítulo en las tarjetas.
  final String resumen;

  /// Contenido completo del recurso en texto plano con saltos de línea.
  final String contenido;

  /// Categoría temática del recurso.
  final CategoriaRecurso categoria;

  /// URL de la imagen ilustrativa almacenada en Firebase Storage (opcional).
  final String? imagenUrl;

  /// Autor del recurso (entrenador, federación, etc.).
  final String autor;

  /// Fecha de publicación o última actualización.
  final DateTime fechaPublicacion;

  Recurso({
    required this.id,
    required this.titulo,
    required this.resumen,
    required this.contenido,
    required this.categoria,
    this.imagenUrl,
    required this.autor,
    required this.fechaPublicacion,
  });

  /// Crea un [Recurso] a partir de un documento de Firestore.
  factory Recurso.fromMap(Map<String, dynamic> map, String id) {
    return Recurso(
      id: id,
      titulo: map['titulo'] ?? '',
      resumen: map['resumen'] ?? '',
      contenido: map['contenido'] ?? '',
      categoria: _categoriaFromString(map['categoria']),
      imagenUrl: map['imagenUrl'],
      autor: map['autor'] ?? '',
      fechaPublicacion: (map['fechaPublicacion'] as Timestamp).toDate(),
    );
  }

  /// Convierte el modelo a un mapa para guardar en Firestore.
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'resumen': resumen,
      'contenido': contenido,
      'categoria': categoria.name,
      'imagenUrl': imagenUrl,
      'autor': autor,
      'fechaPublicacion': Timestamp.fromDate(fechaPublicacion),
    };
  }

  /// Convierte el string almacenado en Firestore al enum [CategoriaRecurso].
  static CategoriaRecurso _categoriaFromString(String? value) {
    return CategoriaRecurso.values.firstWhere(
      (c) => c.name == value,
      orElse: () => CategoriaRecurso.tecnica,
    );
  }
}
