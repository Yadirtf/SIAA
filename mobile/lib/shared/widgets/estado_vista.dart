// estado_vista.dart — Estados de pantalla reutilizables: vacío y error con reintento
import 'package:flutter/material.dart';

/// Mensaje centrado para listas sin resultados.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final String? detalle;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.mensaje,
    this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    final gris =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 56, color: gris),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500, color: gris),
            ),
            if (detalle != null) ...[
              const SizedBox(height: 6),
              Text(detalle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: gris)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error visible con botón "Reintentar" (nunca se oculta un fallo de red).
class EstadoError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;

  const EstadoError(
      {super.key, required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
