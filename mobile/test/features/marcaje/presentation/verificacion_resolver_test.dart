// verificacion_resolver_test.dart — Testigo de verificación complementaria (US-GEO-13)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/data/services/wifi_bssid_service.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/lectura_baliza.dart';
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
  late int busquedasBle;

  Future<void> montar(WidgetTester tester) async {
    pedidosQr = [];
    busquedasBle = 0;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
  }

  VerificacionResolver resolver(
    String? bssid, {
    String? qr = 'QR-A101',
    LecturaBaliza baliza =
        const LecturaBaliza.fallida(MotivoSinBaliza.noEncontrada),
  }) =>
      VerificacionResolver(
        wifi: _WifiFijo(bssid),
        pedirCodigoQr: (_, {bool otroMetodoIntentado = false}) async {
          pedidosQr.add(otroMetodoIntentado);
          return qr;
        },
        buscarBaliza: (_) async {
          busquedasBle++;
          return baliza;
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

  testWidgets('aula con BLE adjunta el UUID de la baliza detectada',
      (tester) async {
    await montar(tester);
    final r = await resolver(null,
            baliza: const LecturaBaliza.encontrada(
                'e2c56db5-dffb-48d2-b060-d0f5a71096e0'))
        .resolver(ctx, _sesion(['BLE', 'QR']));
    expect(r.verificacion?.metodo, 'BLE');
    expect(r.verificacion?.valor, 'e2c56db5-dffb-48d2-b060-d0f5a71096e0');
    expect(busquedasBle, 1);
    expect(pedidosQr, isEmpty);
    expect(r.aviso, isNull);
  });

  testWidgets('WiFi legible evita el escaneo BLE', (tester) async {
    await montar(tester);
    final r = await resolver('AA:BB:CC:DD:EE:FF')
        .resolver(ctx, _sesion(['WIFI', 'BLE']));
    expect(r.verificacion?.metodo, 'WIFI');
    expect(busquedasBle, 0);
  });

  testWidgets('sin baliza recurre al QR indicando que se intentó otro método',
      (tester) async {
    await montar(tester);
    final r = await resolver(null).resolver(ctx, _sesion(['BLE', 'QR']));
    expect(r.verificacion?.metodo, 'QR');
    expect(pedidosQr, [true]);
  });

  testWidgets('aula solo con BLE y Bluetooth apagado explica cómo resolverlo',
      (tester) async {
    await montar(tester);
    final r = await resolver(null,
            baliza:
                const LecturaBaliza.fallida(MotivoSinBaliza.bluetoothApagado))
        .resolver(ctx, _sesion(['BLE']));
    expect(r.verificacion, isNull);
    expect(r.cancelado, isFalse);
    expect(r.aviso, contains('Active el Bluetooth'));
  });

  testWidgets('cancelar el QR cancela el marcaje', (tester) async {
    await montar(tester);
    final r = await resolver(null, qr: null).resolver(ctx, _sesion(['QR']));
    expect(r.cancelado, isTrue);
  });

  testWidgets('WIFI exigido sin red legible avisa cómo resolverlo',
      (tester) async {
    await montar(tester);
    final r = await resolver(null).resolver(ctx, _sesion(['WIFI']));
    expect(r.verificacion, isNull);
    expect(r.aviso, contains('WiFi'));
  });
}
