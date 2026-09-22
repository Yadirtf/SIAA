import 'package:flutter/material.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/models/gps_accuracy_status.dart';

/// Marcador que representa la posición GPS en vivo del usuario sobre el mapa,
/// con un halo de radio de dispersión y color según la precisión (RF-GEO-002).
class GpsMarker extends StatelessWidget {
  final GpsAccuracyStatus accuracy;

  const GpsMarker({
    super.key,
    required this.accuracy,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (accuracy) {
      case GpsAccuracyStatus.optimal:
        color = SIAAColors.asistenciaPresente;
        break;
      case GpsAccuracyStatus.acceptable:
        color = Colors.amber;
        break;
      case GpsAccuracyStatus.insufficient:
      default:
        color = SIAAColors.asistenciaAusente;
        break;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.25),
          ),
        ),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
          ),
        ),
      ],
    );
  }
}
