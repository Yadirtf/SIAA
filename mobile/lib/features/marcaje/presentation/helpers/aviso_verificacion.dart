// aviso_verificacion.dart — Explica por qué no se pudo aportar el testigo exigido (US-GEO-13 AC-02)
import '../../domain/models/lectura_baliza.dart';
import '../../domain/models/verificacion_complementaria_model.dart';

class AvisoVerificacion {
  const AvisoVerificacion._();

  static String sinTestigo(List<String> metodos, MotivoSinBaliza? motivoBle) {
    final m = metodos.map((e) => e.toUpperCase()).toSet();
    final partes = <String>[];
    if (m.contains(VerificacionComplementariaModel.metodoWifi)) {
      partes.add('No se pudo leer la red WiFi del aula. Active el WiFi y la '
          'ubicación precisa y conéctese a la red institucional.');
    }
    if (m.contains(VerificacionComplementariaModel.metodoBle)) {
      partes.add(baliza(motivoBle ?? MotivoSinBaliza.noEncontrada));
    }
    if (partes.isEmpty) {
      return 'Esta aula exige verificación complementaria y no se aportó '
          'ninguna.';
    }
    return '${partes.join(' ')} Luego intente de nuevo.';
  }

  static String baliza(MotivoSinBaliza motivo) {
    switch (motivo) {
      case MotivoSinBaliza.sinSoporte:
        return 'Este dispositivo no tiene Bluetooth de baja energía para '
            'detectar la baliza del aula.';
      case MotivoSinBaliza.bluetoothApagado:
        return 'Active el Bluetooth para detectar la baliza del aula.';
      case MotivoSinBaliza.sinPermiso:
        return 'Conceda a SIAA el permiso de Bluetooth (dispositivos cercanos) '
            'para detectar la baliza del aula.';
      case MotivoSinBaliza.ubicacionApagada:
        return 'Active la ubicación del dispositivo: Android la exige para '
            'detectar balizas Bluetooth.';
      case MotivoSinBaliza.noEncontrada:
        return 'No se detectó la baliza Bluetooth del aula; acérquese a ella.';
    }
  }
}
