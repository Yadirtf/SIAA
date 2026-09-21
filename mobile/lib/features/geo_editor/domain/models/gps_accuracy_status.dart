import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// Semáforo de precisión GPS con umbrales configurables.
// AC-03, AC-04, T-GEO-02.6.
// Umbrales: Óptima <= 10m (Verde), Aceptable 10-20m (Amarillo), Insuficiente > 20m (Rojo).
enum GpsAccuracyStatus {
  optimal,
  acceptable,
  insufficient,
  searching,
}

extension GpsAccuracyStatusX on GpsAccuracyStatus {
  /// AC-04: bloquea el botón de captura si la precisión es insuficiente.
  bool get canCapture => this == GpsAccuracyStatus.optimal || this == GpsAccuracyStatus.acceptable;

  Color get color {
    switch (this) {
      case GpsAccuracyStatus.optimal:
        return SIAAColors.gpsExcelente;
      case GpsAccuracyStatus.acceptable:
        return SIAAColors.gpsAceptable;
      case GpsAccuracyStatus.insufficient:
        return SIAAColors.gpsInsuficiente;
      case GpsAccuracyStatus.searching:
        return SIAAColors.gpsBuscando;
    }
  }

  String get label {
    switch (this) {
      case GpsAccuracyStatus.optimal:
        return 'Precisión óptima (≤ 10 m)';
      case GpsAccuracyStatus.acceptable:
        return 'Precisión aceptable (10 - 20 m)';
      case GpsAccuracyStatus.insufficient:
        return 'Precisión insuficiente (> 20 m)';
      case GpsAccuracyStatus.searching:
        return 'Buscando satélites GPS...';
    }
  }

  static GpsAccuracyStatus fromAccuracy(
    double accuracy, {
    double optimalThreshold = 10.0,
    double acceptableThreshold = 20.0,
  }) {
    if (accuracy <= 0) return GpsAccuracyStatus.searching;
    if (accuracy <= optimalThreshold) return GpsAccuracyStatus.optimal;
    if (accuracy <= acceptableThreshold) return GpsAccuracyStatus.acceptable;
    return GpsAccuracyStatus.insufficient;
  }
}
