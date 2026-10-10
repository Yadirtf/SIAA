// busqueda_baliza_dialog.dart — Indicador mientras se busca la baliza BLE del aula (US-GEO-13)
// El escaneo dura unos segundos: el docente ve qué ocurre y puede omitirlo.
import 'package:flutter/material.dart';

import '../../domain/models/lectura_baliza.dart';

class BusquedaBalizaDialog extends StatefulWidget {
  final Future<LecturaBaliza> Function() buscar;

  const BusquedaBalizaDialog({super.key, required this.buscar});

  /// Ejecuta [buscar] con el diálogo abierto; si el docente lo omite devuelve
  /// "no encontrada" para continuar con el siguiente método.
  static Future<LecturaBaliza> show(
    BuildContext context, {
    required Future<LecturaBaliza> Function() buscar,
  }) async {
    final r = await showDialog<LecturaBaliza>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BusquedaBalizaDialog(buscar: buscar),
    );
    return r ?? const LecturaBaliza.fallida(MotivoSinBaliza.noEncontrada);
  }

  @override
  State<BusquedaBalizaDialog> createState() => _BusquedaBalizaDialogState();
}

class _BusquedaBalizaDialogState extends State<BusquedaBalizaDialog> {
  bool _cerrado = false;

  @override
  void initState() {
    super.initState();
    widget.buscar().then(_cerrar);
  }

  void _cerrar(LecturaBaliza? lectura) {
    if (_cerrado || !mounted) return;
    _cerrado = true;
    Navigator.of(context).pop(lectura);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Verificación del aula'),
      content: const Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text('Buscando la baliza Bluetooth del aula… '
                'Mantenga el Bluetooth activo.'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _cerrar(null),
          child: const Text('Omitir'),
        ),
      ],
    );
  }
}
