// verificacion_resolver.dart — Obtiene el testigo de verificación complementaria antes de marcar
// Se ejecuta en el momento de la captura: el testigo viaja en la petición (y en la cola offline).
import 'package:flutter/widgets.dart';
import '../../data/services/selector_verificacion.dart';
import '../../data/services/wifi_bssid_service.dart';
import '../../domain/models/sesion_activa_model.dart';
import '../../domain/models/verificacion_complementaria_model.dart';
import '../widgets/codigo_qr_dialog.dart';

class ResolucionVerificacion {
  final bool cancelado;
  final VerificacionComplementariaModel? verificacion;

  /// Se exige verificación y el dispositivo no pudo aportar ninguna: explica por qué
  /// antes de que el servidor rechace con RECHAZADO_VERIFICACION (US-GEO-13 AC-02).
  final String? aviso;

  const ResolucionVerificacion({
    this.cancelado = false,
    this.verificacion,
    this.aviso,
  });
}

class VerificacionResolver {
  final WifiBssidService _wifi;
  final Future<String?> Function(BuildContext context, {bool wifiIntentado})
      _pedirCodigoQr;

  VerificacionResolver({
    WifiBssidService? wifi,
    Future<String?> Function(BuildContext context, {bool wifiIntentado})?
        pedirCodigoQr,
  })  : _wifi = wifi ?? WifiBssidService(),
        _pedirCodigoQr = pedirCodigoQr ?? CodigoQrDialog.show;

  Future<ResolucionVerificacion> resolver(
    BuildContext context,
    SesionActivaModel sesion,
  ) async {
    final exigida = sesion.verificacionComplementariaExigida;
    final metodos = sesion.metodosVerificacion;
    if (!exigida) return const ResolucionVerificacion();

    String? bssid;
    if (SelectorVerificacion.requiereBssid(
        exigida: exigida, metodos: metodos)) {
      bssid = await _wifi.leerBssid();
    }

    String? codigoQr;
    if (SelectorVerificacion.requiereCodigoQr(
      exigida: exigida,
      metodos: metodos,
      bssid: bssid,
    )) {
      if (!context.mounted) {
        return const ResolucionVerificacion(cancelado: true);
      }
      codigoQr = await _pedirCodigoQr(context,
          wifiIntentado: SelectorVerificacion.requiereBssid(
              exigida: exigida, metodos: metodos));
      if (codigoQr == null) {
        return const ResolucionVerificacion(cancelado: true);
      }
    }

    final verificacion = SelectorVerificacion.seleccionar(
      exigida: exigida,
      metodos: metodos,
      bssid: bssid,
      codigoQr: codigoQr,
    );
    return ResolucionVerificacion(
      verificacion: verificacion,
      aviso: verificacion == null ? avisoSinTestigo(metodos) : null,
    );
  }

  /// Por qué no se pudo aportar el testigo exigido con los métodos del aula.
  static String avisoSinTestigo(List<String> metodos) {
    final m = metodos.map((e) => e.toUpperCase()).toSet();
    if (m.contains(VerificacionComplementariaModel.metodoWifi)) {
      return 'No se pudo leer la red WiFi del aula. Active el WiFi y la '
          'ubicación precisa, conéctese a la red institucional e intente de nuevo.';
    }
    if (m.contains(VerificacionComplementariaModel.metodoBle)) {
      return 'Esta aula exige verificación por baliza BLE y esta versión de la app '
          'aún no puede leerla. Informe al administrador del espacio.';
    }
    return 'Esta aula exige verificación complementaria y no se aportó ninguna.';
  }
}
