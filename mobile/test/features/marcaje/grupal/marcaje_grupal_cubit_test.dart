// marcaje_grupal_cubit_test.dart — Ventana estudiantil del docente (US-MAR-13)
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';
import 'package:siaa_mobile/features/marcaje/presentation/cubit/marcaje_grupal_cubit.dart';
import 'package:siaa_mobile/features/marcaje/presentation/cubit/marcaje_grupal_state.dart';

import 'fakes_grupal.dart';

void main() {
  late GrupalRemoteFake remote;

  MarcajeGrupalCubit cubitCon(Future<SesionActivaModel?> Function() cargar) =>
      MarcajeGrupalCubit(grupal: remote, cargarSesion: cargar);

  setUp(() => remote = GrupalRemoteFake());

  test('sin clase en curso queda en sinSesion', () async {
    final cubit = cubitCon(() async => null);
    await cubit.cargar();
    expect(cubit.state.carga, CargaGrupal.sinSesion);
    await cubit.close();
  });

  test('recupera la ventana abierta desde el servidor tras recargar', () async {
    final cierre = DateTime.now().toUtc().add(const Duration(minutes: 7));
    final cubit = cubitCon(() async => sesionDocente(ventanaEstudiantil: {
          'abierta': true,
          'abiertaEn': DateTime.now().toUtc().toIso8601String(),
          'cierraEn': cierre.toIso8601String(),
        }));
    await cubit.cargar();
    expect(cubit.state.carga, CargaGrupal.lista);
    expect(cubit.state.ventanaAbierta, isTrue);
    expect(cubit.state.ventana.cierraEn, cierre);
    await cubit.close();
  });

  test('abre con la duración elegida y luego cierra', () async {
    final cubit = cubitCon(() async => sesionDocente());
    await cubit.cargar();
    expect(cubit.state.ventanaAbierta, isFalse);
    cubit.seleccionarDuracion(15);
    await cubit.abrirVentana();
    expect(remote.duracionPedida, 15);
    expect(cubit.state.ventanaAbierta, isTrue);
    expect(cubit.state.aviso, contains('pueden marcar hasta las'));
    expect(cubit.state.avisoEsError, isFalse);

    await cubit.cerrarVentana();
    expect(remote.cierres, 1);
    expect(cubit.state.ventanaAbierta, isFalse);
    expect(cubit.state.aviso, 'Cerraste el marcaje para estudiantes.');
    await cubit.close();
  });

  test('muestra el mensaje del servidor cuando no se puede abrir (409)',
      () async {
    remote.errorAbrir = errorApi(409, 'La sesión no está en curso.');
    final cubit = cubitCon(() async => sesionDocente());
    await cubit.cargar();
    final avisoAntes = cubit.state.avisoId;
    await cubit.abrirVentana();
    expect(cubit.state.aviso, 'La sesión no está en curso.');
    expect(cubit.state.avisoEsError, isTrue);
    expect(cubit.state.avisoId, avisoAntes + 1);
    expect(cubit.state.procesando, isFalse);
    expect(cubit.state.ventanaAbierta, isFalse);
    await cubit.close();
  });

  test('ventanaVencida cierra la ventana local cuando la cuenta llega a cero',
      () async {
    final cubit = cubitCon(() async => sesionDocente());
    await cubit.cargar();
    await cubit.abrirVentana();
    cubit.ventanaVencida();
    expect(cubit.state.ventana.abierta, isFalse);
    await cubit.close();
  });

  test('error de carga sin sesión previa muestra estado de error', () async {
    final cubit = cubitCon(() async => throw errorApi(500, 'Servidor caído'));
    await cubit.cargar();
    expect(cubit.state.carga, CargaGrupal.error);
    expect(cubit.state.error, 'Servidor caído');
    await cubit.close();
  });
}
