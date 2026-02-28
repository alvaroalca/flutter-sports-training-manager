/// Servicio que centraliza las operaciones de subida y eliminación de
/// archivos en Firebase Storage.
///
/// Estructura de carpetas en Storage:
///   fotos_perfil/{uid}/foto.jpg    → foto de perfil de cada usuario
///   fotos_grupos/{grupoId}.jpg     → foto de portada de cada grupo
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ─────────────────────────────────────────────
  // FOTOS DE PERFIL
  // ─────────────────────────────────────────────

  /// Sube la foto de perfil de un usuario y devuelve la URL de descarga.
  ///
  /// [uid]       → identificador del usuario (usado como nombre de archivo)
  /// [bytes]     → bytes de la imagen (JPEG/PNG)
  /// [extension] → extensión del archivo sin punto ('jpg', 'png')
  Future<String> subirFotoPerfil(
      String uid, Uint8List bytes, String extension) async {
    final ref = _storage.ref().child('fotos_perfil/$uid/foto.$extension');
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/$extension'),
    );
    return task.ref.getDownloadURL();
  }

  // ─────────────────────────────────────────────
  // FOTOS DE GRUPO
  // ─────────────────────────────────────────────

  /// Sube la foto de portada de un grupo y devuelve la URL de descarga.
  ///
  /// [grupoId]   → ID del grupo (usado como nombre de archivo)
  /// [bytes]     → bytes de la imagen (JPEG/PNG)
  /// [extension] → extensión del archivo sin punto ('jpg', 'png')
  Future<String> subirFotoGrupo(
      String grupoId, Uint8List bytes, String extension) async {
    final ref = _storage.ref().child('fotos_grupos/$grupoId.$extension');
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: 'image/$extension'),
    );
    return task.ref.getDownloadURL();
  }
}
