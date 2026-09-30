// solapamiento_model.dart — Par de aulas cuyos polígonos se superponen (US-GEO-05)
// Respuesta de GET /espacios/solapamientos: {totalConflictos, conflictos[]}.
import 'package:equatable/equatable.dart';

class SolapamientoModel extends Equatable {
  final String sedeId;
  final String? bloqueId;
  final int? piso;
  final String espacio1Codigo;
  final String espacio1Nombre;
  final String espacio2Codigo;
  final String espacio2Nombre;
  final double areaSolapadaM2;
  final double porcentajeSolapado;
  final bool esCritico;

  const SolapamientoModel({
    required this.sedeId,
    this.bloqueId,
    this.piso,
    required this.espacio1Codigo,
    required this.espacio1Nombre,
    required this.espacio2Codigo,
    required this.espacio2Nombre,
    required this.areaSolapadaM2,
    required this.porcentajeSolapado,
    required this.esCritico,
  });

  factory SolapamientoModel.fromJson(Map<String, dynamic> j) =>
      SolapamientoModel(
        sedeId: j['sedeId'] as String? ?? '',
        bloqueId: j['bloqueId'] as String?,
        piso: (j['piso'] as num?)?.toInt(),
        espacio1Codigo: j['espacio1Codigo'] as String? ?? '',
        espacio1Nombre: j['espacio1Nombre'] as String? ?? '',
        espacio2Codigo: j['espacio2Codigo'] as String? ?? '',
        espacio2Nombre: j['espacio2Nombre'] as String? ?? '',
        areaSolapadaM2: (j['areaSolapadaM2'] as num?)?.toDouble() ?? 0,
        porcentajeSolapado: (j['porcentajeSolapado'] as num?)?.toDouble() ?? 0,
        esCritico: j['esCritico'] as bool? ?? false,
      );

  static String etiquetaAula(String codigo, String nombre) {
    if (codigo.isNotEmpty && nombre.isNotEmpty && codigo != nombre) {
      return '$codigo · $nombre';
    }
    return codigo.isNotEmpty ? codigo : (nombre.isNotEmpty ? nombre : 'Aula');
  }

  String get aula1 => etiquetaAula(espacio1Codigo, espacio1Nombre);
  String get aula2 => etiquetaAula(espacio2Codigo, espacio2Nombre);

  static List<SolapamientoModel> listaDesde(Object? data) {
    if (data is! Map<String, dynamic>) return const [];
    return (data['conflictos'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SolapamientoModel.fromJson)
        .toList();
  }

  @override
  List<Object?> get props => [
        sedeId,
        bloqueId,
        piso,
        espacio1Codigo,
        espacio1Nombre,
        espacio2Codigo,
        espacio2Nombre,
        areaSolapadaM2,
        porcentajeSolapado,
        esCritico,
      ];
}
