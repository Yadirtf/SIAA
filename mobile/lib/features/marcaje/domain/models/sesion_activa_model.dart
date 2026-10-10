// sesion_activa_model.dart — Modelo de sesión activa y ventana para marcaje (US-MAR-01)
import 'package:equatable/equatable.dart';
import 'marcaje_result_model.dart';
import 'ventana_estudiantil_model.dart';

class EspacioInfo extends Equatable {
  final String id;
  final String codigo;
  final String nombre;

  const EspacioInfo({
    required this.id,
    required this.codigo,
    required this.nombre,
  });

  factory EspacioInfo.fromJson(Map<String, dynamic> json) {
    return EspacioInfo(
      id: json['id'] as String? ?? '',
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'codigo': codigo,
        'nombre': nombre,
      };

  @override
  List<Object?> get props => [id, codigo, nombre];
}

class VentanaInfo extends Equatable {
  final DateTime abreEn;
  final DateTime cierraEn;
  final String estado; // ABIERTA, NO_ABIERTA, CERRADA
  final int minutosParaAbrir;

  /// Tipo de marcaje que admite la ventana: ENTRADA o SALIDA (US-MAR-15).
  final String tipo;

  const VentanaInfo({
    required this.abreEn,
    required this.cierraEn,
    required this.estado,
    this.minutosParaAbrir = 0,
    this.tipo = 'ENTRADA',
  });

  bool get esSalida => tipo == 'SALIDA';
  bool get estaAbierta => estado == 'ABIERTA';
  bool get noAbierta => estado == 'NO_ABIERTA';
  bool get estaCerrada => estado == 'CERRADA';

  factory VentanaInfo.fromJson(Map<String, dynamic> json) {
    return VentanaInfo(
      abreEn:
          DateTime.tryParse(json['abreEn'] as String? ?? '') ?? DateTime.now(),
      cierraEn: DateTime.tryParse(json['cierraEn'] as String? ?? '') ??
          DateTime.now(),
      estado: json['estado'] as String? ?? 'NO_ABIERTA',
      minutosParaAbrir: (json['minutosParaAbrir'] as num?)?.toInt() ?? 0,
      tipo: (json['tipo'] as String? ?? '').toUpperCase() == 'SALIDA'
          ? 'SALIDA'
          : 'ENTRADA',
    );
  }

  Map<String, dynamic> toJson() => {
        'abreEn': abreEn.toIso8601String(),
        'cierraEn': cierraEn.toIso8601String(),
        'estado': estado,
        'minutosParaAbrir': minutosParaAbrir,
        'tipo': tipo,
      };

  @override
  List<Object?> get props => [abreEn, cierraEn, estado, minutosParaAbrir, tipo];
}

class SesionActivaModel extends Equatable {
  final String id;
  final String asignatura;
  final String grupo;
  final EspacioInfo espacio;
  final DateTime inicioProgramado;
  final DateTime finProgramado;
  final String modalidad;
  final VentanaInfo ventana;
  final bool verificacionComplementariaExigida;

  /// Métodos aceptados por el aula (WIFI | BLE | QR); solo viene cuando es exigida.
  final List<String> metodosVerificacion;

  /// Parámetro de sesión: el servidor exige token de Play Integrity válido.
  final bool exigirAttestation;
  final bool tieneMarcajeEntrada;
  final bool tieneMarcajeSalida;
  final String? marcajeEntradaEstado;

  /// Modo del marcaje de salida congelado en la sesión:
  /// OBLIGATORIO | OPCIONAL | DESACTIVADO (US-MAR-15); null si no se informó.
  final String? modoMarcajeSalida;

  /// Minutos de permanencia de la salida ya registrada (US-MAR-15 AC-02).
  final int? permanenciaSalidaMin;

  /// Diferencia entre el reloj del servidor y el del celular al recibir la
  /// sesión; la cuenta regresiva la suma para no depender de un reloj mal puesto.
  final Duration desfaseReloj;

  /// Ventana que el docente abrió a los estudiantes (US-MAR-13); null si nunca se abrió.
  final VentanaEstudiantil? ventanaEstudiantil;

  const SesionActivaModel({
    required this.id,
    required this.asignatura,
    required this.grupo,
    required this.espacio,
    required this.inicioProgramado,
    required this.finProgramado,
    required this.modalidad,
    required this.ventana,
    this.verificacionComplementariaExigida = false,
    this.metodosVerificacion = const [],
    this.exigirAttestation = false,
    this.tieneMarcajeEntrada = false,
    this.tieneMarcajeSalida = false,
    this.marcajeEntradaEstado,
    this.modoMarcajeSalida,
    this.permanenciaSalidaMin,
    this.desfaseReloj = Duration.zero,
    this.ventanaEstudiantil,
  });

  /// Tipo de marcaje que corresponde a la ventana vigente (US-MAR-15).
  String get tipoMarcaje => ventana.esSalida ? 'SALIDA' : 'ENTRADA';

  bool get salidaDesactivada => modoMarcajeSalida == 'DESACTIVADO';

  /// El marcaje propio de la ventana vigente ya quedó registrado.
  bool get marcajeVentanaRegistrado =>
      ventana.esSalida ? tieneMarcajeSalida : tieneMarcajeEntrada;

  /// La ventana vigente admite todavía un marcaje (nunca salida si está desactivada: AC-03).
  bool get admiteMarcaje =>
      !marcajeVentanaRegistrado && !(ventana.esSalida && salidaDesactivada);

  /// Hora actual corregida con el reloj del servidor.
  DateTime ahoraServidor() => DateTime.now().add(desfaseReloj);

  factory SesionActivaModel.fromDetalleJson(Map<String, dynamic> json) {
    final sesionMap = json['sesion'] as Map<String, dynamic>? ?? {};
    final ventanaMap = json['ventana'] as Map<String, dynamic>? ?? {};
    final espacioMap = sesionMap['espacio'] as Map<String, dynamic>? ?? {};
    final marcajeExistente = json['marcajeExistente'] as Map<String, dynamic>?;
    final ventanaEst =
        json['ventanaEstudiantil'] ?? sesionMap['ventanaEstudiantil'];
    final parametros = json['parametros'] as Map<String, dynamic>? ?? {};
    final metodos = (json['metodosVerificacion'] as List<dynamic>? ?? [])
        .whereType<String>()
        .map((m) => m.toUpperCase())
        .toList();

    final marcajeSalida = json['marcajeSalida'] as Map<String, dynamic>?;
    final tieneEntrada = _aceptado(marcajeExistente, 'ENTRADA');
    final tieneSalida = _aceptado(marcajeSalida, 'SALIDA');
    final modoSalida = parametros['marcajeSalida'] as String?;

    return SesionActivaModel(
      id: sesionMap['id'] as String? ?? '',
      asignatura: sesionMap['asignatura'] as String? ?? 'Sin Asignatura',
      grupo: sesionMap['grupo'] as String? ?? 'G1',
      espacio: EspacioInfo.fromJson(espacioMap),
      inicioProgramado:
          DateTime.tryParse(sesionMap['inicioProgramado'] as String? ?? '') ??
              DateTime.now(),
      finProgramado:
          DateTime.tryParse(sesionMap['finProgramado'] as String? ?? '') ??
              DateTime.now(),
      modalidad: sesionMap['modalidad'] as String? ?? 'PRESENCIAL',
      ventana: VentanaInfo.fromJson(ventanaMap),
      verificacionComplementariaExigida:
          json['verificacionComplementariaExigida'] as bool? ?? false,
      metodosVerificacion: metodos,
      exigirAttestation: parametros['exigirAttestation'] as bool? ?? false,
      tieneMarcajeEntrada: tieneEntrada,
      tieneMarcajeSalida: tieneSalida,
      marcajeEntradaEstado: marcajeExistente?['resultado'] as String?,
      modoMarcajeSalida: modoSalida?.toUpperCase(),
      permanenciaSalidaMin: tieneSalida
          ? (marcajeSalida!['permanenciaMin'] as num?)?.toInt()
          : null,
      desfaseReloj: _desfase(json['horaServidor']),
      ventanaEstudiantil: ventanaEst is Map<String, dynamic>
          ? VentanaEstudiantil.fromJson(ventanaEst)
          : null,
    );
  }

  static bool _aceptado(Map<String, dynamic>? marcaje, String tipo) =>
      marcaje != null &&
      marcaje['tipo'] == tipo &&
      MarcajeResultModel.resultadosAceptados.contains(marcaje['resultado']);

  static Duration _desfase(Object? horaServidor) {
    final servidor = DateTime.tryParse(horaServidor as String? ?? '');
    if (servidor == null) return Duration.zero;
    return servidor.difference(DateTime.now());
  }

  @override
  List<Object?> get props => [
        id,
        asignatura,
        grupo,
        espacio,
        inicioProgramado,
        finProgramado,
        modalidad,
        ventana,
        verificacionComplementariaExigida,
        metodosVerificacion,
        exigirAttestation,
        tieneMarcajeEntrada,
        tieneMarcajeSalida,
        marcajeEntradaEstado,
        modoMarcajeSalida,
        permanenciaSalidaMin,
        desfaseReloj,
        ventanaEstudiantil,
      ];
}
