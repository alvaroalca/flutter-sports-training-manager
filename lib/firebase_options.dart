// ARCHIVO AUTOGENERADO — no editar manualmente.
//
// Generado por: FlutterFire CLI (`flutterfire configure`).
// Cuándo se regenera: al añadir una plataforma nueva o cambiar de proyecto Firebase.
//
// Por qué existe:
//   Firebase necesita saber a qué proyecto conectarse según la plataforma (Android/iOS).
//   Este archivo centraliza esas credenciales y las expone a través de
//   `DefaultFirebaseOptions.currentPlatform`, que recibe `Firebase.initializeApp()`
//   en main.dart. Sin él, la app no puede inicializar ningún servicio Firebase.
//
//   Las claves aquí son identificadores de proyecto públicos (no secretos de servidor),
//   por lo que es seguro y recomendable versionar este archivo.
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUmcPNf_vOJBfggSrys_Klegxkt9oya2g',
    appId: '1:425274545710:android:82a287acb19f7d544531bf',
    messagingSenderId: '425274545710',
    projectId: 'tiro-olimpico-trainer',
    databaseURL: 'https://tiro-olimpico-trainer-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'tiro-olimpico-trainer.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAMi5hozPoTzDkUdaXF4zilrp9v2__MecQ',
    appId: '1:425274545710:ios:6719bc40af3922e84531bf',
    messagingSenderId: '425274545710',
    projectId: 'tiro-olimpico-trainer',
    databaseURL: 'https://tiro-olimpico-trainer-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'tiro-olimpico-trainer.firebasestorage.app',
    iosBundleId: 'com.example.tfg',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDHl3rggC0SCkrxqKldHROvzg6fCdh6IGM',
    appId: '1:425274545710:web:531f098f62dc33fb4531bf',
    messagingSenderId: '425274545710',
    projectId: 'tiro-olimpico-trainer',
    authDomain: 'tiro-olimpico-trainer.firebaseapp.com',
    databaseURL: 'https://tiro-olimpico-trainer-default-rtdb.europe-west1.firebasedatabase.app',
    storageBucket: 'tiro-olimpico-trainer.firebasestorage.app',
    measurementId: 'G-D5XHDX4QK8',
  );

}