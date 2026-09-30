// sesion_contexto_test.dart — Restauración de sesión al reabrir la app y cambio de
// contexto de rol contra POST /auth/contexto (US-AUT-01, RF-ROL-004).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/auth/jwt_claims.dart';
import 'package:siaa_mobile/core/navigation/navigation.dart';
import 'package:siaa_mobile/core/navigation/presentation/widgets/drawer/role_context_selector.dart';
import 'package:siaa_mobile/core/storage/secure_storage.dart';
import 'package:siaa_mobile/features/auth/data/auth_repository.dart';
import 'package:siaa_mobile/features/auth/data/sesion_restaurador.dart';
import 'package:siaa_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:siaa_mobile/features/perfil/data/perfil_remote_datasource.dart';
import 'package:siaa_mobile/features/perfil/domain/perfil_model.dart';

import '../../helpers/auth_sesion.dart';

class _PerfilFake extends PerfilRemoteDataSource {
  final PerfilModel? perfil;
  final bool falla;
  _PerfilFake(this.perfil, {this.falla = false}) : super(dio: Dio());

  @override
  Future<PerfilModel?> obtener() async {
    if (falla) throw DioException(requestOptions: RequestOptions());
    return perfil;
  }
}

class _RepoContexto extends AuthRepository {
  String? rolPedido;
  bool falla = false;

  @override
  Future<TokenPair> cambiarContexto({required String rol}) async {
    rolPedido = rol;
    if (falla) {
      throw const AuthException(message: 'Rol fuera de vigencia', code: 'X');
    }
    return TokenPair(
      accessToken: tokenCon({
        'uid': 'u-1',
        'rol': rol,
        'perms': ['reporte:leer']
      }),
      refreshToken: 'r2',
      expiraEn: '',
      usuario: const UsuarioInfo(
        id: 'u-1',
        correo: '',
        nombre: 'Ana',
        apellido: 'Gómez',
        roles: ['DOCENTE', 'COORDINADOR'],
        permisos: ['reporte:leer'],
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  final token = tokenCon({
    'uid': 'u-1',
    'rol': 'COORDINADOR',
    'perms': ['marcaje:leer', 'reporte:leer'],
    'exp': 4102444800,
  });

  test('JwtClaims lee uid, rol, permisos y expiración', () {
    final c = JwtClaims.decodificar(token)!;
    expect(c.usuarioId, 'u-1');
    expect(c.rolActivo, 'COORDINADOR');
    expect(c.permisos, ['marcaje:leer', 'reporte:leer']);
    expect(c.expiradoEn(DateTime.utc(2026)), isFalse);
    expect(JwtClaims.decodificar('no-es-jwt'), isNull);
  });

  test('restaura nombre y roles de /me/perfil y permisos del token', () async {
    final s = await SesionRestaurador(
      leerToken: () async => token,
      perfil: _PerfilFake(const PerfilModel(
          id: 'u-1',
          nombre: 'Ana',
          apellido: 'Gómez',
          correo: 'a@x.co',
          roles: ['DOCENTE', 'COORDINADOR'])),
    ).restaurar();
    expect(s!.nombre, 'Ana Gómez');
    expect(s.roles, ['COORDINADOR', 'DOCENTE']); // el activo primero
    expect(s.permisos, ['marcaje:leer', 'reporte:leer']);
  });

  test('sin red usa el token; sin token no hay sesión', () async {
    final s = await SesionRestaurador(
      leerToken: () async => token,
      perfil: _PerfilFake(null, falla: true),
    ).restaurar();
    expect(s!.roles, ['COORDINADOR']);
    expect(s.nombre, '');
    expect(await SesionRestaurador(leerToken: () async => null).restaurar(),
        isNull);
  });

  test('AuthContextoSolicitado adopta los permisos del nuevo token', () async {
    final repo = _RepoContexto();
    final bloc = await authBlocCon(['marcaje:crear'],
        repository: repo, roles: ['DOCENTE', 'COORDINADOR']);
    bloc.add(const AuthContextoSolicitado('COORDINADOR'));
    final s = await bloc.stream.first as AuthAuthenticated;
    expect(repo.rolPedido, 'COORDINADOR');
    expect(s.permisos, ['reporte:leer']);
    expect(s.rolActivo, 'COORDINADOR');
    expect(await SecureStorage.getRefreshToken(), 'r2');

    repo.falla = true;
    bloc.add(const AuthContextoSolicitado('DOCENTE'));
    final conAviso = await bloc.stream.first as AuthAuthenticated;
    expect(conAviso.avisoContexto, 'Rol fuera de vigencia');
    expect(conAviso.permisos, ['reporte:leer']);
    await bloc.close();
  });

  testWidgets('RoleContextSelector acepta roles del backend y pide el cambio',
      (tester) async {
    final repo = _RepoContexto();
    final auth = await tester.runAsync(() => authBlocCon(['marcaje:crear'],
        repository: repo, roles: ['DOCENTE', 'COORDINADOR']));
    const nav = NavState(
        rolesDisponibles: ['DOCENTE', 'COORDINADOR'], rolActivo: 'docente');
    await tester.pumpWidget(BlocProvider<AuthBloc>.value(
      value: auth!,
      child: MaterialApp(
        home: Scaffold(
          drawer: const Drawer(child: RoleContextSelector(navState: nav)),
          body: Builder(
              builder: (c) => TextButton(
                  onPressed: () => Scaffold.of(c).openDrawer(),
                  child: const Text('abrir'))),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Docente'), findsOneWidget);
    await tester.tap(find.text('Docente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coordinador').last);
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(repo.rolPedido, 'COORDINADOR');
  });
}
