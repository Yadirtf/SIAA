/// Modelo de un parámetro efectivo con su nivel de origen (US-PAR-03 AC-01).
class ParametroEfectivoModel {
  final String clave;
  final dynamic valor;
  final String nivel;
  final String nivelId;

  const ParametroEfectivoModel({
    required this.clave,
    required this.valor,
    required this.nivel,
    required this.nivelId,
  });

  factory ParametroEfectivoModel.fromJson(Map<String, dynamic> json) {
    return ParametroEfectivoModel(
      clave: json['clave'] as String? ?? '',
      valor: json['valor'],
      nivel: json['nivel'] as String? ?? 'GLOBAL',
      nivelId: json['nivel_id'] as String? ?? '',
    );
  }

  bool get esGlobal => nivel == 'GLOBAL';

  String get nivelLabel {
    switch (nivel) {
      case 'GLOBAL':
        return 'Global';
      case 'SEDE':
        return 'Sede';
      case 'FACULTAD':
        return 'Facultad';
      case 'BLOQUE':
        return 'Bloque';
      case 'AULA':
        return 'Aula';
      case 'ASIGNACION':
        return 'Asignación';
      default:
        return nivel;
    }
  }

  String get valorFormateado {
    if (valor is bool) return valor == true ? 'Sí' : 'No';
    if (valor == null) return '—';
    return valor.toString();
  }
}

/// Snapshot de todos los parámetros efectivos para un ámbito dado.
class ParametrosSnapshot {
  final List<ParametroEfectivoModel> parametros;

  const ParametrosSnapshot({required this.parametros});

  factory ParametrosSnapshot.fromJson(Map<String, dynamic> json) {
    final lista = json['parametros'] as List<dynamic>? ?? [];
    return ParametrosSnapshot(
      parametros: lista
          .map((e) => ParametroEfectivoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Solicitud de escritura de un parámetro (US-PAR-01 AC-02, AC-03).
class GuardarParametroRequest {
  final String ambito;
  final String ambitoId;
  final String clave;
  final dynamic valor;

  const GuardarParametroRequest({
    required this.ambito,
    required this.ambitoId,
    required this.clave,
    required this.valor,
  });

  Map<String, dynamic> toJson() => {
    'ambito': ambito,
    'ambito_id': ambitoId,
    'clave': clave,
    'valor': valor,
  };
}
