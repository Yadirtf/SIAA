import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/usuarios/presentation/bloc/importacion_usuarios_bloc.dart';

import 'fake_usuarios_repository.dart';

void main() {
  late FakeUsuariosRepository repo;
  late ImportacionUsuariosBloc bloc;

  setUp(() {
    repo = FakeUsuariosRepository();
    bloc = ImportacionUsuariosBloc(repository: repo);
  });

  tearDown(() => bloc.close());

  Future<ImportacionUsuariosState> esperar(ImportacionUsuariosPaso paso) =>
      bloc.stream.firstWhere((s) => s.paso == paso);

  test('valida primero y luego confirma con el mismo CSV', () async {
    const csv = 'correo,nombre,apellido,documento\na@uni.edu.co,A,B,1\n';

    bloc.add(const PrevisualizarImportacionUsuariosEvent(csv));
    final previa = await esperar(ImportacionUsuariosPaso.previa);
    expect(previa.resultado?.confirmado, isFalse);
    expect(previa.resultado?.validas, 1);

    bloc.add(const ConfirmarImportacionUsuariosEvent());
    final fin = await esperar(ImportacionUsuariosPaso.completada);
    expect(fin.resultado?.creados, 1);
    expect(repo.llamadas, ['importar:false', 'importar:true']);
    expect(repo.ultimoCsv, csv);
  });

  test('confirmar sin vista previa no llama al backend', () async {
    bloc.add(const ConfirmarImportacionUsuariosEvent());
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repo.llamadas, isEmpty);
    expect(bloc.state.paso, ImportacionUsuariosPaso.inicial);
  });

  test('un 422 en la validación se muestra como error', () async {
    repo.error = const ApiException(
      message: 'Falta la columna correo',
      statusCode: 422,
    );
    bloc.add(const PrevisualizarImportacionUsuariosEvent('x\n'));

    final s = await bloc.stream.firstWhere((s) => s.error != null);
    expect(s.paso, ImportacionUsuariosPaso.inicial);
    expect(s.error, 'Falta la columna correo');
  });
}
