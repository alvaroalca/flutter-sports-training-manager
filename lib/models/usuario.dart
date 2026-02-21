/// Modelo que representa a un usuario de la aplicación.
///
/// No incluye un rol fijo: cualquier usuario puede actuar como entrenador
/// o como atleta. El modo de vista activo se gestiona como estado local
/// en [AuthController] mediante el enum [ModoVista] y se puede cambiar
/// en cualquier momento desde la pantalla principal.
///
/// Los datos se almacenan en la colección 'usuarios' de Firestore,
/// usando el UID de Firebase Auth como identificador del documento.
import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  /// Identificador único del usuario, coincide con el UID de Firebase Auth.
  final String uid;

  /// Nombre de pila del usuario.
  final String nombre;

  /// Apellidos del usuario.
  final String apellidos;

  /// Correo electrónico asociado a la cuenta.
  final String email;

  /// Fecha en la que se creó la cuenta.
  final DateTime fechaCreacion;

  /// URL de la foto de perfil almacenada en Firebase Storage (opcional).
  final String? fotoPerfil;

  /// Código único de usuario, formato #000001.
  /// Se asigna al registrarse o la primera vez que inicia sesión.
  final String? codigoUsuario;

  Usuario({
    required this.uid,
    required this.nombre,
    required this.apellidos,
    required this.email,
    required this.fechaCreacion,
    this.fotoPerfil,
    this.codigoUsuario,
  });

  /// Devuelve el nombre completo concatenando nombre y apellidos.
  String get nombreCompleto => '$nombre $apellidos';

  /// Crea un [Usuario] a partir de un documento de Firestore.
  ///
  /// [map] contiene los campos del documento y [uid] es el ID del documento.
  /// Crea un [Usuario] a partir de un documento de Firestore.
  factory Usuario.fromMap(Map<String, dynamic> map, String uid) {
    return Usuario(
      uid: uid,
      nombre: map['nombre'] ?? '',
      apellidos: map['apellidos'] ?? '',
      email: map['email'] ?? '',
      fechaCreacion: (map['fechaCreacion'] as Timestamp).toDate(),
      fotoPerfil: map['fotoPerfil'],
      codigoUsuario: map['codigoUsuario'],
    );
  }

  /// Convierte el modelo a un mapa para guardar en Firestore.
  ///
  /// El campo [uid] no se incluye ya que es el ID del documento.
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellidos': apellidos,
      'email': email,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fotoPerfil': fotoPerfil,
      if (codigoUsuario != null) 'codigoUsuario': codigoUsuario,
    };
  }

  /// Devuelve una copia del usuario con los campos indicados modificados.
  Usuario copyWith({
    String? nombre,
    String? apellidos,
    String? email,
    String? fotoPerfil,
    String? codigoUsuario,
  }) {
    return Usuario(
      uid: uid,
      nombre: nombre ?? this.nombre,
      apellidos: apellidos ?? this.apellidos,
      email: email ?? this.email,
      fechaCreacion: fechaCreacion,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      codigoUsuario: codigoUsuario ?? this.codigoUsuario,
    );
  }
}
