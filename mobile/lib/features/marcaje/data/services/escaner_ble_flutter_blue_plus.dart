// escaner_ble_flutter_blue_plus.dart — Escaneo BLE corto con flutter_blue_plus (US-GEO-13)
// Solo en primer plano y por unos segundos, en el momento de marcar: nunca rastreo de fondo.
// En Android el plugin solicita BLUETOOTH_SCAN/CONNECT (12+) o ubicación (≤ 11);
// se pide también ubicación precisa porque Android filtra las balizas sin ella.
import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../domain/models/lectura_baliza.dart';
import '../../domain/services/selector_baliza.dart';
import 'escaner_ble.dart';

class EscanerBleFlutterBluePlus implements EscanerBle {
  /// Tras ver el primer iBeacon se escucha un poco más para elegir el más cercano.
  static const _graciaTrasIBeacon = Duration(milliseconds: 1200);

  @override
  Future<List<AnuncioBle>> escanear(Duration duracion) async {
    await _comprobarAdaptador();
    final vistos = <String, AnuncioBle>{};
    final listo = Completer<void>();
    Timer? gracia;

    final sub = FlutterBluePlus.onScanResults.listen((resultados) {
      for (final r in resultados) {
        final anuncio = _convertir(r);
        vistos[r.device.remoteId.str] = anuncio;
        if (gracia == null &&
            SelectorBaliza.uuidIBeacon(anuncio.datosFabricante) != null) {
          gracia = Timer(_graciaTrasIBeacon, () {
            if (!listo.isCompleted) listo.complete();
          });
        }
      }
    });

    try {
      await FlutterBluePlus.startScan(
        timeout: duracion,
        androidUsesFineLocation: true,
      );
      await Future.any([
        listo.future,
        FlutterBluePlus.isScanning.where((s) => !s).first,
      ]).timeout(duracion + const Duration(seconds: 2), onTimeout: () {});
    } on FlutterBluePlusException catch (e) {
      throw FallaEscanerBle(_motivoDe(e.description));
    } finally {
      gracia?.cancel();
      await sub.cancel();
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
    }
    return vistos.values.toList();
  }

  Future<void> _comprobarAdaptador() async {
    try {
      if (!await FlutterBluePlus.isSupported) {
        throw const FallaEscanerBle(MotivoSinBaliza.sinSoporte);
      }
      // En iOS el estado arranca en "unknown" hasta que CoreBluetooth responde.
      final estado = await FlutterBluePlus.adapterState
          .where((s) => s != BluetoothAdapterState.unknown)
          .first
          .timeout(const Duration(seconds: 3),
              onTimeout: () => BluetoothAdapterState.unknown);
      if (estado == BluetoothAdapterState.unauthorized) {
        throw const FallaEscanerBle(MotivoSinBaliza.sinPermiso);
      }
      if (estado == BluetoothAdapterState.unavailable) {
        throw const FallaEscanerBle(MotivoSinBaliza.sinSoporte);
      }
      if (estado != BluetoothAdapterState.on) {
        throw const FallaEscanerBle(MotivoSinBaliza.bluetoothApagado);
      }
    } on FallaEscanerBle {
      rethrow;
    } catch (_) {
      throw const FallaEscanerBle(MotivoSinBaliza.sinSoporte);
    }
  }

  static MotivoSinBaliza _motivoDe(String? descripcion) {
    final d = (descripcion ?? '').toLowerCase();
    if (d.contains('permission')) return MotivoSinBaliza.sinPermiso;
    if (d.contains('location')) return MotivoSinBaliza.ubicacionApagada;
    if (d.contains('off') || d.contains('adapter')) {
      return MotivoSinBaliza.bluetoothApagado;
    }
    return MotivoSinBaliza.noEncontrada;
  }

  static AnuncioBle _convertir(ScanResult r) => AnuncioBle(
        datosFabricante: r.advertisementData.manufacturerData,
        uuidsServicio:
            r.advertisementData.serviceUuids.map((g) => g.str128).toList(),
        rssi: r.rssi,
      );
}
