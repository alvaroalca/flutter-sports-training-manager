# ShootTrack

> Aplicación móvil multiplataforma para la planificación y seguimiento del entrenamiento en tiro deportivo

**Trabajo de Fin de Ciclo — Desarrollo de Aplicaciones Multiplataforma (DAM)**  
Autor: Álvaro Alcaraz Pérez · Universidad Alfonso X el Sabio · 2025-2026

---

## Descripción

ShootTrack digitaliza el ciclo completo del entrenamiento de pistola olímpica a 10 metros. Los entrenamientos de esta disciplina se basan en ejercicios cronometrados con fases estrictas de preparación y apuntado que, hasta ahora, se coordinaban de forma verbal entre entrenador y atleta sin ningún registro centralizado.

La aplicación cubre todo el flujo: el entrenador diseña sesiones con ejercicios parametrizados, las asigna a atletas individuales o a grupos enteros, y el atleta las ejecuta guiado por un temporizador integrado que secuencia cada fase del disparo. Los resultados quedan registrados disparo a disparo y el entrenador puede revisar la evolución de sus atletas en tiempo real.

---

## Vídeo de presentación

Presentación del Trabajo de Fin de Ciclo disponible en YouTube: [ver vídeo](https://youtu.be/lxZENzaq6Tc).

---

## Funcionalidades

### Portal atleta
- Lista de entrenamientos asignados (por entrenador o grupo) con estado pendiente / en progreso / completado
- Ejecución guiada con temporizador por fases (preparación → apuntado) y registro de puntuación por disparo
- Marcar entrenamiento como terminado sin pasar por tracking
- Vincularse con un entrenador introduciendo su código de usuario
- Unirse a grupos de entrenamiento mediante código
- Biblioteca de recursos técnicos con filtro por categoría
- Perfil editable con foto y gestión del entrenador asignado

### Portal entrenador
- Crear plantillas de entrenamiento con ejercicios configurables (fases, tiempos, nº disparos, series)
- Asignar plantillas a atletas concretos o a todos los miembros de un grupo en un solo paso
- Panel de atletas con estadísticas globales, historial de resultados y observaciones editables por sesión
- Vista de entrenamientos asignados a cada atleta con sus estados en tiempo real
- Crear y gestionar grupos con código único compartible
- Aprobar o rechazar solicitudes de ingreso a grupos
- Añadir atletas directamente desde el panel mediante su código de usuario

### Compartido
- Autenticación con email y contraseña (Firebase Auth)
- Cualquier cuenta puede usar ambos portales (modo atleta / modo entrenador) sin cambiar de sesión
- Código de usuario único generado automáticamente al registrarse (formato `#000001`)
- Menú lateral con cierre de sesión desde cualquier pantalla principal

---

## Stack tecnológico

| Capa | Tecnología | Versión |
|---|---|---|
| Framework UI | Flutter / Dart | 3.x / 3.x |
| Autenticación | Firebase Authentication | ^5.0.0 |
| Base de datos | Cloud Firestore | ^5.0.0 |
| Almacenamiento | Firebase Storage | ^12.0.0 |
| Estado | Provider (`ChangeNotifier`) | ^6.1.2 |
| Navegación | go_router | ^14.0.0 |
| Plataformas | Android 8.0+ · iOS 14+ | — |

---

## Arquitectura

Arquitectura en capas inspirada en MVVM, adaptada al ecosistema Flutter con Provider:

```
┌─────────────────────────────────────────┐
│               Views                     │  Widgets Flutter por funcionalidad
├─────────────────────────────────────────┤
│            Controllers                  │  ChangeNotifier — lógica de negocio
│  Auth · Entrenamiento · Tracking        │
│  Coach · Biblioteca · Grupos            │
├─────────────────────────────────────────┤
│             Services                    │  Acceso a Firebase
│  AuthService · FirestoreService         │
│  StorageService                         │
├─────────────────────────────────────────┤
│              Models                     │  Modelos con fromMap/toMap Firestore
│  Usuario · Atleta · Entrenamiento       │
│  Ejercicio · Resultado · Recurso        │
│  Grupo · SolicitudGrupo                 │
└─────────────────────────────────────────┘
```

- Las vistas observan controllers con `context.watch<T>()` y se reconstruyen automáticamente.
- Los controllers exponen `Stream<T>` (tiempo real) y `Future<T>` (operaciones puntuales).
- El tracking implementa una **máquina de estados** (`idle → preparación → apuntado → registro → completado`) con `Timer.periodic`.
- La navegación es declarativa con go_router y redirección automática por estado de sesión.

---

## Estructura del proyecto

```
lib/
├── main.dart                         # Entrada + inicialización Firebase
├── firebase_options.dart             # Configuración por plataforma (generado)
├── app/
│   ├── app.dart                      # MyApp + MultiProvider
│   └── router.dart                   # Rutas y redirección por estado de sesión
├── models/
│   ├── usuario.dart
│   ├── atleta.dart                   # Datos deportivos + vínculo entrenador
│   ├── entrenamiento.dart            # null atletaId = plantilla
│   ├── ejercicio.dart
│   ├── resultado.dart                # Series + disparos anidados
│   ├── recurso.dart
│   ├── grupo.dart
│   └── solicitud_grupo.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart        # Todas las operaciones Firestore
│   └── storage_service.dart
├── controllers/
│   ├── auth_controller.dart          # Sesión, usuario, modo vista, vinculación
│   ├── entrenamiento_controller.dart # CRUD + asignación masiva a grupos
│   ├── tracking_controller.dart      # Máquina de estados del temporizador
│   ├── coach_controller.dart         # Panel entrenador + agregar atleta
│   ├── biblioteca_controller.dart    # Filtros + siembra de contenido
│   └── grupos_controller.dart        # Grupos + solicitudes de ingreso
├── views/
│   ├── auth/                         # Login, Registro
│   ├── dashboard/                    # Pantalla principal con grid por portal
│   ├── training/                     # Lista, creación y detalle de entrenamientos
│   ├── tracking/                     # Ejecución con temporizador en tiempo real
│   ├── coach/                        # Panel de atletas y perfil individual
│   ├── library/                      # Biblioteca técnica y detalle de recurso
│   ├── grupos/                       # Grupos (vistas entrenador y atleta)
│   └── profile/                      # Perfil + gestión del entrenador asignado
├── core/
│   ├── constants/                    # AppRoutes, AppStrings
│   └── theme/                        # AppColors, AppTextStyles, AppDimensions
└── shared/widgets/
    └── app_scaffold.dart             # Header unificado con menú lateral
```

---

## Modelo de datos (Firestore)

Estructura plana (colecciones en raíz) para facilitar consultas y evitar límites de escritura en subcolecciones.

| Colección | Campos clave |
|---|---|
| `usuarios` | `uid`, `nombre`, `apellidos`, `email`, `fotoPerfil`, `codigoUsuario` (#000001) |
| `atletas` | `uid` (= usuarios), `entrenadorId`, `categoria`, `modalidad`, `licenciaFederativa`, `fechaVinculacion` |
| `entrenamientos` | `nombre`, `entrenadorId`, `atletaId` (null = plantilla), `ejerciciosIds[]`, `estado`, `fechaProgramada` |
| `ejercicios` | `nombre`, `tiempoPreparacion`, `tiempoApuntado`, `numDisparos`, `repeticiones` |
| `resultados` | `atletaId`, `entrenadorId`, `entrenamientoId`, `series[]` → `disparos[]`, `observacionesAtleta`, `observacionesEntrenador` |
| `recursos` | `titulo`, `resumen`, `contenido`, `categoria`, `autor`, `fechaPublicacion` |
| `grupos` | `nombre`, `entrenadorId`, `codigoGrupo`, `miembrosIds[]`, `fotoGrupo` |
| `solicitudes` | `grupoId`, `atletaId`, `estado` (pendiente/aprobada/rechazada), `fechaSolicitud` |
| `contadores/codigos` | `ultimoUsuario`, `ultimoGrupo` (contador para generación de códigos únicos) |

---

## Puesta en marcha

### Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0 / Dart ≥ 3.0
- Android Studio 2022+ o VS Code con extensiones Flutter/Dart
- Proyecto Firebase con Authentication, Firestore y Storage habilitados
- Dispositivo físico o emulador (Android API 26+ / iOS 14+)

### Instalación

```bash
git clone <url-del-repositorio>
cd tfg
flutter pub get
```

### Configuración de Firebase

1. Crear un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Habilitar **Authentication** → proveedor Email/Contraseña
3. Crear base de datos **Cloud Firestore** (modo producción)
4. Habilitar **Firebase Storage**
5. Registrar las apps Android e iOS en el proyecto
6. Instalar la CLI de FlutterFire y configurar:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Esto genera `lib/firebase_options.dart` con las claves de cada plataforma.

7. Desplegar las reglas de seguridad:

```bash
firebase deploy --only firestore:rules --project <project-id>
```

### Ejecución

```bash
flutter run                        # Desarrollo en dispositivo conectado
flutter build apk --release        # Android release
flutter build ipa --release        # iOS release (solo macOS + Xcode)
```

---

## Reglas de Firestore

Las reglas de producción están en [`firestore.rules`](firestore.rules). Cubren:

- Lectura/escritura por propietario en `usuarios` con validación de campos permitidos
- Acceso cruzado entrenador ↔ atleta en `atletas` y `resultados`
- Creación de entrenamientos solo por su `entrenadorId`; atleta solo puede actualizar el campo `estado`
- Solicitudes de ingreso validadas contra el grupo (debe existir, atleta no debe ser ya miembro)
- Generación de códigos únicos mediante transacción atómica en `contadores/codigos`

```bash
# Desplegar reglas actualizadas
firebase deploy --only firestore:rules --project tiro-olimpico-trainer
```

---

## Licencia

Proyecto desarrollado con fines académicos como Trabajo de Fin de Ciclo del ciclo formativo de Desarrollo de Aplicaciones Multiplataforma (DAM). Universidad Alfonso X el Sabio, curso 2025-2026.
