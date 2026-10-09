// verificacion_resolver.dart — Obtiene el testigo de verificación complementaria antes de marcar
// Se ejecuta en el momento de la captura: el testigo viaja en la petición (y en la cola offline).
// Orden: WiFi (BSSID) → baliza BLE (escaneo corto en primer plano) → QR por cámara o tecleado.
import 'package:flutter/widgets.dart';
import '../../data/services/baliza_ble_service.dart';
import '../../data/services/selector_verificacion.dart';
import '../../data/services/wifi_bssid_service.dart';
import '../../domain/models/lectura_baliza.dart';
import '../../domain/models/sesion_activa_model.dart';
import '../../domain/models/verificacion_complementaria_model.dart';
import '../widgets/busqueda_baliza_dialog.dart';
import '../widgets/codigo_qr_dialog.dart';
import 'aviso_verificacion.dart';

typedef PedirCodigoQr = Future<String?> Function(BuildContext context,
    {bool otroMetodoIntentado});
typedef BuscarBaliza = Future<LecturaBaliza> Function(BuildContext context);

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
  final PedirCodigoQr _pedirCodigoQr;
  final BuscarBaliza _buscarBaliza;

  VerificacionResolver({
    WifiBssidService? wifi,
    PedirCodigoQr? pedirCodigoQr,
    BuscarBaliza? buscarBaliza,
  })  : _wifi = wifi ?? WifiBssidService(),
        _pedirCodigoQr = pedirCodigoQr ?? CodigoQrDialog.show,
        _buscarBaliza = buscarBaliza ?? _buscarBalizaPorDefecto;

  static Future<LecturaBaliza> _buscarBalizaPorDefecto(BuildContext context) =>
      BusquedaBalizaDialog.show(context, buscar: BalizaBleService().buscar);

  Future<ResolucionVerificacion> resolver(
    BuildContext context,
    SesionActivaModel sesion,
  ) async {
    final exigida = sesion.verificacionComplementariaExigida;
    final metodos = sesion.metodosVerificacion;
    if (!exigida) return const ResolucionVerificacion();

    String? bssid;
    final wifiIntentado =
        SelectorVerificacion.requiereBssid(exigida: exigida, metodos: metodos);
    if (wifiIntentado) bssid = await _wifi.leerBssid();

    LecturaBaliza? baliza;
    if (SelectorVerificacion.requiereBle(
        exigida: exigida, metodos: metodos, bssid: bssid)) {
      if (!context.mounted) {
        return const ResolucionVerificacion(cancelado: true);
      }
      baliza = await _buscarBaliza(context);
    }

    String? codigoQr;
    if (SelectorVerificacion.requiereCodigoQr(
      exigida: exigida,
      metodos: metodos,
      bssid: bssid,
      uuidBle: baliza?.uuid,
    )) {
      if (!context.mounted) {
        return const ResolucionVerificacion(cancelado: true);
      }
      codigoQr = await _pedirCodigoQr(context,
          otroMetodoIntentado: wifiIntentado || baliza != null);
      if (codigoQr == null) {
        return const ResolucionVerificacion(cancelado: true);
      }
    }

    final verificacion = SelectorVerificacion.seleccionar(
      exigida: exigida,
      metodos: metodos,
      bssid: bssid,
      uuidBle: baliza?.uuid,
      codigoQr: codigoQr,
    );
    return ResolucionVerificacion(
      verificacion: verificacion,
      aviso: verificacion == null
          ? AvisoVerificacion.sinTestigo(metodos, baliza?.motivo)
          : null,
    );
  }
}
