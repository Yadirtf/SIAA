import 'package:flutter/material.dart';
import '../../domain/models/gps_accuracy_status.dart';

/// Badge visual para el semáforo de precisión GPS según AC-03 y AC-04.
class GpsTrafficLightBadge extends StatelessWidget {
  final GpsAccuracyStatus status;
  final double? accuracyMetros;

  const GpsTrafficLightBadge({
    super.key,
    required this.status,
    this.accuracyMetros,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final accuracyText = accuracyMetros != null && accuracyMetros! > 0
        ? '± ${accuracyMetros!.toStringAsFixed(1)} m'
        : '--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '($accuracyText)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
