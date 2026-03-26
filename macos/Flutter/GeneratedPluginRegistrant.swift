//
//  ARCHIVO AUTOGENERADO — no editar manualmente.
//
//  Generado por: Flutter tool al ejecutar `flutter pub get` o `flutter build`.
//  Cuándo se regenera: al añadir o eliminar plugins con soporte macOS en pubspec.yaml.
//
//  Por qué existe:
//    Equivalente Swift del registrador de plugins de iOS, pero para macOS.
//    Registra: cloud_firestore, firebase_auth, firebase_core, firebase_storage
//    y file_selector_macos (selector de archivos nativo del sistema operativo).
//

import FlutterMacOS
import Foundation

import cloud_firestore
import file_selector_macos
import firebase_auth
import firebase_core
import firebase_storage

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FLTFirebaseFirestorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseFirestorePlugin"))
  FileSelectorPlugin.register(with: registry.registrar(forPlugin: "FileSelectorPlugin"))
  FLTFirebaseAuthPlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseAuthPlugin"))
  FLTFirebaseCorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseCorePlugin"))
  FLTFirebaseStoragePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseStoragePlugin"))
}
