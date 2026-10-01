// Textos de ayuda de cada parámetro. Semántica verificada contra el backend:
// marcaje/evaluador.go, generador_sesiones.go y parametros_sesion.go.
import 'catalogo_parametros.dart';

const catalogoParametros = <InfoParametro>[
  InfoParametro(
    clave: 'holgura_entrada_antes_min',
    nombre: 'Apertura antes de la clase',
    grupo: GrupoParametro.entrada,
    unidad: 'min',
    minimo: 0,
    maximo: 120,
    porDefecto: 15,
    resumen: 'Cuántos minutos antes del inicio se puede marcar la entrada.',
    comoFunciona:
        'La ventana de entrada abre este número de minutos antes de la hora '
        'de inicio. Antes de ese momento la app muestra la cuenta regresiva y '
        'no deja marcar.',
    recomendacion:
        'Entre 10 y 15 minutos da tiempo de llegar al aula sin permitir '
        'marcar desde muy temprano.',
  ),
  InfoParametro(
    clave: 'holgura_entrada_despues_min',
    nombre: 'Cierre después del inicio',
    grupo: GrupoParametro.entrada,
    unidad: 'min',
    minimo: 0,
    maximo: 120,
    porDefecto: 15,
    resumen: 'Hasta cuántos minutos después del inicio se acepta la entrada.',
    comoFunciona:
        'La ventana de entrada cierra este número de minutos después de la '
        'hora de inicio. Pasado ese momento ya no se acepta el marcaje y la '
        'clase queda sin entrada; el docente puede radicar una justificación.'
        '',
    recomendacion:
        'Debe ser mayor o igual que el umbral de tardanza; si es menor, '
        'nadie alcanzaría a quedar como "tardanza".',
  ),
  InfoParametro(
    clave: 'umbral_tardanza_min',
    nombre: 'Umbral de tardanza',
    grupo: GrupoParametro.entrada,
    unidad: 'min',
    minimo: 0,
    maximo: 60,
    porDefecto: 10,
    resumen: 'Minutos después del inicio a partir de los cuales es tardanza.',
    comoFunciona:
        'Si el docente marca la entrada hasta este número de minutos después '
        'del inicio queda como Presente; si marca después, queda como '
        'Tardanza (siempre que la ventana siga abierta).',
    recomendacion: 'Un valor común es 10 minutos.',
  ),
  InfoParametro(
    clave: 'salida_obligatoria',
    nombre: 'Marcaje de salida',
    grupo: GrupoParametro.salida,
    porDefecto: 'DESACTIVADO',
    opciones: {
      'DESACTIVADO': 'Desactivado',
      'OPCIONAL': 'Opcional',
      'OBLIGATORIO': 'Obligatorio',
    },
    resumen: 'Si el docente marca también la salida de la clase.',
    comoFunciona:
        'Desactivado: solo se marca la entrada. Opcional u Obligatorio: la '
        'clase tiene además una ventana de salida alrededor de la hora de fin '
        '(definida por los dos parámetros siguientes) y la app ofrece marcar '
        'la salida. Hoy Opcional y Obligatorio se comportan igual: la falta '
        'de salida no genera una inasistencia.',
    recomendacion:
        'Actívelo si la institución necesita evidencia de que la clase '
        'duró completa.',
  ),
  InfoParametro(
    clave: 'holgura_salida_antes_min',
    nombre: 'Apertura de salida antes del fin',
    grupo: GrupoParametro.salida,
    unidad: 'min',
    minimo: 0,
    maximo: 60,
    porDefecto: 10,
    resumen: 'Cuántos minutos antes del fin se puede marcar la salida.',
    comoFunciona:
        'Solo aplica si el marcaje de salida está en Opcional u Obligatorio. '
        'La ventana de salida abre este número de minutos antes de la hora '
        'de fin.',
    recomendacion: 'Entre 5 y 10 minutos.',
  ),
  InfoParametro(
    clave: 'holgura_salida_despues_min',
    nombre: 'Cierre de salida después del fin',
    grupo: GrupoParametro.salida,
    unidad: 'min',
    minimo: 0,
    maximo: 120,
    porDefecto: 20,
    resumen: 'Hasta cuántos minutos después del fin se acepta la salida.',
    comoFunciona:
        'Solo aplica si el marcaje de salida está en Opcional u Obligatorio. '
        'La ventana de salida cierra este número de minutos después de la '
        'hora de fin.',
    recomendacion: 'Entre 15 y 20 minutos.',
  ),
  InfoParametro(
    clave: 'precision_gps_max_metros',
    nombre: 'Precisión GPS máxima',
    grupo: GrupoParametro.ubicacion,
    unidad: 'm',
    minimo: 5,
    maximo: 200,
    porDefecto: 35,
    resumen: 'Margen de error máximo del GPS para aceptar un marcaje.',
    comoFunciona:
        'El celular informa con qué margen de error conoce su ubicación. Si '
        'ese margen es mayor que este valor, el marcaje se rechaza y la app '
        'pide reintentar (por ejemplo, cerca de una ventana). Un número más '
        'bajo es más estricto.',
    recomendacion:
        'Entre 25 y 40 metros funciona en la mayoría de edificios; bajarlo '
        'demasiado genera rechazos dentro del aula.',
  ),
  InfoParametro(
    clave: 'buffer_perimetral_metros',
    nombre: 'Margen alrededor del aula',
    grupo: GrupoParametro.ubicacion,
    unidad: 'm',
    minimo: 0,
    maximo: 100,
    porDefecto: 10,
    aplicado: false,
    resumen: 'Distancia extra alrededor del polígono del aula.',
    comoFunciona:
        'Pensado para aceptar marcajes un poco por fuera del polígono del '
        'aula. Hoy cada aula usa el margen que se fija al guardar su polígono '
        '(10 m por defecto) y este parámetro todavía no lo cambia.',
    recomendacion: 'Déjelo en 10 metros.',
  ),
  InfoParametro(
    clave: 'promedio_lecturas_vertice',
    nombre: 'Lecturas por vértice',
    grupo: GrupoParametro.ubicacion,
    unidad: 'lecturas',
    minimo: 1,
    maximo: 20,
    porDefecto: 5,
    aplicado: false,
    resumen: 'Lecturas GPS que se promedian al capturar cada esquina del aula.',
    comoFunciona:
        'Pensado para el editor de aulas del celular: más lecturas por '
        'esquina dan un polígono más exacto. El editor todavía no lee este '
        'valor.',
    recomendacion: 'Déjelo en 5.',
  ),
  InfoParametro(
    clave: 'bloqueo_mock_location',
    nombre: 'Bloquear ubicación simulada',
    grupo: GrupoParametro.seguridad,
    porDefecto: true,
    resumen: 'Rechaza marcajes hechos con apps que falsean el GPS.',
    comoFunciona:
        'Si está en Sí y el celular reporta una ubicación simulada (apps de '
        '"Fake GPS"), el marcaje se rechaza.',
    recomendacion: 'Manténgalo en Sí.',
  ),
  InfoParametro(
    clave: 'bloqueo_dispositivo_rooteado',
    nombre: 'Bloquear celulares modificados',
    grupo: GrupoParametro.seguridad,
    porDefecto: false,
    resumen: 'Rechaza marcajes desde celulares rooteados o emuladores.',
    comoFunciona:
        'Si está en Sí, los marcajes de celulares con root o de emuladores '
        'se rechazan, porque en ellos es fácil falsear la ubicación.',
    recomendacion:
        'Actívelo cuando todos los docentes usen celulares de fábrica.',
  ),
  InfoParametro(
    clave: 'exigir_attestation',
    nombre: 'Verificar la app con Google (Play Integrity)',
    grupo: GrupoParametro.seguridad,
    porDefecto: false,
    resumen: 'Exige que Google confirme que la app y el celular son legítimos.',
    comoFunciona:
        'Si está en Sí, cada marcaje debe traer la verificación de Play '
        'Integrity. Requiere configurar PLAY_INTEGRITY_PACKAGE y '
        'PLAY_INTEGRITY_CREDENTIALS en el servidor; sin eso todos los '
        'marcajes se rechazan.',
    recomendacion: 'Actívelo solo después de configurar el servidor.',
  ),
  InfoParametro(
    clave: 'verificacion_complementaria',
    nombre: 'Verificación complementaria',
    grupo: GrupoParametro.seguridad,
    porDefecto: false,
    resumen: 'Pide además WiFi, Bluetooth o QR en aulas que lo tengan.',
    comoFunciona:
        'Si está en Sí, en las aulas que tengan configurada una red WiFi, '
        'baliza Bluetooth o código QR, el docente debe validar también ese '
        'elemento. Las clases virtuales no lo exigen.',
    recomendacion: 'Útil en aulas donde el GPS es poco confiable.',
  ),
  InfoParametro(
    clave: 'offline_permitido',
    nombre: 'Marcaje sin conexión',
    grupo: GrupoParametro.seguridad,
    porDefecto: true,
    aplicado: false,
    resumen: 'Permite guardar el marcaje sin internet y enviarlo después.',
    comoFunciona:
        'Pensado para decidir si la app puede guardar marcajes sin conexión. '
        'Hoy la app siempre los guarda y los envía al recuperar la señal; '
        'este valor todavía no lo cambia.',
    recomendacion: 'Déjelo en Sí.',
  ),
  InfoParametro(
    clave: 'porcentaje_minimo_asistencia',
    nombre: 'Asistencia mínima',
    grupo: GrupoParametro.alertas,
    unidad: '%',
    minimo: 50,
    maximo: 100,
    porDefecto: 80,
    aplicado: false,
    resumen: 'Porcentaje por debajo del cual un docente genera alerta.',
    comoFunciona:
        'Pensado para avisar cuando la asistencia de un docente baja de este '
        'porcentaje. La regla existe en el servidor pero todavía no envía '
        'alertas.',
    recomendacion: '80 % es el valor habitual.',
  ),
  InfoParametro(
    clave: 'inasistencias_consecutivas_alerta',
    nombre: 'Faltas seguidas para alerta',
    grupo: GrupoParametro.alertas,
    unidad: 'faltas',
    minimo: 1,
    maximo: 10,
    porDefecto: 3,
    aplicado: false,
    resumen: 'Inasistencias consecutivas que disparan una alerta.',
    comoFunciona:
        'Pensado para avisar cuando un docente acumula este número de faltas '
        'seguidas. La regla existe en el servidor pero todavía no envía '
        'alertas.',
    recomendacion: '3 faltas.',
  ),
  InfoParametro(
    clave: 'retencion_coordenadas_dias',
    nombre: 'Conservar coordenadas',
    grupo: GrupoParametro.privacidad,
    unidad: 'días',
    minimo: 30,
    maximo: 3650,
    porDefecto: 365,
    soloGlobal: true,
    resumen: 'Días que se guardan las coordenadas exactas de cada marcaje.',
    comoFunciona:
        'Pasado este plazo, las coordenadas de los marcajes se borran; se '
        'conservan el resultado y la distancia al aula. Es una política de '
        'toda la institución, por eso solo se configura en Global '
        '(Ley 1581 de protección de datos).',
    recomendacion: '365 días, salvo que la política de datos diga otra cosa.',
  ),
];
