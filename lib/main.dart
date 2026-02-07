/// Punto de entrada de la aplicación ShootTrack.
///
/// La secuencia de arranque es:
///   1. [WidgetsFlutterBinding.ensureInitialized] para garantizar que el
///      binding de Flutter esté listo antes de cualquier llamada asíncrona.
///   2. [Firebase.initializeApp] inicializa todos los servicios Firebase
///      (Auth, Firestore, Storage) usando las opciones generadas por FlutterFire CLI.
///   3. [runApp] monta el árbol de widgets raíz definido en [MyApp].
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';

void main() async {
  // Garantiza que los bindings estén inicializados antes de await
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase con la configuración específica de la plataforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}