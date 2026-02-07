# MEMORIA DEL TRABAJO FIN DE CICLO
## Técnico Superior en Desarrollo de Aplicaciones Multiplataforma

---

**Título del proyecto:**
Diseño y desarrollo de una aplicación móvil multiplataforma para la planificación y seguimiento del entrenamiento en tiro deportivo

**Autor:** Álvaro Alcaraz Pérez
**Centro:** Universidad Alfonso X el Sabio
**Ciclo:** Desarrollo de Aplicaciones Multiplataforma (DAM)
**Fecha de entrega:** 2025-2026

---

> **Nota de formato para Word:**
> Fuente: Arial o Times New Roman, tamaño 12, interlineado 1.5.
> Márgenes: Superior/Inferior 2,5 cm · Izquierdo/Derecho 3 cm.
> Portada, página en blanco, índice y abstract van antes de la numeración.

---

## ABSTRACT *(English — 15-20 lines)*

This project presents the design and development of a cross-platform mobile application called **ShootTrack**, aimed at managing Olympic pistol shooting training sessions. The application addresses a real need identified in federated sports clubs, where training is still managed through verbal timing by the coach, paper notes, and no centralised digital tool exists to track exercises, results, or athlete progress over time.

ShootTrack has been built using **Flutter** as the cross-platform framework, targeting both Android and iOS from a single codebase. The backend is powered by **Firebase**, using Firebase Authentication for role-based access control, Cloud Firestore as a real-time NoSQL database, and Firebase Storage for media assets. Application state is managed with the **Provider** pattern and navigation is handled declaratively with **GoRouter**.

The system supports two user roles: coach and athlete. Coaches can create training sessions composed of timed exercises, assign them to athletes, review results in real time, and add technical observations. Athletes can follow sessions guided by a built-in countdown timer that sequences the preparation and aiming phases of each shot, record scores, and access a technical library covering shooting technique, equipment, regulations, and mental preparation.

The result is a functional, scalable application that centralises all training management and lays the groundwork for future extensions such as competition tracking, video analysis, and federation integration.

---

## 1. RESUMEN Y OBJETIVOS

### 1.1 Descripción del proyecto

ShootTrack es una aplicación móvil multiplataforma desarrollada con Flutter orientada a la gestión integral del entrenamiento de tiro olímpico de pistola a 10 metros. El proyecto surge de una necesidad real detectada en clubes federados donde el trabajo técnico se apoya exclusivamente en la comunicación verbal entre entrenador y atleta, sin registro digital centralizado de tiempos, rutinas, puntuaciones ni evolución del deportista.

La aplicación cubre el ciclo completo del entrenamiento: desde la creación de rutinas personalizadas por parte del entrenador hasta la ejecución guiada por el atleta con temporizador integrado, el registro de resultados, y la visualización del progreso a lo largo del tiempo.

### 1.2 Motivación

El tiro olímpico de pistola es una disciplina de precisión en la que la consistencia en la ejecución del ciclo del disparo (preparación, apuntado, presión del gatillo, seguimiento) es determinante para el rendimiento. Este ciclo debe repetirse bajo restricciones temporales estrictas, especialmente en categorías de desarrollo donde el entrenador cronometra verbalmente cada fase.

La ausencia de herramientas digitales específicas para esta disciplina contrasta con la madurez tecnológica de otros deportes. Aplicaciones como TrainHeroic, TeamBuildr o ShotMarker existen para deportes de sala o modalidades de tiro con rifle, pero no cubren de forma completa las necesidades de la pistola olímpica a 10 metros con sus características particulares de temporización y rol del entrenador.

### 1.3 Objetivos generales

- Desarrollar una aplicación móvil funcional y multiplataforma (Android e iOS) para la gestión del entrenamiento de pistola olímpica a 10 metros.
- Implementar un sistema de autenticación con diferenciación de roles (entrenador y atleta).
- Construir un módulo de temporizador guiado que automatice las fases del ciclo del disparo.
- Ofrecer al entrenador visibilidad en tiempo real sobre el progreso de sus atletas.
- Crear una biblioteca de recursos técnicos accesible desde la aplicación.

### 1.4 Objetivos específicos

1. Modelar las entidades del dominio (Usuario, Atleta, Entrenamiento, Ejercicio, Resultado, Serie, Recurso) como clases Dart con serialización Firestore.
2. Implementar Firebase Authentication con creación de perfil en Firestore tras el registro.
3. Desarrollar la pantalla de creación de entrenamientos con ejercicios parametrizados (tiempo de preparación, tiempo de apuntado, número de disparos, repeticiones).
4. Implementar el temporizador de tiro como máquina de estados: idle → preparación → apuntado → registro → completado.
5. Implementar el guardado de resultados en Firestore con estructura de series y disparos individuales.
6. Desarrollar el panel del entrenador con lista de atletas vinculados, estadísticas globales e historial de resultados con observaciones editables.
7. Desarrollar la biblioteca técnica con categorías filtrables y contenido en detalle.
8. Configurar la navegación declarativa con GoRouter y redirección automática por rol y estado de sesión.

### 1.5 Alcance y limitaciones

El proyecto se circunscribe a la modalidad de pistola de aire a 10 metros en el contexto de entrenamientos. No cubre la gestión de competiciones oficiales, la integración con sistemas de dianas electrónicas externas, ni funcionalidades sociales entre atletas. Estas extensiones se recogen en el capítulo de trabajo futuro.

---

## 2. ANTECEDENTES

### 2.1 Contexto del tiro olímpico

El tiro deportivo con pistola a 10 metros es una disciplina olímpica regulada por la Federación Internacional de Tiro Deportivo (ISSF). En España, la Real Federación Española de Tiro Olímpico (RFEDETO) agrupa a los tiradores federados y organiza competiciones en categorías desde cadete hasta absoluto.

El entrenamiento de esta modalidad se caracteriza por:
- Sesiones individuales de 60-120 minutos.
- Ejercicios compuestos por series de 5-10 disparos con tiempos de preparación y apuntado prefijados.
- Puntuación decimal por disparo (0.0 a 10.9 en sistemas electrónicos).
- Fuerte componente de control mental y automatización del ciclo del disparo.

### 2.2 Análisis de soluciones existentes

#### 2.2.1 TrainHeroic
Plataforma de gestión de entrenamiento de fuerza y acondicionamiento físico ampliamente usada en deportes de equipo. Permite al entrenador programar sesiones, registrar cargas y visualizar el progreso. No contempla ejercicios de temporización ni modalidades de precisión como el tiro.

**Ventajas relevantes:** interfaz limpia, roles entrenador/atleta diferenciados, historial de resultados.
**Limitaciones para el proyecto:** sin soporte de temporizador por disparo, sin modelo de datos para puntuaciones de tiro.

#### 2.2.2 ShotMarker (Sius Ascor)
Sistema de diana electrónica profesional con aplicación companion. Registra el punto de impacto exacto de cada disparo y genera estadísticas de dispersión. Requiere hardware específico (diana electrónica) con un coste de varios miles de euros.

**Ventajas relevantes:** precisión milimétrica, análisis de agrupación.
**Limitaciones para el proyecto:** dependencia de hardware externo, coste prohibitivo para clubes de desarrollo, sin módulo de planificación de entrenamientos.

#### 2.2.3 My Shooting Coach
Aplicación móvil para tiro con análisis de imagen mediante la cámara del dispositivo. Detecta el movimiento de la pistola durante el apuntado. Disponible para iOS.

**Ventajas relevantes:** sin hardware adicional, disponible en tienda oficial.
**Limitaciones para el proyecto:** sin módulo de entrenador, sin planificación de sesiones, enfocada exclusivamente en el análisis de movimiento.

#### 2.2.4 MySwimPro
Referente en deportes individuales de rendimiento. Genera planes de entrenamiento adaptativos, guía al nadador con instrucciones de audio y registra cada serie. Modelo freemium con suscripción premium.

**Ventajas relevantes:** guía activa durante el entrenamiento, roles entrenador/atleta, historial completo, diseño muy cuidado.
**Limitaciones para el proyecto:** específico para natación, no adaptable a tiro.

#### 2.2.5 Tabla comparativa

| Característica | TrainHeroic | ShotMarker | My Shooting Coach | MySwimPro | ShootTrack |
|---|---|---|---|---|---|
| Roles entrenador/atleta | ✅ | ❌ | ❌ | ✅ | ✅ |
| Temporizador por disparo | ❌ | ❌ | ❌ | ❌ | ✅ |
| Sin hardware externo | ✅ | ❌ | ✅ | ✅ | ✅ |
| Registro de puntuaciones | ❌ | ✅ | ❌ | ✅ | ✅ |
| Planificación de sesiones | ✅ | ❌ | ❌ | ✅ | ✅ |
| Biblioteca técnica | ❌ | ❌ | ❌ | ✅ | ✅ |
| Multiplataforma | ✅ | iOS | iOS | ✅ | ✅ |
| Coste para clubs | Alto | Muy alto | Gratuito/Premium | Suscripción | Gratuito |

### 2.3 Conclusión del análisis

Ninguna solución existente cubre de forma completa el ciclo de gestión del entrenamiento de pistola olímpica a 10 metros sin requerir hardware externo. ShootTrack cubre este hueco ofreciendo un sistema integrado de planificación, ejecución guiada por temporizador, registro de resultados y seguimiento por parte del entrenador, accesible desde cualquier dispositivo móvil moderno.

---

## 3. ANÁLISIS Y ESPECIFICACIÓN DE REQUISITOS

### 3.1 Identificación de actores

| Actor | Descripción |
|---|---|
| **Entrenador** | Usuario registrado con rol de entrenador. Crea entrenamientos, los asigna a atletas, revisa resultados y añade observaciones técnicas. |
| **Atleta** | Usuario registrado con rol de atleta. Ejecuta los entrenamientos asignados, registra puntuaciones y consulta la biblioteca. |
| **Firebase (sistema externo)** | Gestiona la autenticación, la persistencia de datos en tiempo real y el almacenamiento de ficheros. |

### 3.2 Requisitos funcionales

#### RF-01 Autenticación
- RF-01.1: El sistema permite registrar un nuevo usuario introduciendo nombre, apellidos, email, contraseña y rol.
- RF-01.2: El sistema valida el formato del email y la longitud mínima de la contraseña (6 caracteres).
- RF-01.3: El sistema permite iniciar sesión con email y contraseña.
- RF-01.4: El sistema redirige al usuario al home correspondiente a su rol tras autenticarse.
- RF-01.5: El sistema permite cerrar sesión desde cualquier pantalla principal.

#### RF-02 Gestión de entrenamientos (Entrenador)
- RF-02.1: El entrenador puede crear una plantilla de entrenamiento con nombre, descripción, fecha programada y lista de ejercicios.
- RF-02.2: Cada ejercicio tiene: nombre, descripción, tiempo de preparación, tiempo de apuntado, número de disparos y número de repeticiones.
- RF-02.3: Los ejercicios se pueden reordenar dentro de la sesión mediante arrastre.
- RF-02.4: El entrenador puede visualizar la lista de sus plantillas en tiempo real.

#### RF-03 Ejecución de entrenamientos (Atleta)
- RF-03.1: El atleta visualiza la lista de entrenamientos asignados con su estado.
- RF-03.2: El atleta puede acceder al detalle de un entrenamiento y ver el resumen de ejercicios.
- RF-03.3: Al iniciar un entrenamiento, la app guía al atleta con un temporizador de cuenta atrás que distingue la fase de preparación (azul) y la fase de apuntado (rojo).
- RF-03.4: Al finalizar el tiempo de apuntado, el atleta introduce la puntuación del disparo (0.0–10.9).
- RF-03.5: Al completar todas las series, se muestra un resumen con total y media, y se puede guardar el resultado con observaciones.

#### RF-04 Panel del entrenador
- RF-04.1: El entrenador visualiza la lista de atletas vinculados.
- RF-04.2: Al seleccionar un atleta, se muestra su perfil con estadísticas globales y el historial de resultados en tiempo real.
- RF-04.3: El entrenador puede añadir observaciones técnicas a cada resultado.

#### RF-05 Biblioteca técnica
- RF-05.1: Todos los usuarios pueden acceder a la biblioteca de recursos.
- RF-05.2: Los recursos se pueden filtrar por categoría (Técnica, Equipamiento, Reglamento, Mentalidad, Físico).
- RF-05.3: Al seleccionar un recurso, se muestra el contenido completo con formato de artículo.

### 3.3 Requisitos no funcionales

| Código | Categoría | Descripción |
|---|---|---|
| RNF-01 | Rendimiento | Las pantallas con streams de Firestore deben mostrar datos en menos de 2 segundos en condiciones normales de red. |
| RNF-02 | Usabilidad | La interfaz debe ser navegable sin manual por usuarios sin conocimientos técnicos. |
| RNF-03 | Portabilidad | La app debe funcionar en Android 8.0+ e iOS 14+. |
| RNF-04 | Seguridad | Los datos de cada usuario solo deben ser accesibles por él mismo y, en el caso del atleta, por su entrenador asignado. |
| RNF-05 | Escalabilidad | La arquitectura de Firestore debe permitir ampliar el número de colecciones sin refactorización mayor. |
| RNF-06 | Mantenibilidad | El código debe seguir el patrón MVC/MVVM con separación clara de modelos, servicios, controllers y vistas. |

### 3.4 Casos de uso

-hay que hacer los dibujooooos draw io

#### CU-01: Registrarse
- **Actor:** Usuario nuevo
- **Precondición:** La app está abierta en la pantalla de login.
- **Flujo principal:**
  1. El usuario pulsa "Crear cuenta".
  2. El sistema muestra el formulario de registro.
  3. El usuario introduce nombre, apellidos, email, contraseña y selecciona su rol.
  4. El sistema valida los campos y crea la cuenta en Firebase Auth.
  5. El sistema crea el documento del usuario en Firestore.
  6. El sistema redirige al home correspondiente al rol.
- **Flujo alternativo:** Si el email ya está registrado, el sistema muestra el error "Este correo ya está registrado".

#### CU-02: Crear entrenamiento
- **Actor:** Entrenador
- **Precondición:** El entrenador está autenticado.
- **Flujo principal:**
  1. El entrenador navega a "Entrenamientos" y pulsa "+".
  2. El sistema muestra el formulario de creación.
  3. El entrenador introduce nombre, descripción y fecha opcional.
  4. El entrenador añade ejercicios uno a uno mediante el diálogo de ejercicio.
  5. El entrenador pulsa "Guardar".
  6. El sistema persiste los ejercicios y el entrenamiento en Firestore.
  7. El sistema navega de vuelta al listado.

#### CU-03: Ejecutar entrenamiento con temporizador
- **Actor:** Atleta
- **Precondición:** El atleta tiene al menos un entrenamiento asignado.
- **Flujo principal:**
  1. El atleta selecciona un entrenamiento y pulsa "Iniciar".
  2. El sistema muestra la pantalla de inicio del primer ejercicio.
  3. El atleta pulsa "Iniciar ejercicio".
  4. El sistema inicia la cuenta atrás de preparación.
  5. Al terminar la preparación, el sistema inicia la cuenta atrás de apuntado.
  6. Al terminar el apuntado, el sistema solicita la puntuación del disparo.
  7. Los pasos 4–6 se repiten por cada disparo de cada serie.
  8. Al completar todas las series, el sistema muestra el resumen.
  9. El atleta introduce observaciones y guarda el resultado.

#### CU-04: Revisar progreso de atleta
- **Actor:** Entrenador
- **Precondición:** El entrenador tiene atletas vinculados con resultados registrados.
- **Flujo principal:**
  1. El entrenador navega al "Panel" y selecciona un atleta.
  2. El sistema muestra el perfil con estadísticas globales.
  3. El entrenador expande un resultado para ver el detalle por series.
  4. El entrenador escribe sus observaciones y pulsa "Guardar".
  5. El sistema actualiza el documento en Firestore.

---

## 4. SOLUCIÓN PROPUESTA

### 4.1 Arquitectura general

ShootTrack sigue una arquitectura en capas inspirada en el patrón **MVVM (Model-View-ViewModel)**, adaptada al ecosistema Flutter con Provider:

```
┌──────────────────────────────────────────────┐
│                  VISTAS (Views)               │
│  login · register · homes · entrenamientos   │
│  tracking · panel entrenador · biblioteca    │
└────────────────────┬─────────────────────────┘
                     │ context.watch / context.read
┌────────────────────▼─────────────────────────┐
│              CONTROLLERS                      │
│  AuthController · EntrenamientoController    │
│  TrackingController · CoachController        │
│  BibliotecaController                        │
└────────────────────┬─────────────────────────┘
                     │ llamadas a métodos
┌────────────────────▼─────────────────────────┐
│               SERVICIOS                       │
│       AuthService · FirestoreService         │
└────────────────────┬─────────────────────────┘
                     │ SDK calls
┌────────────────────▼─────────────────────────┐
│              FIREBASE BACKEND                 │
│   Authentication · Firestore · Storage       │
└──────────────────────────────────────────────┘
```

**Flujo de datos:**
- Las vistas observan los controllers mediante `context.watch<T>()` y se reconstruyen automáticamente cuando el estado cambia.
- Los controllers invocan los servicios para operaciones de red y llaman a `notifyListeners()` tras actualizar su estado interno.
- Los servicios encapsulan todo acceso a Firebase, exponiendo tanto métodos `Future<T>` (operaciones puntuales) como `Stream<T>` (datos en tiempo real).

### 4.2 Estructura de directorios

```
lib/
├── app/
│   ├── app.dart          # MyApp con MultiProvider y MaterialApp.router
│   └── router.dart       # GoRouter con rutas y lógica de redirección
├── controllers/
│   ├── auth_controller.dart
│   ├── entrenamiento_controller.dart
│   ├── tracking_controller.dart
│   ├── coach_controller.dart
│   └── biblioteca_controller.dart
├── core/
│   └── constants/
│       ├── app_colors.dart
│       ├── app_routes.dart
│       └── app_strings.dart
├── models/
│   ├── usuario.dart
│   ├── atleta.dart
│   ├── ejercicio.dart
│   ├── entrenamiento.dart
│   ├── resultado.dart
│   └── recurso.dart
├── services/
│   ├── auth_service.dart
│   └── firestore_service.dart
└── views/
    ├── auth/
    │   ├── login_view.dart
    │   └── register_view.dart
    ├── home/
    │   ├── home_atleta_view.dart
    │   └── home_entrenador_view.dart
    ├── training/
    │   ├── entrenamientos_view.dart
    │   ├── crear_entrenamiento_view.dart
    │   └── detalle_entrenamiento_view.dart
    ├── tracking/
    │   └── tracking_view.dart
    ├── coach/
    │   ├── panel_entrenador_view.dart
    │   └── perfil_atleta_view.dart
    └── library/
        ├── biblioteca_view.dart
        └── detalle_recurso_view.dart
```

### 4.3 Modelo de datos (Firestore)

La base de datos en Cloud Firestore se organiza en colecciones de nivel raíz. Se elige una estructura plana (no anidada) para facilitar las consultas y evitar el límite de un documento por segundo en colecciones con subcolecciones muy activas.

#### Colección `usuarios`
```
usuarios/{uid}
  nombre:          String
  apellidos:       String
  email:           String
  rol:             String  ("entrenador" | "atleta")
  fechaCreacion:   Timestamp
  fotoPerfil:      String?  (URL Firebase Storage)
```

#### Colección `atletas`
```
atletas/{uid}
  entrenadorId:        String  (uid del entrenador)
  categoria:           String  ("Juvenil" | "Junior" | "Absoluto" | ...)
  modalidad:           String  ("Pistola 10m" | "Pistola 25m" | ...)
  licenciaFederativa:  String?
  fechaVinculacion:    Timestamp
```

#### Colección `ejercicios`
```
ejercicios/{id}
  nombre:            String
  descripcion:       String
  tiempoPreparacion: Number  (segundos)
  tiempoApuntado:    Number  (segundos)
  numDisparos:       Number
  repeticiones:      Number
  notas:             String?
```

#### Colección `entrenamientos`
```
entrenamientos/{id}
  nombre:           String
  descripcion:      String
  entrenadorId:     String
  atletaId:         String?  (null = plantilla)
  ejerciciosIds:    Array<String>
  fechaCreacion:    Timestamp
  fechaProgramada:  Timestamp?
  estado:           String  ("pendiente" | "enProgreso" | "completado")
```

#### Colección `resultados`
```
resultados/{id}
  entrenamientoId:          String
  atletaId:                 String
  ejercicioId:              String
  fecha:                    Timestamp
  series: [
    {
      numSerie:  Number
      disparos:  Array<Number>  (puntuaciones 0.0–10.9)
    }
  ]
  observacionesAtleta:       String?
  observacionesEntrenador:   String?
```

#### Colección `recursos`
```
recursos/{id}
  titulo:           String
  resumen:          String
  contenido:        String
  categoria:        String  ("tecnica" | "equipamiento" | ...)
  autor:            String
  imagenUrl:        String?
  fechaPublicacion: Timestamp
```

### 4.4 Diagrama Entidad-Relación (lógico)

```
USUARIO ──< ATLETA >── ENTRENADOR (USUARIO)
                │
                │ asignado a
                ▼
         ENTRENAMIENTO ──< CONTIENE >── EJERCICIO
                │
                │ genera
                ▼
            RESULTADO ──< COMPUESTO >── SERIE ──< INCLUYE >── DISPARO
```

Relaciones:
- Un **Entrenador** puede tener muchos **Atletas**.
- Un **Atleta** tiene exactamente un **Entrenador** asignado.
- Un **Entrenamiento** puede contener muchos **Ejercicios** (referenciados por ID).
- Un **Entrenamiento** puede estar asignado a un **Atleta** (o ser plantilla sin asignar).
- Un **Resultado** contiene varias **Series** (datos anidados en Firestore).
- Una **Serie** contiene los valores decimales de cada disparo.

### 4.5 Diseño de la navegación

GoRouter gestiona la navegación con redirección automática basada en el estado de sesión:

```
/login                ← punto de entrada si no hay sesión
/register
/home-atleta          ← redirige aquí si rol == atleta
/home-entrenador      ← redirige aquí si rol == entrenador
/entrenamientos
/entrenamientos/nuevo
/entrenamientos/:id
/tracking/:id
/panel-entrenador
/atleta/:id
/biblioteca
/biblioteca/:id
```

Reglas de redirección:
- Usuario **no autenticado** → siempre `/login`.
- Usuario **autenticado** en `/login` o `/register` → home por rol.
- Usuario autenticado en cualquier ruta protegida → sin redirección.

### 4.6 Tecnologías utilizadas

| Tecnología | Versión | Uso |
|---|---|---|
| Flutter | 3.x | Framework UI multiplataforma |
| Dart | 3.x | Lenguaje de programación |
| Firebase Auth | ^5.0.0 | Autenticación de usuarios |
| Cloud Firestore | ^5.0.0 | Base de datos NoSQL en tiempo real |
| Firebase Storage | ^12.0.0 | Almacenamiento de imágenes |
| Provider | ^6.1.2 | Gestión de estado |
| GoRouter | ^14.0.0 | Navegación declarativa |
| Material Design 3 | — | Sistema de diseño visual |

---

## 5. PLAN DE TRABAJO

### 5.1 Metodología de desarrollo

El proyecto se ha desarrollado siguiendo una metodología **iterativa e incremental** con sprints semanales de una semana de duración. Al inicio de cada sprint se definían las funcionalidades a implementar y al final se revisaban los resultados para ajustar el plan.

Esta metodología es adecuada para un proyecto individual de TFG porque:
- Permite entregar funcionalidades completas y demostrables en cada iteración.
- Facilita la detección temprana de problemas técnicos.
- Se adapta a los cambios de alcance que surgen durante el desarrollo.

### 5.2 Planificación temporal (diagrama de Gantt)

| Semana | Actividad |
|---|---|
| 1 | Análisis de requisitos y redacción de la propuesta de TFG |
| 2 | Configuración del proyecto Flutter y Firebase. Estructura de directorios |
| 3 | Modelado de datos: clases Dart con serialización Firestore |
| 4 | Capa de servicios: AuthService y FirestoreService |
| 5 | Módulo de autenticación: login, registro, controllers, navegación |
| 6 | Módulo de entrenamientos: creación de sesiones y ejercicios |
| 7 | Módulo de tracking: temporizador por fases y registro de resultados |
| 8 | Panel del entrenador: lista de atletas, perfil y observaciones |
| 9 | Biblioteca técnica: recursos por categoría y vista de detalle |
| 10 | Pruebas funcionales, corrección de errores y refinamiento de UI |
| 11 | Redacción de la memoria del TFG |
| 12 | Revisión final, maquetación y entrega |

### 5.3 Presupuesto estimado

| Concepto | Detalle | Coste estimado |
|---|---|---|
| **Desarrollo** | 200 horas × 15 €/h (tarifa junior) | 3.000 € |
| **Firebase** | Plan Spark (gratuito hasta límites de cuota) | 0 € |
| **Apple Developer Program** | Necesario para publicar en App Store | 99 €/año |
| **Google Play** | Tarifa de registro único | 25 € |
| **Licencia Android Studio** | Gratuito | 0 € |
| **Diseño de icono y assets** | Canva Pro (plan estudiante) | 0 € |
| **TOTAL** | | **~3.124 €** |

> Nota: el coste de desarrollo refleja el valor de mercado del trabajo realizado. El proyecto ha sido desarrollado por el propio alumno como trabajo académico sin compensación económica.

---

## 6. DESARROLLO DE LA SOLUCIÓN

### 6.1 Configuración del proyecto

El proyecto se inicializó con `flutter create tfg` y se configuró Firebase mediante la CLI de FlutterFire (`flutterfire configure`), que genera el fichero `firebase_options.dart` con las claves de configuración por plataforma.

Las dependencias principales se declaran en `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0
  provider: ^6.1.2
  go_router: ^14.0.0
```

Firebase se inicializa en `main.dart` antes de ejecutar la aplicación:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
```

### 6.2 Capa de modelos

Se han definido seis modelos de datos en `lib/models/`, todos siguiendo el mismo patrón:
- Constructor con parámetros nombrados y `required` donde aplica.
- Factory constructor `fromMap(Map<String, dynamic> map, String id)` para deserializar desde Firestore.
- Método `toMap()` para serializar hacia Firestore.
- Método `copyWith()` para actualizaciones inmutables.

El modelo `Resultado` incorpora la clase anidada `Serie` que agrupa los disparos de una repetición. Esta clase también tiene sus propios `fromMap`/`toMap` para serialización como campo anidado (no subcolección).

### 6.3 Capa de servicios

`FirestoreService` centraliza todas las operaciones de base de datos. Se han implementado dos tipos de operaciones:

**Operaciones puntuales (Future):** para lectura/escritura de documentos individuales donde no se necesita actualización en tiempo real (cargar un ejercicio por ID, guardar un resultado, actualizar observaciones).

**Operaciones en tiempo real (Stream):** para listados que deben reflejar cambios inmediatamente (lista de atletas del entrenador, entrenamientos del atleta, historial de resultados). Los streams se crean con `.snapshots()` de Firestore y se transforman con `.map()` al tipo correspondiente.

`AuthService` encapsula Firebase Auth y orquesta la creación del perfil en Firestore tras el registro, garantizando la consistencia entre ambos sistemas.

### 6.4 Gestión de estado con Provider

Cada módulo funcional tiene su propio `ChangeNotifier`:

- **AuthController:** estado de sesión, usuario autenticado, loading y errores de auth.
- **EntrenamientoController:** operaciones CRUD de entrenamientos y streams de plantillas/sesiones.
- **TrackingController:** máquina de estados del temporizador (ver sección 6.5).
- **CoachController:** carga de perfiles de atletas y gestión de observaciones.
- **BibliotecaController:** filtrado por categoría y siembra de contenido inicial.

Todos se registran en `MultiProvider` en `app.dart` y son accesibles desde cualquier widget con `context.read<T>()` (sin rebuild) o `context.watch<T>()` (con rebuild al cambiar).

### 6.5 Módulo de tracking: máquina de estados

El temporizador de tiro es el componente más singular del proyecto. Se implementa en `TrackingController` como una máquina de estados finitos con los siguientes estados:

```
idle ──[iniciar()]──► preparacion
                           │
                    (countdown = 0)
                           │
                           ▼
                       apuntado
                           │
                    (countdown = 0)
                           │
                           ▼
                       registro ──[registrarDisparo(pts)]──►
                           │                                │
                    (último disparo de todas las series)    │
                           │                                │ (hay más disparos)
                           ▼                                └──► preparacion
                       completado
```

El timer interno usa `Timer.periodic` de `dart:async` con período de 1 segundo. En cada tick decrementa `_segundosRestantes` y notifica a los listeners. Al llegar a 0 cancela el timer y ejecuta el callback de transición de estado.

La interfaz reacciona a cada estado mostrando una pantalla diferente mediante un `switch` sobre `ctrl.fase`:

```dart
return switch (ctrl.fase) {
  FaseEjercicio.idle       => _PantallaInicio(...),
  FaseEjercicio.preparacion ||
  FaseEjercicio.apuntado   => _PantallaTemporizador(...),
  FaseEjercicio.registro   => _PantallaRegistro(...),
  FaseEjercicio.completado => _PantallaCompletado(...),
};
```

### 6.6 Biblioteca técnica con siembra de datos

La biblioteca incluye un mecanismo de inicialización automática: al entrar en la pantalla por primera vez, `BibliotecaController.sembrarContenido()` verifica si la colección `recursos` de Firestore está vacía y, en ese caso, crea los seis artículos técnicos predefinidos. Esto garantiza que la app tenga contenido útil desde el primer uso sin necesidad de un panel de administración.

### 6.7 Tema visual

La aplicación usa **Material Design 3** configurado globalmente en `app.dart`. Los colores principales están centralizados en `AppColors` para facilitar futuros cambios de branding. Los estilos de `InputDecoration`, `Card` y botones se definen una sola vez en el `ThemeData` para consistencia en toda la UI.

---

## 7. DESPLIEGUE E INSTALACIÓN

### 7.1 Requisitos previos

Para compilar y ejecutar ShootTrack se necesita:

- **Flutter SDK** 3.0.0 o superior ([flutter.dev](https://flutter.dev))
- **Android Studio** 2022+ con plugin de Flutter y Dart instalados
- **JDK 17** (incluido en Android Studio)
- **Android SDK** nivel API 26 (Android 8.0) o superior
- **Xcode 14+** para compilar en iOS (solo macOS)
- Cuenta de **Firebase** con proyecto configurado

### 7.2 Configuración de Firebase

1. Crear un proyecto en [console.firebase.google.com](https://console.firebase.google.com).
2. Activar **Authentication** → proveedor **Email/Contraseña**.
3. Crear la base de datos en **Firestore** → modo prueba (o configurar reglas de seguridad).
4. Añadir aplicaciones Android e iOS al proyecto Firebase.
5. Instalar la CLI de FlutterFire:
   ```bash
   dart pub global activate flutterfire_cli
   ```
6. Configurar Firebase en el proyecto:
   ```bash
   flutterfire configure
   ```
   Esto genera `lib/firebase_options.dart` automáticamente.

### 7.3 Instalación y ejecución en desarrollo

```bash
# 1. Clonar el repositorio
git clone <url-del-repositorio>
cd tfg

# 2. Instalar dependencias
flutter pub get

# 3. Conectar un dispositivo o iniciar un emulador

# 4. Ejecutar la app
flutter run
```

### 7.4 Generación del APK (Android)

```bash
# APK de debug (para pruebas)
flutter build apk --debug

# APK de release (para distribución)
flutter build apk --release
```

El fichero generado se encuentra en `build/app/outputs/flutter-apk/app-release.apk`.

### 7.5 Generación del IPA (iOS)

```bash
# Solo en macOS con Xcode configurado
flutter build ios --release
```

Para distribución en App Store se requiere una cuenta de Apple Developer.

### 7.6 Reglas de seguridad de Firestore (recomendadas para producción)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Un usuario solo puede leer/escribir su propio perfil
    match /usuarios/{uid} {
      allow read, write: if request.auth.uid == uid;
    }

    // El atleta puede leer su perfil; el entrenador puede leerlo si es su entrenadorId
    match /atletas/{uid} {
      allow read: if request.auth.uid == uid
                  || request.auth.uid == resource.data.entrenadorId;
      allow write: if request.auth.uid == uid;
    }

    // Entrenamientos visibles por entrenador y atleta asignado
    match /entrenamientos/{id} {
      allow read: if request.auth.uid == resource.data.entrenadorId
                  || request.auth.uid == resource.data.atletaId;
      allow write: if request.auth.uid == resource.data.entrenadorId;
    }

    // Resultados: el atleta escribe, el entrenador puede añadir observaciones
    match /resultados/{id} {
      allow create: if request.auth.uid == request.resource.data.atletaId;
      allow read, update: if request.auth.uid == resource.data.atletaId
                          || request.auth.uid == resource.data.entrenadorId;
    }

    // Biblioteca: lectura pública para usuarios autenticados
    match /recursos/{id} {
      allow read: if request.auth != null;
      allow write: if false; // Solo administradores (manual por consola)
    }
  }
}
```

### 7.7 Manual de usuario básico

#### Para el entrenador:
1. Registrarse seleccionando el rol **Entrenador**.
2. Desde el home, acceder a **Crear entrenamiento** para diseñar una sesión.
3. Añadir ejercicios con los parámetros de temporización deseados.
4. En **Mis atletas** revisar el progreso y añadir observaciones.

#### Para el atleta:
1. Registrarse seleccionando el rol **Atleta** (el entrenador deberá vincularlo manualmente desde Firestore hasta implementar el sistema de invitaciones).
2. Acceder a **Mis entrenamientos** para ver las sesiones asignadas.
3. Pulsar **Iniciar entrenamiento** y seguir el temporizador.
4. Introducir la puntuación de cada disparo cuando se solicite.
5. Guardar el resultado con observaciones opcionales al finalizar.

---

## 8. EVOLUCIÓN Y TRABAJO FUTURO

A continuación se detallan las extensiones identificadas durante el desarrollo que quedan fuera del alcance del TFG pero que aumentarían significativamente el valor de la aplicación:

### 8.1 Sistema de invitaciones entrenador-atleta
Actualmente la vinculación atleta-entrenador requiere intervención manual en Firestore. Se propone implementar un sistema de códigos de invitación donde el entrenador genera un código único y el atleta lo introduce al registrarse.

### 8.2 Módulo de competiciones
Añadir un módulo específico para el registro de resultados en competición oficial (60 disparos + final de 24), con comparativa entre entrenamiento y competición para identificar el impacto de la presión competitiva en el rendimiento.

### 8.3 Integración con dianas electrónicas
Conectar con sistemas de diana electrónica (Sius Ascor, Megalink) mediante Bluetooth o API REST para registrar automáticamente la puntuación de cada disparo sin intervención manual del atleta.

### 8.4 Análisis estadístico avanzado
Implementar gráficas de evolución temporal (puntuación media por semana), análisis de consistencia (desviación típica por serie) y comparativa entre atletas del mismo entrenador.

### 8.5 Notificaciones push
Notificar al atleta cuando el entrenador le asigna un nuevo entrenamiento o añade observaciones a un resultado, usando Firebase Cloud Messaging.

### 8.6 Modo offline
Implementar persistencia local con Firestore offline cache, de modo que el atleta pueda ejecutar entrenamientos sin conexión y sincronizar los resultados al recuperar la red.

### 8.7 Localización (i18n)
Adaptar la app para múltiples idiomas usando el sistema de internacionalización de Flutter (`flutter_localizations`), comenzando por inglés para facilitar su uso en competiciones internacionales.

---

## 9. BIBLIOGRAFÍA (formato APA 7ª edición)

Dart team. (2024). *Dart documentation*. Google LLC. https://dart.dev/guides

Firebase team. (2024). *Firebase documentation: Cloud Firestore*. Google LLC. https://firebase.google.com/docs/firestore

Firebase team. (2024). *Firebase documentation: Authentication*. Google LLC. https://firebase.google.com/docs/auth

Flutter team. (2024). *Flutter documentation*. Google LLC. https://docs.flutter.dev

GoRouter team. (2024). *GoRouter package documentation*. pub.dev. https://pub.dev/packages/go_router

International Shooting Sport Federation. (2023). *ISSF technical and competition rules*. ISSF. https://www.issf-sports.org/theissf/rules.ashx

Nystrom, R. (2014). *Game programming patterns*. Genever Benning. https://gameprogrammingpatterns.com

Provider team. (2024). *Provider package documentation*. pub.dev. https://pub.dev/packages/provider

Real Federación Española de Tiro Olímpico. (2024). *Reglamentos deportivos*. RFEDETO. https://www.rfedeto.es

Windmill, E. (2020). *Flutter in action*. Manning Publications.

---

*Fin de la memoria*
