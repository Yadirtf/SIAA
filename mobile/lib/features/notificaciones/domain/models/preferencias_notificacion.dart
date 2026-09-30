// preferencias_notificacion.dart — Preferencias por tipo de notificación (US-NOT-02)
// Espejo de GET/PUT /me/notificaciones/preferencias. Las obligatorias siempre quedan activas.
import 'package:equatable/equatable.dart';

class PreferenciasNotificacion extends Equatable {
  /// Claves del contrato en el orden en que se muestran.
  static const claves = [
    'recordatorioSesion',
    'cierreVentana',
    'resultadoJustificacion',
    'cambioHorario',
  ];

  static const etiquetas = {
    'recordatorioSesion': 'Recordatorio de sesión',
    'cierreVentana': 'Cierre de ventana de marcaje',
    'resultadoJustificacion': 'Resultado de justificaciones',
    'cambioHorario': 'Cambios de horario',
  };

  final Map<String, bool> valores;
  final Set<String> obligatorias;

  const PreferenciasNotificacion({
    required this.valores,
    this.obligatorias = const {},
  });

  factory PreferenciasNotificacion.fromJson(Map<String, dynamic> json) {
    final obligatorias = (json['obligatorias'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toSet();
    return PreferenciasNotificacion(
      valores: {
        for (final k in claves)
          k: obligatorias.contains(k) || (json[k] as bool? ?? true),
      },
      obligatorias: obligatorias,
    );
  }

  bool esObligatoria(String clave) => obligatorias.contains(clave);

  bool valor(String clave) => esObligatoria(clave) || (valores[clave] ?? true);

  /// Cambia una preferencia; las obligatorias no se pueden desactivar.
  PreferenciasNotificacion con(String clave, bool activo) {
    if (esObligatoria(clave)) return this;
    return PreferenciasNotificacion(
      valores: {...valores, clave: activo},
      obligatorias: obligatorias,
    );
  }

  /// Cuerpo del PUT (sin "obligatorias").
  Map<String, dynamic> toJson() => {for (final k in claves) k: valor(k)};

  @override
  List<Object?> get props => [valores, obligatorias];
}
