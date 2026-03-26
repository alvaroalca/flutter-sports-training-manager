# ShootTrack

> Aplicación móvil multiplataforma para la planificación y seguimiento del entrenamiento en tiro deportivo

**Trabajo de Fin de Grado — Desarrollo de Aplicaciones Multiplataforma (DAM)**
Autor: Álvaro Alcaraz Pérez

---

## Descripción

ShootTrack nace de una necesidad real detectada en el tiro olímpico federado: los entrenamientos de pistola a 10 metros se basan en ejercicios cronometrados y altamente personalizados que, hasta ahora, se coordinaban de forma manual entre entrenador y deportista, sin ninguna herramienta digital que centralizase tiempos, rutinas, resultados ni evolución.

La aplicación digitaliza todo ese flujo: el entrenador diseña sesiones con ejercicios configurados por fases y tiempos, las asigna al deportista, y este las ejecuta con un temporizador integrado que guía cada serie. Los resultados quedan registrados disparo a disparo y el entrenador puede consultar la evolución de sus atletas en cualquier momento.

---

## Objetivos

**General:** Desarrollar una aplicación móvil funcional que facilite la gestión integral del entrenamiento en tiro olímpico, permitiendo la personalización de rutinas, el seguimiento del rendimiento y la interacción entre entrenadores y deportistas.

**Específicos:**
- Sistema de autenticación con roles diferenciados (entrenador / deportista)
- Módulo de creación y asignación de entrenamientos personalizados por tiempos y fases del disparo
- Ejecución guiada de entrenamientos con temporizador en tiempo real
- Registro detallado de puntuaciones, observaciones y evolución deportiva
- Panel del entrenador para visualizar el progreso de sus atletas
- Biblioteca de recursos técnicos y formativos sobre tiro deportivo
- Gestión de grupos de entrenamiento con código de invitación
- Arquitectura de datos sencilla, escalable y apoyada en servicios en la nube

---

## Funcionalidades principales

### Para el deportista
- Consultar y ejecutar entrenamientos asignados por el entrenador
- Temporizador de fases (preparación / apuntado) por serie y ejercicio
- Registro de puntuaciones disparo a disparo con cálculo automático de totales y medias
- Historial de resultados y progreso personal
- Unirse a grupos de entrenamiento mediante código
- Acceso a la biblioteca de recursos técnicos

### Para el entrenador
- Crear entrenamientos compuestos por ejercicios configurables (fases, tiempos, disparos, repeticiones)
- Asignar entrenamientos a atletas específicos o guardarlos como plantillas reutilizables
- Consultar el progreso y los resultados de los atletas asignados
- Gestionar grupos de entrenamiento y aprobar solicitudes de entrada
- Acceso a la biblioteca de recursos técnicos

---

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Framework | Flutter 3 / Dart |
| Autenticación | Firebase Authentication |
| Base de datos | Cloud Firestore |
| Almacenamiento | Firebase Storage |
| Gestión de estado | Provider (`ChangeNotifier`) |
| Navegación | go_router |
| Plataformas objetivo | Android · iOS |

---

## Arquitectura

El proyecto sigue una arquitectura en capas con separación clara de responsabilidades:

```
┌──────────────┐
│    Views     │  Vistas por funcionalidad (Flutter widgets)
├──────────────┤
│ Controllers  │  Lógica de negocio (ChangeNotifier + Provider)
├──────────────┤
│   Services   │  Acceso a Firebase (Auth, Firestore, Storage)
├──────────────┤
│    Models    │  Modelos de datos con serialización Firestore
└──────────────┘
```

La navegación es declarativa con **go_router**, con redirección automática según el estado de autenticación. El árbol de widgets raíz inyecta los 6 controllers mediante `MultiProvider`.

---

## Estructura del proyecto

```
lib/
├── main.dart                    # Entrada + inicialización Firebase
├── firebase_options.dart        # Configuración por plataforma
├── app/
│   ├── app.dart                 # MyApp + MultiProvider
│   └── router.dart              # Rutas y lógica de redirección
├── models/                      # Usuario, Atleta, Entrenamiento, Ejercicio,
│                                #   Resultado, Recurso, Grupo, SolicitudGrupo
├── services/
│   ├── auth_service.dart        # Firebase Auth
│   ├── firestore_service.dart   # Todas las operaciones Firestore
│   └── storage_service.dart     # Subida de imágenes
├── controllers/
│   ├── auth_controller.dart     # Sesión, usuario, modo vista
│   ├── entrenamiento_controller.dart
│   ├── tracking_controller.dart # Ejecución en tiempo real
│   ├── coach_controller.dart    # Panel entrenador
│   ├── biblioteca_controller.dart
│   └── grupos_controller.dart
├── views/
│   ├── auth/                    # Login, Registro
│   ├── dashboard/               # Pantalla principal con accesos por rol
│   ├── training/                # Lista, detalle y creación de entrenamientos
│   ├── tracking/                # Ejecución con temporizador
│   ├── coach/                   # Panel entrenador y perfil atleta
│   ├── library/                 # Biblioteca y detalle de recurso
│   ├── grupos/                  # Grupos (entrenador y atleta)
│   └── profile/                 # Perfil de usuario
├── core/
│   ├── constants/app_routes.dart
│   ├── theme/                   # AppTheme, AppColors, AppTextStyles
│   └── l10n/app_strings.dart    # Cadenas de texto centralizadas
└── shared/widgets/              # AppScaffold y componentes reutilizables
```

---

## Modelo de datos

Las colecciones principales en Firestore son:

| Colección | Descripción |
|---|---|
| `usuarios` | Perfil de cada usuario (nombre, email, foto, código único) |
| `atletas` | Datos deportivos del atleta (modalidad, categoría, licencia) |
| `entrenamientos` | Sesiones de entrenamiento con estado y atleta asignado |
| `ejercicios` | Ejercicios individuales con fases, tiempos y disparos |
| `resultados` | Resultados de ejecución: series → disparos → puntuaciones |
| `recursos` | Biblioteca técnica categorizada |
| `grupos` | Grupos de entrenamiento con código de invitación |
| `solicitudes_grupos` | Solicitudes pendientes de atletas para unirse |

---

## Puesta en marcha

### Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0
- Dart ≥ 3.0
- Proyecto Firebase configurado (Authentication + Firestore + Storage)
- Android Studio / Xcode para emulación o dispositivo físico

### Instalación

```bash
# Clonar el repositorio
git clone <url-del-repositorio>
cd tfg

# Instalar dependencias
flutter pub get
```

### Configuración de Firebase

1. Crear un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Habilitar **Authentication** (proveedor Email/Contraseña)
3. Crear base de datos **Firestore** en modo producción
4. Habilitar **Storage**
5. Registrar las apps Android e iOS en el proyecto Firebase
6. Generar `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) y colocarlos en sus rutas correspondientes
7. Ejecutar `flutterfire configure` para regenerar `lib/firebase_options.dart`

### Ejecución

```bash
# Verificar dispositivos disponibles
flutter devices

# Ejecutar en dispositivo/emulador
flutter run

# Build release para Android
flutter build apk --release

# Build release para iOS
flutter build ipa --release
```

---

## Reglas de Firestore recomendadas

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Solo usuarios autenticados
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

> Para producción se recomienda refinar estas reglas por colección.

---

## Licencia

Proyecto desarrollado con fines académicos como Trabajo de Fin de Grado del ciclo formativo de Desarrollo de Aplicaciones Multiplataforma (DAM).
