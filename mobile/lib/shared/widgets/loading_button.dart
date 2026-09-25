// Widget de botón con estado de carga — shared/widgets
// Mínimo 44px táctil (RNF-USA-003), deshabilita durante carga.
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SIAALoadingButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;

  const SIAALoadingButton({
    super.key,
    required this.label,
    required this.isLoading,
    this.onPressed,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? SIAAColors.primary500,
        disabledBackgroundColor:
            (backgroundColor ?? SIAAColors.primary500).withOpacity(0.6),
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(
          borderRadius: SIAASpacing.radiusSm,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isLoading
            ? const SizedBox(
                key: ValueKey('loading'),
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                key: const ValueKey('label'),
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: SIAASpacing.sm),
                  ],
                  Text(
                    label,
                    style: SIAATypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Indicador de estado GPS con semáforo de colores — SRS §9.1
class GPSStatusIndicator extends StatelessWidget {
  final double? precisionMetros;
  final bool buscando;
  final double maxPrecision;

  const GPSStatusIndicator({
    super.key,
    this.precisionMetros,
    this.buscando = false,
    this.maxPrecision = 35.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final label = _label;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(
        horizontal: SIAASpacing.md,
        vertical: SIAASpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: SIAASpacing.radiusFull,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: SIAASpacing.sm),
          Text(
            label,
            style: SIAATypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Color get _color {
    if (buscando || precisionMetros == null) return SIAAColors.gpsBuscando;
    if (precisionMetros! <= 10) return SIAAColors.gpsExcelente;
    if (precisionMetros! <= maxPrecision) return SIAAColors.gpsAceptable;
    return SIAAColors.gpsInsuficiente;
  }

  String get _label {
    if (buscando) return 'Buscando GPS...';
    if (precisionMetros == null) return 'Sin señal';
    if (precisionMetros! <= 10)
      return 'GPS excelente (±${precisionMetros!.toStringAsFixed(0)} m)';
    if (precisionMetros! <= 35)
      return 'GPS aceptable (±${precisionMetros!.toStringAsFixed(0)} m)';
    return 'Señal débil (±${precisionMetros!.toStringAsFixed(0)} m)';
  }
}

/// Chip de estado de asistencia codificado por color — SRS §9.3
class AttendanceStatusChip extends StatelessWidget {
  final String resultado;

  const AttendanceStatusChip({super.key, required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SIAASpacing.md,
        vertical: SIAASpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: SIAASpacing.radiusFull,
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Text(
        _label,
        style: SIAATypography.labelSmall.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color get _color {
    switch (resultado.toUpperCase()) {
      case 'PRESENTE':
        return SIAAColors.asistenciaPresente;
      case 'TARDANZA':
        return SIAAColors.asistenciaTardanza;
      case 'AUSENTE':
      case 'RECHAZADO_FUERA_DE_AREA':
      case 'RECHAZADO_FUERA_DE_HORARIO':
      case 'RECHAZADO_INTEGRIDAD':
      case 'RECHAZADO_SIN_ASIGNACION':
        return SIAAColors.asistenciaAusente;
      case 'AUSENCIA_JUSTIFICADA':
        return SIAAColors.asistenciaJustificada;
      default:
        return SIAAColors.neutral500;
    }
  }

  String get _label {
    switch (resultado.toUpperCase()) {
      case 'PRESENTE':
        return 'Presente';
      case 'TARDANZA':
        return 'Tardanza';
      case 'AUSENTE':
        return 'Ausente';
      case 'AUSENCIA_JUSTIFICADA':
        return 'Justificado';
      case 'RECHAZADO_FUERA_DE_AREA':
        return 'Fuera de área';
      case 'RECHAZADO_FUERA_DE_HORARIO':
        return 'Fuera de horario';
      case 'RECHAZADO_INTEGRIDAD':
        return 'Error de integridad';
      case 'RECHAZADO_SIN_ASIGNACION':
        return 'Sin asignación';
      default:
        return resultado;
    }
  }
}
