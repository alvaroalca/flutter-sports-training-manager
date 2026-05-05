/// Controller de autenticación que actúa como intermediario entre
/// la capa de servicios ([AuthService]) y la interfaz de usuario.
///
/// Extiende [ChangeNotifier] para integrarse con el paquete Provider:
/// cuando el estado interno cambia (cargando, error, usuario) notifica
/// a los widgets suscritos para que se reconstruyan automáticamente.
///
/// Gestiona los estados:
///   - [isLoading]: indica si hay una operación en curso.
///   - [errorMessage]: almacena el mensaje del último error, si lo hay.
///   - [usuario]: el usuario autenticado actualmente.
///   - [modoVista]: portal activo (atleta o entrenador), gestionado localmente.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tfg/models/atleta.dart';
import 'package:tfg/models/usuario.dart';
import 'package:tfg/services/auth_service.dart';
import 'package:tfg/services/firestore_service.dart';
import 'package:tfg/services/storage_service.dart';

/// Modo de vista activo en la aplicación.
///
/// No se persiste en Firestore: cada sesión comienza en modo atleta.
/// El usuario puede cambiar de portal en cualquier momento desde la pantalla principal.
enum ModoVista { atleta, entrenador }

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  StreamSubscription<User?>? _authSub;

  /// Suscribe al stream de Firebase Auth para restaurar la sesión
  /// automáticamente cuando la app arranca con una sesión ya activa.
  AuthController() {
    _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  /// Reacciona a cambios en el estado de autenticación de Firebase.
  ///
  /// Si hay un usuario de Firebase pero [_usuario] es null (p.ej. al arrancar
  /// la app con sesión guardada), carga el perfil desde Firestore.
  /// Si no hay usuario de Firebase, limpia el estado local.
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null && _usuario == null && !_isLoading) {
      _setLoading(true);
      _usuario = await _authService.cargarUsuarioPorUid(firebaseUser.uid);

      // Asignación lazy del código para usuarios que se registraron antes
      // de que se implementara el sistema de códigos.
      if (_usuario != null && _usuario!.codigoUsuario == null) {
        final codigo = await _firestoreService
            .asignarCodigoUsuarioSiNoTiene(firebaseUser.uid);
        _usuario = _usuario!.copyWith(codigoUsuario: codigo);
      }

      _setLoading(false);
    } else if (firebaseUser == null && _usuario != null) {
      _usuario = null;
      _modoVista = ModoVista.atleta;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Indica si hay una operación asíncrona en progreso.
  /// La UI muestra un indicador de carga mientras sea true.
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Mensaje del último error producido, o null si no hay error activo.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Usuario autenticado actualmente, o null si no hay sesión activa.
  Usuario? _usuario;
  Usuario? get usuario => _usuario;

  /// Portal activo en la sesión actual.
  ///
  /// Comienza siempre en [ModoVista.atleta]. El usuario puede cambiarlo
  /// desde la pantalla principal sin cerrar sesión ni recargar datos.
  ModoVista _modoVista = ModoVista.atleta;
  ModoVista get modoVista => _modoVista;

  /// Cambia el portal activo y notifica a los widgets suscritos.
  void cambiarModo(ModoVista modo) {
    _modoVista = modo;
    notifyListeners();
  }

  /// Stream del estado de autenticación de Firebase.
  ///
  /// Los widgets que necesiten reaccionar a cambios de sesión (ej. el router)
  /// deben escuchar este stream directamente.
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Intenta registrar un nuevo usuario con los datos del formulario.
  ///
  /// Actualiza [isLoading] durante la operación y [errorMessage] si falla.
  /// Devuelve true si el registro fue exitoso, false en caso contrario.
  Future<bool> registrar({
    required String nombre,
    required String apellidos,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _usuario = await _authService.registrar(
        nombre: nombre,
        apellidos: apellidos,
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      // Traduce los códigos de error de Firebase a mensajes comprensibles
      _errorMessage = _traducirErrorAuth(e.code);
      return false;
    } catch (_) {
      _errorMessage = 'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Intenta iniciar sesión con email y contraseña.
  ///
  /// Devuelve true si el inicio de sesión fue exitoso, false en caso contrario.
  Future<bool> iniciarSesion({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      _usuario = await _authService.iniciarSesion(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _traducirErrorAuth(e.code);
      return false;
    } catch (_) {
      _errorMessage = 'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sube una nueva foto de perfil para el usuario autenticado.
  ///
  /// Actualiza Firebase Storage y el documento Firestore del usuario,
  /// y refresca [usuario] localmente para que la UI se actualice.
  ///
  /// Devuelve la URL pública de la imagen, o null si hubo un error.
  Future<String?> subirFotoPerfil(Uint8List bytes, String extension) async {
    final uid = _usuario?.uid;
    if (uid == null) return null;
    try {
      final url = await _storageService.subirFotoPerfil(uid, bytes, extension);
      await _firestoreService.actualizarFotoPerfil(uid, url);
      _usuario = _usuario!.copyWith(fotoPerfil: url);
      notifyListeners();
      return url;
    } catch (_) {
      return null;
    }
  }

  /// Actualiza el nombre y apellidos del usuario en Firestore y en el estado local.
  ///
  /// Devuelve true si la operación fue exitosa, false en caso contrario.
  Future<bool> actualizarPerfil({
    required String nombre,
    required String apellidos,
  }) async {
    final uid = _usuario?.uid;
    if (uid == null) return false;
    _setLoading(true);
    try {
      await _firestoreService.actualizarUsuario(
        uid,
        {'nombre': nombre, 'apellidos': apellidos},
      );
      _usuario = _usuario!.copyWith(nombre: nombre, apellidos: apellidos);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Devuelve el documento atleta del usuario actual, o null si no existe.
  Future<Atleta?> obtenerAtletaActual() =>
      _firestoreService.obtenerAtleta(_usuario!.uid);

  /// Devuelve el usuario con el UID dado, o null si no existe.
  Future<Usuario?> obtenerUsuarioPorUid(String uid) =>
      _firestoreService.obtenerUsuario(uid);

  /// Vincula el usuario actual como atleta al entrenador con [codigoEntrenador].
  ///
  /// Devuelve null si la operación fue exitosa, o un mensaje de error.
  Future<String?> vincularEntrenador({
    required String codigoEntrenador,
    required String categoria,
    required String modalidad,
  }) async {
    try {
      final trainer = await _firestoreService
          .buscarUsuarioPorCodigo(codigoEntrenador.trim().toUpperCase());
      if (trainer == null) return 'No existe ningún entrenador con ese código.';
      if (trainer.uid == _usuario!.uid) return 'No puedes vincularte a ti mismo.';

      final atletaActual = await _firestoreService.obtenerAtleta(_usuario!.uid);
      if (atletaActual != null && atletaActual.entrenadorId == trainer.uid) {
        return 'Ya estás vinculado con ${trainer.nombreCompleto}.';
      }

      await _firestoreService.vincularEntrenador(
        atletaUid: _usuario!.uid,
        entrenadorId: trainer.uid,
        categoria: categoria,
        modalidad: modalidad,
      );
      return null;
    } catch (e) {
      return 'Error al vincular entrenador: ${e.toString()}';
    }
  }

  /// Cierra la sesión del usuario actual y limpia el estado local.
  ///
  /// Resetea también el modo de vista a [ModoVista.atleta] para que la
  /// próxima sesión comience siempre desde el portal del atleta.
  Future<void> cerrarSesion() async {
    await _authService.cerrarSesion();
    _usuario = null;
    _modoVista = ModoVista.atleta;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // Métodos privados de utilidad
  // ─────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Traduce los códigos de error de Firebase Auth a mensajes en español.
  String _traducirErrorAuth(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo electrónico ya está registrado.';
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'user-not-found':
        return 'No existe ninguna cuenta con ese correo electrónico.';
      case 'wrong-password':
        return 'La contraseña introducida es incorrecta.';
      // Firebase SDK moderno unifica user-not-found y wrong-password en este código
      case 'invalid-credential':
        return 'El correo o la contraseña son incorrectos.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Espera unos minutos e inténtalo de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Comprueba tu red e inténtalo de nuevo.';
      default:
        return 'Error de autenticación. Inténtalo de nuevo.';
    }
  }
}
