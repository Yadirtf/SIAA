// baliza_ble_service.dart — Busca la baliza BLE del aula para la verificación complementaria
// Escaneo corto (≈ 8 s) y en primer plano, como exige la política de privacidad.
import '../../domain/models/lectura_baliza.dart';
import '../../domain/services/selector_baliza.dart';
import 'escaner_ble.dart';
import 'escaner_ble_flutter_blue_plus.dart';

class BalizaBleService {
  static const duracionEscaneo = Duration(seconds: 8);

  final EscanerBle _escaner;

  BalizaBleService({EscanerBle? escaner})
      : _escaner = escaner ?? EscanerBleFlutterBluePlus();

  Future<LecturaBaliza> buscar() async {
    try {
      final anuncios = await _escaner.escanear(duracionEscaneo);
      final uuid = SelectorBaliza.elegir(anuncios);
      return uuid == null
          ? const LecturaBaliza.fallida(MotivoSinBaliza.noEncontrada)
          : LecturaBaliza.encontrada(uuid);
    } on FallaEscanerBle catch (e) {
      return LecturaBaliza.fallida(e.motivo);
    } catch (_) {
      return const LecturaBaliza.fallida(MotivoSinBaliza.noEncontrada);
    }
  }
}
