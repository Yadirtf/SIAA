import 'package:equatable/equatable.dart';

/// Tipos de ámbito que el backend acepta para restringir a un usuario.
class TipoAmbito {
  TipoAmbito._();

  static const String sede = 'SEDE';
  static const String facultad = 'FACULTAD';
  static const String bloque = 'BLOQUE';

  static const List<String> todos = [sede, facultad, bloque];

  static String plural(String tipo) {
    switch (tipo) {
      case sede:
        return 'Sedes';
      case facultad:
        return 'Facultades';
      case bloque:
        return 'Bloques';
      default:
        return tipo;
    }
  }

  static String etiqueta(String tipo) {
    switch (tipo) {
      case sede:
        return 'Sede';
      case facultad:
        return 'Facultad';
      case bloque:
        return 'Bloque';
      default:
        return tipo;
    }
  }
}

/// Ámbito de actuación de un usuario ({tipo, id}).
class AmbitoModel extends Equatable {
  final String tipo;
  final String id;

  const AmbitoModel({required this.tipo, required this.id});

  factory AmbitoModel.fromJson(Map<String, dynamic> json) {
    return AmbitoModel(
      tipo: json['tipo']?.toString().toUpperCase() ?? '',
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'tipo': tipo, 'id': id};

  @override
  List<Object?> get props => [tipo, id];
}
