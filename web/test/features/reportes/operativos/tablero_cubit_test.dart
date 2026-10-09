import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/reportes/data/models/tablero_model.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/tablero_cubit.dart';
import 'package:siaa_web/features/reportes/presentation/bloc/tablero_state.dart';

import 'fake_reportes_operativos_repository.dart';

void main() {
  test('la espera es el intervalo base más un desfase aleatorio', () {
    final r = Random(7);
    final esperas = List.generate(
      50,
      (_) => TableroCubit.esperaConDesfase(60, r),
    );
    for (final e in esperas) {
      expect(e, greaterThanOrEqualTo(const Duration(seconds: 60)));
      expect(e, lessThanOrEqualTo(const Duration(seconds: 90)));
    }
    expect(esperas.toSet().length, greaterThan(1), reason: 'debe variar');
    expect(
      TableroCubit.esperaConDesfase(0, r),
      greaterThanOrEqualTo(const Duration(seconds: 60)),
    );
  });

  test('carga y se reprograma con la espera con desfase', () async {
    final programados = <(Duration, void Function())>[];
    final temporizadores = <_TimerFalso>[];
    final repo = FakeReportesOperativosRepository()
      ..tableroRespuesta = const TableroModel(
        sesionesDelDia: 3,
        refrescoSugeridoSegundos: 30,
      );
    final cubit = TableroCubit(
      repository: repo,
      random: Random(1),
      crearTemporizador: (espera, accion) {
        programados.add((espera, accion));
        final t = _TimerFalso();
        temporizadores.add(t);
        return t;
      },
    );
    await cubit.iniciar();
    expect(cubit.state.status, TableroStatus.cargado);
    expect(cubit.state.tablero!.sesionesDelDia, 3);
    expect(programados.single.$1.inSeconds, inInclusiveRange(30, 45));
    expect(cubit.state.proximaActualizacion, programados.single.$1);

    // Al vencer el temporizador consulta de nuevo y vuelve a programar.
    programados.single.$2();
    await Future<void>.delayed(Duration.zero);
    expect(repo.llamadas, ['tablero', 'tablero']);
    expect(programados.length, 2);

    // Actualizar a mano cancela la espera pendiente.
    await cubit.actualizar();
    expect(temporizadores[1].cancelado, isTrue);
    await cubit.close();
    expect(temporizadores.last.cancelado, isTrue);
  });

  test('un fallo al actualizar conserva los últimos datos', () async {
    final repo = FakeReportesOperativosRepository()
      ..tableroRespuesta = const TableroModel(sesionesEnCurso: 2);
    final cubit = TableroCubit(
      repository: repo,
      crearTemporizador: (_, __) => _TimerFalso(),
    );
    await cubit.iniciar();
    repo.error = const ApiException(message: 'Sin conexión');
    await cubit.actualizar();
    expect(cubit.state.status, TableroStatus.cargado);
    expect(cubit.state.tablero!.sesionesEnCurso, 2);
    expect(cubit.state.error, 'Sin conexión');
    await cubit.close();
  });

  test('sin datos previos el fallo deja el estado en error', () async {
    final repo = FakeReportesOperativosRepository()
      ..error = const ApiException(message: 'Prohibido', statusCode: 403);
    final cubit = TableroCubit(
      repository: repo,
      crearTemporizador: (_, __) => _TimerFalso(),
    );
    await cubit.iniciar();
    expect(cubit.state.status, TableroStatus.error);
    await cubit.close();
  });

  test('interpreta la respuesta del servidor', () {
    final t = TableroModel.fromJson({
      'fecha': '2026-10-09',
      'sesionesDelDia': 4,
      'marcajes': {'entradasDocentes': 2, 'total': 5},
      'sesionesEnCursoSinMarcaje': [
        {
          'sesionId': 's1',
          'docenteId': 'd1',
          'docente': 'Ana',
          'aula': 'A-301 · Aula 301',
          'minutosTranscurridos': 12,
        },
      ],
      'alertasActivas': [
        {
          'docenteId': 'd2',
          'mensaje': 'Racha',
          'creadaEn': '2026-10-08T10:00:00Z',
        },
      ],
      'refrescoSugeridoSegundos': 0,
    });
    expect(t.sesionesDelDia, 4);
    expect(t.entradasDocentes, 2);
    expect(t.marcajesTotal, 5);
    expect(t.sinMarcaje.single.aula, 'A-301 · Aula 301');
    expect(t.alertas.single.creadaEn, isNotNull);
    expect(t.refrescoSugeridoSegundos, 60);
  });
}

class _TimerFalso implements Timer {
  bool cancelado = false;

  @override
  void cancel() => cancelado = true;

  @override
  bool get isActive => !cancelado;

  @override
  int get tick => 0;
}
