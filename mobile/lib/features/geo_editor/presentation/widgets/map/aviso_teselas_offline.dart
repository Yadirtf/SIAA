// aviso_teselas_offline.dart — Aviso del modo mapa sin conexión y progreso de descarga de zona
// Informa si se usan teselas guardadas o si no hay ninguna para el área (US-GEO-03 AC-04).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/teselas_offline_cubit.dart';
import '../../cubit/teselas_offline_state.dart';

class AvisoTeselasOffline extends StatelessWidget {
  final TeselasOfflineCubit cubit;

  const AvisoTeselasOffline({super.key, required this.cubit});

  static String? textoAviso(TeselasOfflineState s) {
    if (s.descargando) {
      return s.total == 0
          ? 'Preparando la descarga de la zona…'
          : 'Guardando zona sin conexión: ${s.procesadas}/${s.total} teselas';
    }
    if (s.enLinea) return null;
    switch (s.cobertura) {
      case CoberturaTeselas.completa:
        return 'Sin conexión: el mapa muestra las teselas guardadas en el '
            'dispositivo.';
      case CoberturaTeselas.parcial:
        return 'Sin conexión: solo parte de esta zona está guardada; algunas '
            'áreas del mapa se verán vacías.';
      case CoberturaTeselas.ninguna:
        return 'Sin conexión y sin teselas guardadas para esta zona: la imagen '
            'satelital no está disponible. Puede seguir capturando por GPS o '
            'descargar la zona cuando tenga red.';
      case CoberturaTeselas.desconocida:
        return 'Sin conexión: comprobando teselas guardadas…';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeselasOfflineCubit, TeselasOfflineState>(
      bloc: cubit,
      listenWhen: (a, b) => a.mensajeId != b.mensajeId && b.mensaje != null,
      listener: (context, s) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(s.mensaje!),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ));
      },
      builder: (context, s) {
        final texto = textoAviso(s);
        if (texto == null) return const SizedBox.shrink();
        final sinTeselas =
            !s.descargando && s.cobertura == CoberturaTeselas.ninguna;
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          color: sinTeselas
              ? Colors.deepOrange.shade900.withValues(alpha: 0.92)
              : Colors.black87,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                if (s.descargando)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: s.total == 0 ? null : s.procesadas / s.total,
                      color: Colors.cyanAccent,
                    ),
                  )
                else
                  Icon(
                    sinTeselas
                        ? Icons.cloud_off_rounded
                        : Icons.offline_pin_rounded,
                    color: Colors.amberAccent,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
