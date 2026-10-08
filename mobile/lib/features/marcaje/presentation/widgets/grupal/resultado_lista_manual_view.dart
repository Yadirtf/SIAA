// resultado_lista_manual_view.dart — Resumen tras enviar la lista manual: registrados,
// conservados y quienes no pertenecen al grupo (US-MAR-14).
import 'package:flutter/material.dart';

import '../../../domain/models/lista_manual_model.dart';

class ResultadoListaManualView extends StatelessWidget {
  final ResultadoListaManual resultado;
  final VoidCallback onListo;

  const ResultadoListaManualView({
    super.key,
    required this.resultado,
    required this.onListo,
  });

  @override
  Widget build(BuildContext context) {
    final r = resultado;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.check_circle_rounded,
            size: 72, color: Colors.green.shade600),
        const SizedBox(height: 12),
        Text(r.mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        _Fila(
          icono: Icons.how_to_reg_rounded,
          texto: 'Registrados con esta lista',
          valor: '${r.registrados}',
        ),
        _Fila(
          icono: Icons.lock_outline_rounded,
          texto: 'Conservaron su registro anterior',
          valor: '${r.conservados}',
        ),
        if (r.noPertenecen.isNotEmpty)
          _Fila(
            icono: Icons.person_off_outlined,
            texto: 'No pertenecen al grupo (no se registraron)',
            valor: '${r.noPertenecen.length}',
            color: Colors.orange.shade800,
          ),
        const SizedBox(height: 32),
        FilledButton(onPressed: onListo, child: const Text('Listo')),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  final IconData icono;
  final String texto;
  final String valor;
  final Color? color;

  const _Fila({
    required this.icono,
    required this.texto,
    required this.valor,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icono, color: color),
      title: Text(texto, style: TextStyle(color: color)),
      trailing: Text(valor,
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    );
  }
}
