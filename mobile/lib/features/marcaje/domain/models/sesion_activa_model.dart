// sesion_activa_model.dart — Modelo de sesión activa y ventana para marcaje (US-MAR-01)
import 'package:equatable/equatable.dart';
import 'marcaje_result_model.dart';

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

  const VentanaInfo({
    required this.abreEn,
    required this.cierraEn,
    required this.estado,
    this.minutosParaAbrir = 0,
  });

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
    );
  }

  Map<String, dynamic> toJson() => {
        'abreEn': abreEn.toIso8601String(),
        'cierraEn': cierraEn.toIso8601String(),
        'estado': estado,
        'minutosParaAbrir': minutosParaAbrir,
      };

  @override
  List<Object?> get props => [abreEn, cierraEn, estado, minutosParaAbrir];
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
  });

  factory SesionActivaModel.fromDetalleJson(Map<String, dynamic> json) {
    final sesionMap = json['sesion'] as Map<String, dynamic>? ?? {};
    final ventanaMap = json['ventana'] as Map<String, dynamic>? ?? {};
    final espacioMap = sesionMap['espacio'] as Map<String, dynamic>? ?? {};
    final marcajeExistente = json['marcajeExistente'] as Map<String, dynamic>?;
    final parametros = json['parametros'] as Map<String, dynamic>? ?? {};
    final metodos = (json['metodosVerificacion'] as List<dynamic>? ?? [])
        .whereType<String>()
        .map((m) => m.toUpperCase())
        .toList();

    final tieneEntrada = marcajeExistente != null &&
        marcajeExistente['tipo'] == 'ENTRADA' &&
        MarcajeResultModel.resultadosAceptados
            .contains(marcajeExistente['resultado']);

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
      tieneMarcajeSalida: false,
      marcajeEntradaEstado: marcajeExistente?['resultado'] as String?,
    );
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
      ];
}
