/// Servicio de autenticación que encapsula las operaciones de Firebase Auth.
///
/// Gestiona el registro, inicio de sesión y cierre de sesión de usuarios.
/// Tras el registro, crea automáticamente el documento correspondiente en
/// Firestore mediante [FirestoreService], garantizando la consistencia entre
/// la autenticación y los datos de la aplicación.
///
/// Se usa con [Provider] para exponer el estado de autenticación a la UI.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tfg/models/usuario.dart';
import 'package:tfg/services/firestore_service.dart';

class AuthService {
  /// Instancia de Firebase Authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Servicio de Firestore para crear/leer datos de usuario.
  final FirestoreService _firestoreService = FirestoreService();

  /// Stream que emite el [User] de Firebase cuando cambia el estado de sesión.
  ///
  /// Emite null si no hay sesión activa, o el objeto [User] si el usuario
  /// ha iniciado sesión. La UI se suscribe a este stream para reaccionar
  /// automáticamente a cambios de autenticación.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Registra un nuevo usuario con email y contraseña.
  ///
  /// Crea la cuenta en Firebase Auth y a continuación genera el documento
  /// del usuario en Firestore con los datos básicos del perfil.
  ///
  /// Lanza [FirebaseAuthException] si el email ya está en uso o la
  /// contraseña no cumple los requisitos mínimos de seguridad.
  Future<Usuario> registrar({
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
  }) async {
    // Crear cuenta en Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Construir el objeto usuario con los datos del registro.
    // No se guarda rol en Firestore: el modo de vista se gestiona localmente.
    final usuario = Usuario(
      uid: uid,
      nombre: nombre,
      apellidos: apellidos,
      email: email,
      fechaCreacion: DateTime.now(),
    );

    // Persistir el documento en Firestore
    await _firestoreService.crearUsuario(usuario);

    // Asignar código único al nuevo usuario
    final codigo = await _firestoreService.asignarCodigoUsuarioSiNoTiene(uid);

    return usuario.copyWith(codigoUsuario: codigo);
  }

  /// Inicia sesión con email y contraseña.
  ///
  /// Devuelve el [Usuario] con los datos del perfil recuperados de Firestore.
  /// Lanza [FirebaseAuthException] si las credenciales son incorrectas.
  Future<Usuario> iniciarSesion({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = credential.user!.uid;

    // Recuperar el perfil completo desde Firestore
    final usuario = await _firestoreService.obtenerUsuario(uid);
    return usuario!;
  }

  /// Recupera el perfil de un usuario desde Firestore a partir de su UID.
  ///
  /// Usado para restaurar la sesión cuando Firebase Auth ya tiene un usuario
  /// autenticado pero el controlador aún no ha cargado el perfil.
  Future<Usuario?> cargarUsuarioPorUid(String uid) async {
    return await _firestoreService.obtenerUsuario(uid);
  }

  /// Cierra la sesión del usuario actualmente autenticado.
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}
