// resumen_sincronizacion.dart — Balance de una ejecución de sincronización offline (US-MAR-11)
import 'package:equatable/equatable.dart';

class ResumenSincronizacion extends Equatable {
  final int aceptados;
  final int rechazados;
  final int reprogramados;
  final int fallidos;

  const ResumenSincronizacion({
    this.aceptados = 0,
    this.rechazados = 0,
    this.reprogramados = 0,
    this.fallidos = 0,
  });

  static const vacio = ResumenSincronizacion();

  /// Items con respuesta definitiva del servidor (aceptados o rechazados).
  int get evaluados => aceptados + rechazados;

  ResumenSincronizacion operator +(ResumenSincronizacion o) =>
      ResumenSincronizacion(
        aceptados: aceptados + o.aceptados,
        rechazados: rechazados + o.rechazados,
        reprogramados: reprogramados + o.reprogramados,
        fallidos: fallidos + o.fallidos,
      );

  @override
  List<Object?> get props => [aceptados, rechazados, reprogramados, fallidos];
}
