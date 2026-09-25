// Modelo de metadatos de dispositivo — US-AUT-03
// Contiene la información técnica requerida para la vinculación confiable.
class DeviceMetadata {
  final String instalacionId;
  final String modelo;
  final String so;
  final String versionApp;

  const DeviceMetadata({
    required this.instalacionId,
    required this.modelo,
    required this.so,
    required this.versionApp,
  });

  Map<String, dynamic> toJson() => {
        'instalacionId': instalacionId,
        'modelo': modelo,
        'so': so,
        'versionApp': versionApp,
      };

  @override
  String toString() =>
      'DeviceMetadata(instalacionId: $instalacionId, modelo: $modelo, so: $so, versionApp: $versionApp)';
}
