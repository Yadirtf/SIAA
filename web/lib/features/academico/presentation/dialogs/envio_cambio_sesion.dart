import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/confirmar_operacion.dart';
import '../../../../core/widgets/error_operacion_dialog.dart';
import '../../data/models/cambio_sesion.dart';
import '../bloc/sesiones_bloc.dart';

/// Comportamiento común de los diálogos que cambian una sesión puntual
/// (aula, suplente, reprogramar): motivo obligatorio, confirmación cuando la
/// clase ya comenzó (409 CONFIRMACION_REQUERIDA) y el formulario abierto
/// hasta que el servidor acepte.
mixin EnvioCambioSesion<T extends StatefulWidget> on State<T> {
  final formKey = GlobalKey<FormState>();
  final motivoCtrl = TextEditingController();
  bool guardando = false;

  @override
  void dispose() {
    motivoCtrl.dispose();
    super.dispose();
  }

  /// Valida, envía el evento creado por [crear] y cierra el diálogo si se
  /// aplicó. [crear] recibe el cambio (motivo y confirmación) y el completer
  /// donde el bloc entrega el resultado.
  Future<void> enviarCambio(
    AccionSesionEvent Function(CambioSesion cambio, Completer<void> r) crear,
  ) async {
    if (guardando || !formKey.currentState!.validate()) return;
    final bloc = context.read<SesionesBloc>();
    final motivo = motivoCtrl.text.trim();
    setState(() => guardando = true);
    try {
      final aplicado = await ejecutarConConfirmacion(
        context,
        (confirmar) {
          final r = Completer<void>();
          bloc.add(
            crear(CambioSesion(motivo: motivo, confirmar: confirmar), r),
          );
          return r.future;
        },
        titulo: 'La clase ya comenzó',
        textoConfirmar: 'Aplicar el cambio',
        alPreguntar: (preguntando) {
          if (mounted) setState(() => guardando = !preguntando);
        },
      );
      if (!mounted) return;
      if (aplicado) {
        Navigator.pop(context, true);
        return;
      }
      setState(() => guardando = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => guardando = false);
      await mostrarErrorOperacion(context, e);
    }
  }

  /// Botón principal con indicador mientras se guarda.
  Widget botonEnviar(String texto, VoidCallback onPressed) =>
      ElevatedButton.icon(
        onPressed: guardando ? null : onPressed,
        icon: guardando
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_rounded, size: 18),
        label: Text(texto),
      );
}
