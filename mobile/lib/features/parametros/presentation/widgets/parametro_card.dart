import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/models/parametro_model.dart';

/// Tarjeta de un parámetro efectivo con su valor y nivel de origen (US-PAR-03).
class ParametroCard extends StatelessWidget {
  final ParametroEfectivo parametro;

  const ParametroCard({super.key, required this.parametro});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: SIAAColors.neutral200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _claveLabel(parametro.clave),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SIAAColors.primary800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    parametro.clave,
                    style: TextStyle(
                      fontSize: 11,
                      color: SIAAColors.neutral400,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  parametro.valorFormateado,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: SIAAColors.primary500,
                  ),
                ),
                const SizedBox(height: 2),
                _NivelBadge(
                    nivel: parametro.nivelLabel, esGlobal: parametro.esGlobal),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _claveLabel(String clave) {
    const labels = {
      'holgura_entrada_antes_min': 'Holgura entrada (antes)',
      'holgura_entrada_despues_min': 'Holgura entrada (después)',
      'umbral_tardanza_min': 'Umbral tardanza',
      'holgura_salida_antes_min': 'Holgura salida (antes)',
      'holgura_salida_despues_min': 'Holgura salida (después)',
      'precision_gps_max_metros': 'Precisión GPS máxima',
      'buffer_perimetral_metros': 'Buffer perimetral',
      'promedio_lecturas_vertice': 'Lecturas por vértice',
      'salida_obligatoria': 'Marcaje de salida',
      'offline_permitido': 'Marcaje offline',
      'bloqueo_mock_location': 'Bloqueo ubicación simulada',
      'bloqueo_dispositivo_rooteado': 'Bloqueo dispositivo rooteado',
      'verificacion_complementaria': 'Verificación complementaria',
    };
    return labels[clave] ?? clave;
  }
}

class _NivelBadge extends StatelessWidget {
  final String nivel;
  final bool esGlobal;

  const _NivelBadge({required this.nivel, required this.esGlobal});

  @override
  Widget build(BuildContext context) {
    final color = esGlobal ? SIAAColors.neutral300 : SIAAColors.primary200;
    final textColor = esGlobal ? SIAAColors.neutral400 : SIAAColors.primary700;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        nivel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
