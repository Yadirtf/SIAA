// verificacion_resolver_test.dart — Testigo de verificación complementaria (US-GEO-13)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/data/services/wifi_bssid_service.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';
import 'package:siaa_mobile/features/marcaje/presentation/helpers/verificacion_resolver.dart';

class _WifiFijo extends WifiBssidService {
  final String? bssid;
  _WifiFijo(this.bssid);

  @override
  Future<String?> leerBssid() async => bssid;
}

SesionActivaModel _sesion(List<String> metodos) => SesionActivaModel(
      id: 'ses-1',
      asignatura: 'Cálculo',
      grupo: 'G1',
      espacio: const EspacioInfo(id: 'e', codigo: 'A-101', nombre: 'Aula 101'),
      inicioProgramado: DateTime(2026, 10, 9, 7),
      finProgramado: DateTime(2026, 10, 9, 9),
      modalidad: 'PRESENCIAL',
      ventana: VentanaInfo(
        abreEn: DateTime(2026, 10, 9, 6, 45),
        cierraEn: DateTime(2026, 10, 9, 7, 15),
        estado: 'ABIERTA',
      ),
      verificacionComplementariaExigida: true,
      metodosVerificacion: metodos,
    );

void main() {
  late BuildContext ctx;
  late List<bool> pedidosQr;

  Future<void> montar(WidgetTester tester) async {
    pedidosQr = [];
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
  }

  VerificacionResolver resolver(String? bssid, {String? qr = 'QR-A101'}) =>
      VerificacionResolver(
        wifi: _WifiFijo(bssid),
        pedirCodigoQr: (_, {bool wifiIntentado = false}) async {
          pedidosQr.add(wifiIntentado);
          return qr;
        },
      );

  testWidgets('con BSSID legible usa WIFI y no pide el QR', (tester) async {
    await montar(tester);
    final r = await resolver('AA:BB:CC:DD:EE:FF')
        .resolver(ctx, _sesion(['WIFI', 'QR']));
    expect(r.verificacion?.metodo, 'WIFI');
    expect(r.verificacion?.valor, 'AA:BB:CC:DD:EE:FF');
    expect(pedidosQr, isEmpty);
    expect(r.aviso, isNull);
  });

  testWidgets('sin WiFi recurre al código del QR', (tester) async {
    await montar(tester);
    final r = await resolver(null).resolver(ctx, _sesion(['WIFI', 'QR']));
    expect(r.verificacion?.metodo, 'QR');
    expect(pedidosQr, [true]);
  });

  testWidgets('aula solo con QR no menciona el WiFi', (tester) async {
    await montar(tester);
    final r = await resolver(null).resolver(ctx, _sesion(['QR']));
    expect(r.verificacion?.valor, 'QR-A101');
    expect(pedidosQr, [false]);
  });

  testWidgets('aula solo con BLE avisa que la app no puede leer balizas',
      (tester) async {
    await montar(tester);
    final r = await resolver(null).resolver(ctx, _sesion(['BLE']));
    expect(r.verificacion, isNull);
    expect(r.cancelado, isFalse);
    expect(r.aviso, contains('BLE'));
  });

  testWidgets('WIFI exigido sin red legible avisa cómo resolverlo',
      (tester) async {
    await montar(tester);
    final r = await resolver(null).resolver(ctx, _sesion(['WIFI']));
    expect(r.verificacion, isNull);
    expect(r.aviso, contains('WiFi'));
  });
}
