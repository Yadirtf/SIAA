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

  const ResolucionVerificacion({this.cancelado = false, this.verificacion});
}

class VerificacionResolver {
  final WifiBssidService _wifi;
  final Future<String?> Function(BuildContext context) _pedirCodigoQr;

  VerificacionResolver({
    WifiBssidService? wifi,
    Future<String?> Function(BuildContext context)? pedirCodigoQr,
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
      codigoQr = await _pedirCodigoQr(context);
      if (codigoQr == null) {
        return const ResolucionVerificacion(cancelado: true);
      }
    }

    return ResolucionVerificacion(
      verificacion: SelectorVerificacion.seleccionar(
        exigida: exigida,
        metodos: metodos,
        bssid: bssid,
        codigoQr: codigoQr,
      ),
    );
  }
}
