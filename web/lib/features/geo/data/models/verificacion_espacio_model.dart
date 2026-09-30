import 'package:equatable/equatable.dart';

/// Verificación complementaria de un espacio (RF-GEO-016): valores que el
/// dispositivo debe observar dentro del aula para desambiguar pisos.
class VerificacionEspacioModel extends Equatable {
  final List<String> wifiBssids;
  final String bleUuid;
  final String qrCodigo;

  const VerificacionEspacioModel({
    this.wifiBssids = const [],
    this.bleUuid = '',
    this.qrCodigo = '',
  });

  /// Todo vacío: al enviarse, el backend elimina la configuración.
  static const vacia = VerificacionEspacioModel();

  factory VerificacionEspacioModel.fromJson(Map<String, dynamic> json) {
    return VerificacionEspacioModel(
      wifiBssids:
          (json['wifiBssids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      bleUuid: json['bleUuid']?.toString() ?? '',
      qrCodigo: json['qrCodigo']?.toString() ?? '',
    );
  }

  /// Cuerpo de PUT /espacios/:id/verificacion.
  Map<String, dynamic> toJson() => {
    'wifiBssids': wifiBssids,
    'bleUuid': bleUuid,
    'qrCodigo': qrCodigo,
  };

  /// Métodos configurados (WIFI, BLE, QR), en el orden del backend.
  List<String> get metodos => [
    if (wifiBssids.isNotEmpty) 'WIFI',
    if (bleUuid.isNotEmpty) 'BLE',
    if (qrCodigo.isNotEmpty) 'QR',
  ];

  bool get configurada => metodos.isNotEmpty;

  @override
  List<Object?> get props => [wifiBssids, bleUuid, qrCodigo];
}
