// auth_sesion.dart — AuthBloc autenticado con permisos dados, para pruebas de pantallas.
import 'dart:convert';

import 'package:siaa_mobile/features/auth/data/auth_repository.dart';
import 'package:siaa_mobile/features/auth/data/sesion_restaurador.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class RestauradorFijo extends SesionRestaurador {
  final SesionRestaurada? sesion;
  RestauradorFijo(this.sesion) : super(leerToken: () async => null);

  @override
  Future<SesionRestaurada?> restaurar() async => sesion;
}

/// Token JWT sin firma válida (solo el payload importa en el cliente).
String tokenCon(Map<String, dynamic> claims) {
  String b64(Object o) =>
      base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${b64({'alg': 'HS256'})}.${b64(claims)}.firma';
}

/// Devuelve un AuthBloc ya autenticado con [permisos].
Future<AuthBloc> authBlocCon(
  List<String> permisos, {
  AuthRepository? repository,
  List<String> roles = const ['ADMIN_INSTITUCIONAL'],
}) async {
  final bloc = AuthBloc(
    repository: repository ?? AuthRepository(),
    restaurador: RestauradorFijo(SesionRestaurada(
      usuarioId: 'u-1',
      nombre: 'Ana Gómez',
      correo: 'ana@siaa.edu.co',
      roles: roles,
      permisos: permisos,
      rolActivo: roles.first,
    )),
  )..add(AuthSessionChecked());
  await bloc.stream.firstWhere((s) => s is AuthAuthenticated);
  return bloc;
}
