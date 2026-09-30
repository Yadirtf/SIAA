// justificacion_card.dart — Tarjeta de una justificación en "Mis justificaciones"
import 'package:flutter/material.dart';

import '../../domain/models/justificacion_model.dart';
import 'estado_justificacion_chip.dart';
import 'formato_fechas.dart';

class JustificacionCard extends StatelessWidget {
  final Justificacion justificacion;
  final VoidCallback onTap;

  const JustificacionCard({
    super.key,
    required this.justificacion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final j = justificacion;
    final titulo = j.nombreSesion.isNotEmpty ? j.nombreSesion : 'Sesión';
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  EstadoJustificacionChip(estado: j.estado),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${j.tipoEtiqueta} • Sesión del '
                '${formatearFechaSesion(j.fechaSesion)}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                j.descripcion,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              if (j.creadoEn != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Radicada el ${formatearMomento(j.creadoEn!)}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
