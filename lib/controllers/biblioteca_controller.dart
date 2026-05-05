/// Controller de la biblioteca técnica de tiro olímpico.
///
/// Gestiona la carga de recursos por categoría y la inicialización
/// del contenido inicial de la biblioteca mediante [sembrarContenido],
/// que crea los recursos base en Firestore si la colección está vacía.
///
/// Los streams en tiempo real permiten filtrar por [CategoriaRecurso]
/// sin necesidad de recargar manualmente la pantalla.
import 'package:flutter/foundation.dart';
import 'package:tfg/models/recurso.dart';
import 'package:tfg/services/firestore_service.dart';

class BibliotecaController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  /// Categoría actualmente seleccionada en el filtro.
  /// null significa "todas las categorías".
  CategoriaRecurso? _categoriaFiltro;
  CategoriaRecurso? get categoriaFiltro => _categoriaFiltro;

  /// true mientras se está sembrando el contenido inicial.
  bool _sembrando = false;
  bool get sembrando => _sembrando;

  // ─────────────────────────────────────────────
  // STREAMS
  // ─────────────────────────────────────────────

  /// Stream con los recursos según el filtro activo.
  ///
  /// Si [_categoriaFiltro] es null, devuelve todos los recursos.
  /// Si tiene valor, filtra por esa categoría.
  Stream<List<Recurso>> get recursos => _categoriaFiltro == null
      ? _firestoreService.obtenerRecursos()
      : _firestoreService.recursosPorCategoria(_categoriaFiltro!);

  // ─────────────────────────────────────────────
  // FILTRADO
  // ─────────────────────────────────────────────

  /// Establece el filtro de categoría y notifica a los widgets suscritos.
  ///
  /// Pasar null elimina el filtro y muestra todos los recursos.
  void filtrarPorCategoria(CategoriaRecurso? categoria) {
    _categoriaFiltro = categoria;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // CONTENIDO INICIAL
  // ─────────────────────────────────────────────

  /// Siembra el contenido inicial de la biblioteca si la colección está vacía.
  ///
  /// Se llama al entrar a la pantalla de biblioteca por primera vez.
  /// Evita duplicados comprobando primero si ya existen documentos.
  Future<void> sembrarContenido() async {
    // Evitar múltiples ejecuciones simultáneas
    if (_sembrando) return;
    _sembrando = true;
    notifyListeners();

    try {
      // Comparar lo existente con el set esperado: si una siembra previa se
      // interrumpió, sembrar solo los recursos que falten (idempotente por título).
      final actuales = await _firestoreService.obtenerRecursos().first;
      final iniciales = _recursosIniciales();
      if (actuales.length >= iniciales.length) return;

      final titulosExistentes =
          actuales.map((r) => r.titulo).toSet();
      for (final recurso in iniciales) {
        if (titulosExistentes.contains(recurso.titulo)) continue;
        await _firestoreService.crearRecurso(recurso);
      }
    } catch (_) {
      // Si falla la siembra (red, permisos), no romper el estado de la app
    } finally {
      _sembrando = false;
      notifyListeners();
    }
  }

  /// Devuelve la lista de recursos predefinidos para la carga inicial.
  ///
  /// Este contenido cubre las áreas fundamentales del tiro olímpico de pistola
  /// y sirve como base de conocimiento para entrenadores y atletas.
  List<Recurso> _recursosIniciales() {
    final ahora = DateTime.now();
    return [
      // ── TÉCNICA ───────────────────────────────
      Recurso(
        id: '',
        titulo: 'Fundamentos de la postura en pistola 10m',
        resumen:
            'Análisis de los puntos clave de la postura correcta para maximizar '
            'la estabilidad y minimizar la fatiga durante la competición.',
        contenido: '''La postura es la base de toda técnica de tiro. '
Una postura deficiente genera tensión muscular y oscilación, lo que penaliza directamente la puntuación.

PIES Y BASE DE SUSTENTACIÓN
Los pies deben estar separados a la anchura de los hombros, con una apertura de 60-90° respecto a la línea de tiro. El peso se distribuye de forma equitativa entre ambos pies.

RODILLAS Y CADERAS
Las rodillas ligeramente flexionadas absorben microoscilaciones. Las caderas permanecen relajadas y perpendiculares al objetivo.

TORSO Y HOMBROS
El torso gira hacia la línea de tiro sin forzar la columna. Los hombros deben estar bajos y sin tensión. Elevar el hombro del brazo armado es un error frecuente que provoca fatiga.

BRAZO DE TIRO
El brazo se extiende de forma natural, sin bloquear el codo. La muñeca queda alineada con el antebrazo. Mantener el codo muy rígido provoca temblor.

CABEZA Y VISIÓN
La cabeza se gira de forma natural hacia el objetivo. Forzar la posición del cuello genera tensión y distorsiona la alineación de mira.

RESUMEN DE ERRORES FRECUENTES
- Inclinarse hacia adelante para compensar el peso de la pistola.
- Elevar el hombro al extender el brazo.
- Bloquear la respiración durante toda la fase de apuntado.
- Tensar los dedos de la mano libre.''',
        categoria: CategoriaRecurso.tecnica,
        autor: 'Equipo técnico ShootTrack',
        fechaPublicacion: ahora,
      ),

      Recurso(
        id: '',
        titulo: 'El ciclo del disparo: fases y temporización',
        resumen:
            'Descripción detallada de cada fase del ciclo de un disparo '
            'y cómo la correcta temporización mejora la consistencia.',
        contenido: '''Cada disparo en tiro olímpico sigue un ciclo definido '
que debe automatizarse mediante la práctica repetida. La consistencia en la ejecución de este ciclo es más importante que la perfección en un disparo aislado.

FASE 1 – PREPARACIÓN (pre-disparo)
El tirador sube la pistola hasta la posición de apuntado. En esta fase se regulariza la respiración: se realiza una inspiración profunda, se expulsa parte del aire y se retiene el resto. La tensión muscular debe ser mínima.

FASE 2 – APUNTADO
Se busca la alineación de alza, punto de mira y centro de la diana. En pistola electrónica de 10m, el área de 10 tiene un diámetro de 11.5mm. La mirada se enfoca en el punto de mira, no en la diana.

FASE 3 – PRESIÓN DEL GATILLO
La presión del dedo índice es progresiva y uniforme, sin «pellizcar» el gatillo. La pistola debe sorprender al tirador en el momento del disparo.

FASE 4 – SEGUIMIENTO (follow-through)
Tras el disparo, el tirador mantiene la postura y continúa mirando a través de la mira durante 1-2 segundos. Este hábito confirma que no se anticipó el disparo y permite analizar la trayectoria.

TEMPORIZACIÓN EN ENTRENAMIENTO
El uso de un temporizador (como el de esta aplicación) condiciona los tiempos de preparación y apuntado, entrenando al atleta para ejecutar el ciclo de forma autónoma y reproducible en competición.''',
        categoria: CategoriaRecurso.tecnica,
        autor: 'Equipo técnico ShootTrack',
        fechaPublicacion: ahora,
      ),

      // ── EQUIPAMIENTO ──────────────────────────
      Recurso(
        id: '',
        titulo: 'Pistolas electrónicas de 10m: guía de selección',
        resumen:
            'Comparativa de los principales modelos de pistola electrónica '
            'homologada para competición según la normativa ISSF.',
        contenido: '''Las pistolas electrónicas de aire comprimido (4.5mm) '
son el material reglamentario para la modalidad de pistola 10m en categorías de desarrollo y absoluto.

NORMATIVA ISSF
El peso máximo de la pistola con todos los accesorios es de 500g. El gatillo no puede ser inferior a 500g de presión. La culata no puede superar la línea de la muñeca. Consulta el reglamento ISSF actualizado para requisitos de temporada.

MODELOS HABITUALES EN COMPETICIÓN
- Feinwerkbau AW93 / P8X: referencia en precisión, disponible en versiones para mano derecha e izquierda.
- Walther LP400 / LP500: amplia variedad de empuñaduras y configuraciones.
- Steyr LP50 / EVO 10: excelente equilibrio y calidad de gatillo.
- Pardini HP: opción con buena relación calidad-precio para iniciación federada.

MANTENIMIENTO BÁSICO
- Revisar la carga del depósito de CO₂ o del cilindro de aire comprimido antes de cada sesión.
- Limpiar el cañón con un paño seco tras cada sesión de entrenamiento.
- Revisar la tensión del gatillo periódicamente con un medidor homologado.
- Almacenar en estuche rígido, nunca en horizontal sobre superficies duras.

EQUIPAMIENTO COMPLEMENTARIO
- Monóculo o telescopio de tiro: permite analizar impactos sin acercarse a la diana.
- Anteojeras y orejeras: reducen distracciones visuales y sonoras.
- Guante de tiro: mejora la estabilidad reduciendo la transferencia de temperatura y humedad.
- Zapatos de tiro: suela plana con soporte lateral para mejorar la base de sustentación.''',
        categoria: CategoriaRecurso.equipamiento,
        autor: 'Equipo técnico ShootTrack',
        fechaPublicacion: ahora,
      ),

      // ── REGLAMENTO ────────────────────────────
      Recurso(
        id: '',
        titulo: 'Reglamento ISSF: pistola 10m resumen',
        resumen:
            'Resumen de las normas de competición de pistola de aire 10m '
            'según el reglamento vigente de la ISSF.',
        contenido: '''La International Shooting Sport Federation (ISSF) '
regula todas las competiciones de tiro olímpico. A continuación se resumen los puntos más relevantes para la modalidad de pistola 10m.

FORMATO DE COMPETICIÓN
- Fase de clasificación: 60 disparos en 75 minutos (senior), 40 disparos en 50 minutos (junior).
- Fase final: 24 disparos en formato de eliminación directa (1 disparo por serie).
- Los 8 mejores clasificados acceden a la final.

PUNTUACIÓN ELECTRÓNICA
- El valor de cada disparo se registra con un decimal (ej. 9.8, 10.2).
- El 10 interior (X) puntúa 10.9 puntos en sistemas electrónicos.
- No existe el «0» por fallo de disparo en tiempo: el disparo cuenta aunque sea bajo.

SANCIONES HABITUALES
- Disparo fuera de tiempo: penalización de 2 puntos.
- Exceso de peso de la pistola: descalificación del equipo.
- Comportamiento antideportivo: tarjeta amarilla / roja según gravedad.

DISTANCIA Y DIANA
- Distancia reglamentaria: 10 metros exactos.
- Diámetro del negro (zonas 7-10): 59.5mm.
- Diámetro del 10 interior (X): 11.5mm.

Para el reglamento completo y actualizado, consultar la web oficial de la ISSF: www.issf-sports.org''',
        categoria: CategoriaRecurso.reglamento,
        autor: 'Equipo técnico ShootTrack',
        fechaPublicacion: ahora,
      ),

      // ── MENTALIDAD ────────────────────────────
      Recurso(
        id: '',
        titulo: 'Gestión de la presión en competición',
        resumen:
            'Estrategias de preparación mental para mantener el rendimiento '
            'bajo presión y gestionar el nerviosismo en competición.',
        contenido: '''El tiro olímpico es uno de los deportes con mayor '
exigencia de control mental. La técnica puede ser perfecta en entrenamiento y desmoronarse ante la presión competitiva si no se trabaja la dimensión psicológica.

ACTIVACIÓN ÓPTIMA
Cada deportista tiene un nivel de activación (nerviosismo) óptimo para rendir. Niveles muy bajos generan falta de concentración; niveles muy altos producen temblor y precipitación. Identificar el propio nivel óptimo mediante el registro de sensaciones pre-competición es el primer paso.

RUTINA PRE-DISPARO
Establecer una rutina fija de preparación (mismos pasos, mismo orden, mismo tiempo) automatiza el proceso y reduce la influencia del estado emocional sobre la ejecución. La rutina actúa como un ancla psicológica.

FOCO ATENCIONAL
Durante la competición, el foco debe estar en el proceso (postura, respiración, presión del gatillo) y nunca en el resultado. Pensar en el marcador activa la ansiedad y distrae de la tarea.

RECUPERACIÓN ENTRE SERIES
Bajar la pistola, respirar profundamente, usar una palabra o gesto de reencuadre («siguiente», «listo») y volver a subir con mente en blanco es más efectivo que analizar el disparo anterior en el momento.

VISUALIZACIÓN
La visualización mental de disparos perfectos activa los mismos circuitos neuronales que el disparo real. Dedicar 5-10 minutos diarios a visualizar la rutina completa mejora la consistencia bajo presión.''',
        categoria: CategoriaRecurso.mentalidad,
        autor: 'Equipo técnico ShootTrack',
        fechaPublicacion: ahora,
      ),

      // ── FÍSICO ────────────────────────────────
      Recurso(
        id: '',
        titulo: 'Condición física específica para tiro olímpico',
        resumen:
            'Ejercicios de estabilidad, fuerza isométrica y control de la '
            'respiración adaptados a las exigencias del tiro olímpico.',
        contenido: '''Aunque el tiro olímpico no exige una condición '
cardiovascular elevada, la preparación física específica tiene un impacto directo en la puntuación. Los tres pilares son la estabilidad postural, la fuerza isométrica y el control de la respiración.

ESTABILIDAD POSTURAL
- Ejercicios de equilibrio unipodal: mejorar la estabilidad general de la cadena cinética.
- Planchas (isométrica de core): 3×45 segundos, progresando hasta 90 segundos.
- Ejercicios de propiocepción sobre superficie inestable (bosu, fitball).

FUERZA ISOMÉTRICA DEL BRAZO DE TIRO
- Sostener la pistola (o un peso equivalente) extendida durante 30 segundos × 5 series.
- Aumentar progresivamente el tiempo hasta 60 segundos sin temblor.
- Incluir variantes laterales para trabajar la estabilidad en todos los planos.

CONTROL DE LA RESPIRACIÓN
- Respiración diafragmática: inhalar 4s, retener 2s, exhalar 6s. 10 repeticiones.
- Entrenamiento con apnea controlada: practicar la retención de aire durante 8-10s.
- Coordinación respiración-pulso: disparar en el momento de menor aceleración cardíaca (entre latidos).

FRECUENCIA CARDÍACA Y RECUPERACIÓN
El entrenamiento aeróbico moderado (caminar rápido, ciclismo, natación) mejora la recuperación entre series y reduce la frecuencia cardíaca en reposo, disminuyendo la interferencia del pulso sobre la puntería.

NOTA
Evitar el entrenamiento intenso de fuerza los días previos a competición, ya que el temblor muscular post-esfuerzo penaliza directamente.''',
        categoria: CategoriaRecurso.fisico,
        autor: 'Equipo técnico ShootTrack',
        fechaPublicacion: ahora,
      ),
    ];
  }
}
