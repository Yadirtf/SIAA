// perfil_model.dart — Perfil propio (§9.1 "Perfil": datos, dispositivo vinculado)
// Respuesta de GET /me/perfil.
import 'package:equatable/equatable.dart';

class DispositivoPerfil extends Equatable {
  final String instalacionId;
  final String modelo;
  final String so;
  final String versionApp;
  final bool confiable;
  final bool pendienteAprobacion;
  final DateTime? vinculadoEn;
  final DateTime? revocadoEn;

  const DispositivoPerfil({
    required this.instalacionId,
    this.modelo = '',
    this.so = '',
    this.versionApp = '',
    this.confiable = false,
    this.pendienteAprobacion = false,
    this.vinculadoEn,
    this.revocadoEn,
  });

  bool get revocado => revocadoEn != null;

  String get estadoEtiqueta {
    if (revocado) return 'Revocado';
    if (pendienteAprobacion) return 'Pendiente de aprobación';
    return confiable ? 'Confiable' : 'No confiable';
  }

  factory DispositivoPerfil.fromJson(Map<String, dynamic> j) =>
      DispositivoPerfil(
        instalacionId: j['instalacionId'] as String? ?? '',
        modelo: j['modelo'] as String? ?? '',
        so: j['so'] as String? ?? '',
        versionApp: j['versionApp'] as String? ?? '',
        confiable: j['confiable'] as bool? ?? false,
        pendienteAprobacion: j['pendienteAprobacion'] as bool? ?? false,
        vinculadoEn: DateTime.tryParse(j['vinculadoEn'] as String? ?? ''),
        revocadoEn: DateTime.tryParse(j['revocadoEn'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [
        instalacionId,
        modelo,
        so,
        versionApp,
        confiable,
        pendienteAprobacion,
        vinculadoEn,
        revocadoEn,
      ];
}

class PerfilModel extends Equatable {
  final String id;
  final String nombre;
  final String apellido;
  final String correo;
  final String documento;
  final List<String> roles;
  final bool totpActivado;
  final List<DispositivoPerfil> dispositivos;

  /// false cuando los datos vienen de la sesión local (servidor sin /me/perfil).
  final bool completo;

  const PerfilModel({
    required this.id,
    required this.nombre,
    this.apellido = '',
    this.correo = '',
    this.documento = '',
    this.roles = const [],
    this.totpActivado = false,
    this.dispositivos = const [],
    this.completo = true,
  });

  String get nombreCompleto {
    final n = '$nombre $apellido'.trim();
    return n.isEmpty ? 'Usuario' : n;
  }

  factory PerfilModel.fromJson(Map<String, dynamic> j) => PerfilModel(
        id: j['id'] as String? ?? '',
        nombre: j['nombre'] as String? ?? '',
        apellido: j['apellido'] as String? ?? '',
        correo: j['correo'] as String? ?? '',
        documento: j['documento'] as String? ?? '',
        roles: (j['roles'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        totpActivado: j['totpActivado'] as bool? ?? false,
        dispositivos: (j['dispositivos'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DispositivoPerfil.fromJson)
            .toList(),
      );

  @override
  List<Object?> get props => [
        id,
        nombre,
        apellido,
        correo,
        documento,
        roles,
        totpActivado,
        dispositivos,
        completo,
      ];
}
