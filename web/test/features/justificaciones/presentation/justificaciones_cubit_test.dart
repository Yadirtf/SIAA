import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/features/justificaciones/data/models/adjunto_model.dart';
import 'package:siaa_web/features/justificaciones/data/models/justificacion_model.dart';
import 'package:siaa_web/features/justificaciones/presentation/bloc/justificacion_detalle_cubit.dart';
import 'package:siaa_web/features/justificaciones/presentation/bloc/justificaciones_cubit.dart';
import 'package:siaa_web/features/justificaciones/presentation/bloc/justificaciones_state.dart';

import 'fake_justificaciones_repository.dart';

const _radicada = JustificacionModel(
  id: 'j1',
  sesionId: 's1',
  docenteId: 'd1',
  tipo: 'PERMISO',
  descripcion: 'Permiso por cita médica',
  estado: 'RADICADA',
);

void main() {
  late FakeJustificacionesRepository repo;

  setUp(() {
    repo = FakeJustificacionesRepository()
      ..justificaciones = [
        _radicada,
        const JustificacionModel(
          id: 'j2',
          sesionId: 's2',
          docenteId: 'd2',
          tipo: 'COMISION',
          descripcion: 'Comisión de estudios',
          estado: 'APROBADA',
        ),
      ];
  });

  group('JustificacionesCubit', () {
    test(
      'carga las radicadas y resuelve nombres; sin nombre usa el id',
      () async {
        repo.nombres = {'d1': 'Ana Pérez'};
        final cubit = JustificacionesCubit(repository: repo);
        await cubit.cargar();

        expect(cubit.state.status, JustificacionesStatus.cargado);
        expect(repo.ultimoFiltro!.estado, 'RADICADA');
        expect(cubit.state.justificaciones.map((j) => j.id), ['j1']);
        expect(cubit.state.nombreDe('d1'), 'Ana Pérez');
        expect(cubit.state.nombreDe('d9'), 'd9');
        await cubit.close();
      },
    );

    test('publica el error del backend', () async {
      repo.error = const ApiException(message: 'Sin permiso', statusCode: 403);
      final cubit = JustificacionesCubit(repository: repo);
      await cubit.cargar();
      expect(cubit.state.status, JustificacionesStatus.error);
      expect(cubit.state.error, 'Sin permiso');
      await cubit.close();
    });

    test('irAPagina conserva los filtros', () async {
      final cubit = JustificacionesCubit(repository: repo);
      await cubit.cargar(cubit.state.filtro.copyWith(tipo: () => 'PERMISO'));
      await cubit.irAPagina(2);
      expect(repo.ultimoFiltro!.pagina, 2);
      expect(repo.ultimoFiltro!.tipo, 'PERMISO');
      await cubit.close();
    });
  });

  group('JustificacionDetalleCubit', () {
    JustificacionDetalleCubit crear() =>
        JustificacionDetalleCubit(repository: repo, inicial: _radicada);

    test(
      'rechazar sin observaciones suficientes no llama al backend',
      () async {
        final cubit = crear();
        final ok = await cubit.revisar('RECHAZADA', observaciones: 'corto');
        expect(ok, isFalse);
        expect(cubit.state.error, contains('10 caracteres'));
        expect(repo.llamadas, isNot(contains('revisar:RECHAZADA')));
        await cubit.close();
      },
    );

    test('aprobar actualiza el estado y publica el éxito', () async {
      final cubit = crear();
      final estados = <JustificacionDetalleState>[];
      final sub = cubit.stream.listen(estados.add);
      final ok = await cubit.revisar('APROBADA');
      expect(ok, isTrue);
      expect(cubit.state.justificacion.estado, 'APROBADA');
      expect(estados.any((s) => s.mensajeExito != null), isTrue);
      await sub.cancel();
      await cubit.close();
    });

    test('un 409 muestra el error y recarga el estado vigente', () async {
      repo.errorRevisar = const ApiException(
        message: 'La justificación ya fue decidida.',
        statusCode: 409,
      );
      final cubit = crear();
      final estados = <JustificacionDetalleState>[];
      final sub = cubit.stream.listen(estados.add);
      final ok = await cubit.revisar('APROBADA');
      expect(ok, isFalse);
      expect(
        estados.any((s) => s.error?.contains('ya fue decidida') ?? false),
        isTrue,
      );
      expect(repo.llamadas, contains('obtener'));
      await sub.cancel();
      await cubit.close();
    });

    test('descargarSoporte devuelve el archivo', () async {
      final cubit = crear();
      final archivo = await cubit.descargarSoporte(
        const AdjuntoModel(
          id: 'a1',
          nombre: 'soporte.pdf',
          mime: 'application/pdf',
        ),
      );
      expect(archivo!.esPdf, isTrue);
      expect(repo.llamadas, contains('soporte:a1'));
      await cubit.close();
    });
  });
}
