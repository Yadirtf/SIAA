/// Modelo de dominio para un parámetro efectivo resuelto por la cascada.
/// US-PAR-02: herencia Global → Sede → Facultad → Bloque → Aula → Asignación.
class ParametroEfectivo {
  final String clave;
  final dynamic valor;
  final String nivel;
  final String nivelId;

  const ParametroEfectivo({
    required this.clave,
    required this.valor,
    required this.nivel,
    required this.nivelId,
  });

  factory ParametroEfectivo.fromJson(Map<String, dynamic> json) {
    return ParametroEfectivo(
      clave: json['clave'] as String? ?? '',
      valor: json['valor'],
      nivel: json['nivel'] as String? ?? 'GLOBAL',
      nivelId: json['nivel_id'] as String? ?? '',
    );
  }

  /// Retorna true cuando el valor proviene del nivel global (sin override).
  bool get esGlobal => nivel == 'GLOBAL';

  /// Formatea el valor para display. Booleanos como Sí/No, números con unidad si aplica.
  String get valorFormateado {
    if (valor is bool) return valor == true ? 'Sí' : 'No';
    if (valor == null) return '—';
    return valor.toString();
  }

  /// Etiqueta legible del nivel de origen.
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
}

/// Snapshot de todos los parámetros efectivos para un ámbito dado.
class ParametrosSnapshot {
  final List<ParametroEfectivo> parametros;

  const ParametrosSnapshot({required this.parametros});

  factory ParametrosSnapshot.fromJson(Map<String, dynamic> json) {
    final lista = json['parametros'] as List<dynamic>? ?? [];
    return ParametrosSnapshot(
      parametros: lista
          .map((e) => ParametroEfectivo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Devuelve el parámetro por clave o null si no existe.
  ParametroEfectivo? porClave(String clave) {
    try {
      return parametros.firstWhere((p) => p.clave == clave);
    } catch (_) {
      return null;
    }
  }
}
