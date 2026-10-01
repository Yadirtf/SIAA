/// Catálogo legible de los parámetros: nombre, unidad, rango y una explicación
/// de qué controla cada uno, para que la institución sepa qué está
/// configurando. Las claves, rangos y valores por defecto replican
/// backend/internal/domain/parametro/parametro.go (el backend valida).
library;

import 'catalogo_parametros_datos.dart';

export 'catalogo_parametros_datos.dart';

enum GrupoParametro {
  entrada(
    'Ventana de entrada y tardanza',
    'Cuándo puede el docente marcar su llegada y cuándo cuenta como tarde.',
  ),
  salida(
    'Salida de clase',
    'Si se registra la salida de clase y en qué ventana.',
  ),
  ubicacion(
    'Ubicación y GPS',
    'Qué tan precisa debe ser la ubicación para aceptar un marcaje.',
  ),
  seguridad(
    'Seguridad del celular',
    'Qué celulares o ubicaciones se rechazan por riesgo de suplantación.',
  ),
  alertas(
    'Alertas de asistencia',
    'Cuándo avisar que un docente tiene baja asistencia.',
  ),
  privacidad('Privacidad', 'Cuánto tiempo se guardan los datos de ubicación.');

  final String titulo;
  final String descripcion;
  const GrupoParametro(this.titulo, this.descripcion);
}

class InfoParametro {
  final String clave;
  final String nombre;
  final GrupoParametro grupo;

  /// 'min', 'm', '%', 'días', 'lecturas', 'faltas' o '' para Sí/No y opciones.
  final String unidad;
  final String resumen;
  final String comoFunciona;
  final String recomendacion;
  final int? minimo;
  final int? maximo;
  final Object porDefecto;

  /// Valor → etiqueta, para parámetros de opciones fijas.
  final Map<String, String> opciones;
  final bool soloGlobal;

  /// Falso si el valor se guarda pero el sistema todavía no lo usa.
  final bool aplicado;

  const InfoParametro({
    required this.clave,
    required this.nombre,
    required this.grupo,
    required this.resumen,
    required this.comoFunciona,
    required this.recomendacion,
    required this.porDefecto,
    this.unidad = '',
    this.minimo,
    this.maximo,
    this.opciones = const {},
    this.soloGlobal = false,
    this.aplicado = true,
  });

  bool get esNumerico => minimo != null;

  /// Cuándo surte efecto un cambio de este parámetro.
  String get cuandoAplica {
    if (!aplicado) return 'Hoy el sistema no usa este valor.';
    if (grupo == GrupoParametro.privacidad) {
      return 'De inmediato: la limpieza diaria usa el valor vigente.';
    }
    if (grupo == GrupoParametro.alertas) return 'De inmediato.';
    return 'Cada clase guarda los valores de marcaje vigentes cuando se '
        'generan sus sesiones. Un cambio aplica a las sesiones que se generen '
        'después; las ya generadas conservan el valor anterior.';
  }

  String get rangoTexto => esNumerico ? 'Entre $minimo y $maximo $unidad' : '';

  /// "15 min", "Sí", "Opcional".
  String formatear(Object? valor) {
    if (valor == null) return '—';
    if (valor is bool) return valor ? 'Sí' : 'No';
    if (opciones.isNotEmpty) return opciones[valor.toString()] ?? '$valor';
    final n = valor is num && valor == valor.roundToDouble()
        ? valor.toInt().toString()
        : '$valor';
    return unidad.isEmpty ? n : '$n $unidad';
  }

  /// Mensaje de error si [valor] no es válido para este parámetro.
  String? validar(String texto) {
    if (!esNumerico) return null;
    final n = int.tryParse(texto.trim());
    if (n == null) return 'Escriba un número entero';
    if (n < minimo! || n > maximo!) {
      return 'Debe estar entre $minimo y $maximo $unidad';
    }
    return null;
  }
}

final _porClave = {for (final p in catalogoParametros) p.clave: p};

/// Información del parámetro; una genérica si el backend agrega una clave nueva.
InfoParametro infoParametro(String clave) =>
    _porClave[clave] ??
    InfoParametro(
      clave: clave,
      nombre: clave,
      grupo: GrupoParametro.seguridad,
      porDefecto: '',
      resumen: '',
      comoFunciona: 'Parámetro sin descripción en la consola.',
      recomendacion: '',
    );
