// conectividad.dart — Consulta puntual de red disponible (US-GEO-10)
import 'package:connectivity_plus/connectivity_plus.dart';

/// true si el sistema informa alguna interfaz de red activa. Que haya red no
/// garantiza llegar al servidor: los llamadores deben tratar también los fallos de red.
Future<bool> hayConexionDeRed() async {
  try {
    final redes = await Connectivity().checkConnectivity();
    return redes.any((r) => r != ConnectivityResult.none);
  } catch (_) {
    // Sin el plugin (pruebas, web antigua) se asume red y decide la petición.
    return true;
  }
}
