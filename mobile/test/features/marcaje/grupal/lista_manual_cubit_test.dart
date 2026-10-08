// lista_manual_cubit_test.dart — Pase de lista manual del docente (US-MAR-14)
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/presentation/cubit/lista_manual_cubit.dart';
import 'package:siaa_mobile/features/marcaje/presentation/cubit/lista_manual_state.dart';

import 'fakes_grupal.dart';

void main() {
  late GrupalRemoteFake remote;
  late ListaManualCubit cubit;

  setUp(() async {
    remote = GrupalRemoteFake()..estudiantes = estudiantesGrupo;
    cubit = ListaManualCubit(sesionId: 'ses-1', remote: remote);
    await cubit.cargar();
  });

  tearDown(() => cubit.close());

  test('carga el grupo y solo deja editar a los no bloqueados', () {
    expect(cubit.state.carga, CargaListaManual.lista);
    expect(cubit.state.editables, 1);
    cubit.cambiarPresente('est-1', false);
    expect(cubit.state.presentes.containsKey('est-1'), isFalse);
    cubit.cambiarPresente('est-2', true);
    expect(cubit.state.presente('est-2'), isTrue);
  });

  test('exige motivo antes de enviar', () async {
    await cubit.enviar();
    expect(cubit.state.motivoFaltante, isTrue);
    expect(remote.motivoEnviado, isNull);
    cubit.cambiarMotivo('Sin señal');
    expect(cubit.state.motivoFaltante, isFalse);
  });

  test('envía el grupo completo con el motivo y guarda el resultado', () async {
    cubit.marcarTodos(true);
    cubit.cambiarMotivo('  Falla de red en el aula  ');
    await cubit.enviar();
    expect(remote.motivoEnviado, 'Falla de red en el aula');
    expect(remote.presentesEnviados, {'est-1': true, 'est-2': true});
    expect(cubit.state.resultado?.registrados, 1);
    expect(cubit.state.resultado?.noPertenecen, ['ajeno']);
  });

  test('muestra el mensaje del servidor si el envío falla', () async {
    remote.errorRegistrar =
        errorApi(422, 'El motivo es obligatorio', codigo: 'VALIDACION');
    cubit.cambiarMotivo('x');
    await cubit.enviar();
    expect(cubit.state.error, 'El motivo es obligatorio');
    expect(cubit.state.enviando, isFalse);
    expect(cubit.state.resultado, isNull);
  });

  test('error al cargar queda en estado de error con el mensaje', () async {
    remote.errorLista = errorApi(403, 'No eres docente de esta sesión');
    await cubit.cargar();
    expect(cubit.state.carga, CargaListaManual.error);
    expect(cubit.state.error, 'No eres docente de esta sesión');
  });
}
