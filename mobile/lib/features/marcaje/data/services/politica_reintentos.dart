// politica_reintentos.dart — Backoff exponencial por item de la cola offline (US-MAR-11)
import 'dart:math' as math;
import '../../domain/models/offline_marcaje_item.dart';

class PoliticaReintentos {
  final Duration base;
  final Duration maximo;
  final int maxIntentos;

  const PoliticaReintentos({
    this.base = const Duration(seconds: 30),
    this.maximo = const Duration(minutes: 30),
    this.maxIntentos = 8,
  });

  /// Espera tras el intento fallido número [intentos] (1-based): base · 2^(n-1), con tope.
  Duration espera(int intentos) {
    final exponente = math.max(0, intentos - 1).clamp(0, 30);
    final ms = base.inMilliseconds * math.pow(2, exponente);
    return ms >= maximo.inMilliseconds
        ? maximo
        : Duration(milliseconds: ms.toInt());
  }

  /// Registra un intento fallido reintentable: reprograma o, agotado el cupo, marca fallido.
  OfflineMarcajeItem registrarFallo(
    OfflineMarcajeItem item,
    String mensaje,
    DateTime ahora,
  ) {
    final intentos = item.intentos + 1;
    if (intentos >= maxIntentos) {
      return item.copyWith(
        estado: EstadoSincronizacion.fallido,
        intentos: intentos,
        errorMensaje: mensaje,
        limpiarProximoIntento: true,
      );
    }
    return item.copyWith(
      estado: EstadoSincronizacion.pendiente,
      intentos: intentos,
      errorMensaje: mensaje,
      proximoIntento: ahora.add(espera(intentos)),
    );
  }

  /// Fallo definitivo (p. ej. 4xx del lote): requiere reintento manual.
  OfflineMarcajeItem registrarFalloDefinitivo(
    OfflineMarcajeItem item,
    String mensaje,
  ) {
    return item.copyWith(
      estado: EstadoSincronizacion.fallido,
      intentos: item.intentos + 1,
      errorMensaje: mensaje,
      limpiarProximoIntento: true,
    );
  }

  /// Reintento manual desde la UI: vuelve a la cola inmediatamente con contador en cero.
  OfflineMarcajeItem reiniciar(OfflineMarcajeItem item) {
    return item.copyWith(
      estado: EstadoSincronizacion.pendiente,
      intentos: 0,
      limpiarProximoIntento: true,
      limpiarError: true,
    );
  }
}
