import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/usuarios/data/models/usuario_model.dart';
import 'package:siaa_web/features/usuarios/data/models/usuario_requests.dart';
import 'package:siaa_web/features/usuarios/presentation/bloc/usuarios_bloc.dart';
import 'package:siaa_web/features/usuarios/presentation/bloc/usuarios_event.dart';
import 'package:siaa_web/features/usuarios/presentation/bloc/usuarios_filtro.dart';
import 'package:siaa_web/features/usuarios/presentation/bloc/usuarios_state.dart';

import 'fake_usuarios_repository.dart';

void main() {
  late FakeUsuariosRepository repo;
  late UsuariosBloc bloc;

  const ana = UsuarioModel(
    id: 'u1',
    correo: 'ana@uni.edu.co',
    nombre: 'Ana',
    apellido: 'Pérez',
    activo: true,
    roles: ['DOCENTE'],
  );

  setUp(() {
    repo = FakeUsuariosRepository()..usuarios = [ana];
    bloc = UsuariosBloc(repository: repo);
  });

  tearDown(() => bloc.close());

  Future<UsuariosState> esperar(bool Function(UsuariosState) cond) =>
      bloc.stream.firstWhere(cond);

  test('estado inicial', () {
    expect(bloc.state.status, UsuariosStatus.inicial);
    expect(bloc.state.usuarios, isEmpty);
  });

  test('CargarUsuariosEvent emite cargando y luego cargado con el filtro', () {
    const filtro = UsuariosFiltro(texto: 'ana', rol: 'DOCENTE', activo: true);

    expectLater(
      bloc.stream,
      emitsInOrder([
        isA<UsuariosState>().having(
          (s) => s.status,
          'status',
          UsuariosStatus.cargando,
        ),
        isA<UsuariosState>()
            .having((s) => s.status, 'status', UsuariosStatus.cargado)
            .having((s) => s.usuarios, 'usuarios', [ana])
            .having((s) => s.pagina?.total, 'total', 1)
            .having((s) => s.filtro, 'filtro', filtro),
      ]),
    );

    bloc.add(const CargarUsuariosEvent(filtro));
  });

  test('un error de carga expone el mensaje del backend', () async {
    repo.error = const AuthException(
      message: 'No tiene permiso usuario:leer',
      statusCode: 403,
    );
    bloc.add(const CargarUsuariosEvent());

    final s = await esperar((s) => s.status == UsuariosStatus.error);
    expect(s.errorCarga, 'No tiene permiso usuario:leer');
  });

  test('crear sin contraseña informa el envío de la invitación', () async {
    bloc.add(const CargarUsuariosEvent());
    await esperar((s) => s.status == UsuariosStatus.cargado);

    bloc.add(
      const CrearUsuarioEvent(
        CrearUsuarioRequest(
          correo: 'nuevo@uni.edu.co',
          nombre: 'Nuevo',
          apellido: 'Usuario',
          roles: ['DOCENTE'],
        ),
      ),
    );

    final s = await esperar((s) => s.mensajeExito != null);
    expect(s.procesando, isFalse);
    expect(s.mensajeExito, contains('invitación'));
    expect(s.mensajeExito, contains('nuevo@uni.edu.co'));
    expect(s.usuarios, hasLength(2));
    expect(repo.llamadas, ['listar', 'crear', 'listar']);
  });

  test('un 409 al crear deja el mensaje de error y no recarga', () async {
    bloc.add(const CargarUsuariosEvent());
    await esperar((s) => s.status == UsuariosStatus.cargado);
    repo.error = const ApiException(
      message: 'El documento ya está registrado',
      statusCode: 409,
    );

    bloc.add(
      const CrearUsuarioEvent(
        CrearUsuarioRequest(correo: 'x@uni.edu.co', nombre: 'X', apellido: 'Y'),
      ),
    );

    final s = await esperar((s) => s.mensajeError != null);
    expect(s.mensajeError, 'El documento ya está registrado');
    expect(s.procesando, isFalse);
    expect(s.status, UsuariosStatus.cargado);
    expect(repo.llamadas.last, 'crear');
  });

  test('desactivar envía el motivo y refresca el listado', () async {
    bloc.add(const CargarUsuariosEvent());
    await esperar((s) => s.status == UsuariosStatus.cargado);

    bloc.add(const DesactivarUsuarioEvent('u1', 'Retiro de la institución'));

    final s = await esperar((s) => s.mensajeExito != null);
    expect(repo.llamadas, contains('desactivar:Retiro de la institución'));
    expect(s.usuarios.single.activo, isFalse);
    expect(s.mensajeExito, 'Usuario desactivado.');
  });

  test('LimpiarMensajesUsuariosEvent borra los mensajes', () async {
    bloc.add(const CargarUsuariosEvent());
    await esperar((s) => s.status == UsuariosStatus.cargado);
    bloc.add(const DesbloquearUsuarioEvent('u1'));
    await esperar((s) => s.mensajeExito != null);

    bloc.add(const LimpiarMensajesUsuariosEvent());
    final s = await esperar((s) => s.mensajeExito == null);
    expect(s.mensajeError, isNull);
  });
}
