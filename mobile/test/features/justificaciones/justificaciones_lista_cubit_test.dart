import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/justificaciones/data/repositories/justificacion_repository.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/catalogo_justificacion.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/justificacion_exception.dart';
import 'package:siaa_mobile/features/justificaciones/domain/models/justificacion_model.dart';
import 'package:siaa_mobile/features/justificaciones/presentation/cubit/justificacion_detalle_cubit.dart';
import 'package:siaa_mobile/features/justificaciones/presentation/cubit/justificaciones_lista_cubit.dart';
import 'package:siaa_mobile/features/justificaciones/presentation/cubit/justificaciones_lista_state.dart';

class _MockRepo extends Mock implements JustificacionRepository {}

Justificacion _j(String id, {String estado = 'RADICADA'}) => Justificacion(
      id: id,
      sesionId: 's-$id',
      docenteId: 'd1',
      tipo: 'PERMISO',
      descripcion: 'Permiso autorizado por decanatura',
      estado: estado,
    );

void main() {
  late _MockRepo repo;

  setUp(() => repo = _MockRepo());

  blocTest<JustificacionesListaCubit, JustificacionesListaState>(
    'cargar trae la primera página con el total de X-Total-Count',
    build: () {
      when(() => repo.listar(estado: null, pagina: 1, limite: 20)).thenAnswer(
          (_) async =>
              PaginaJustificaciones(items: [_j('1'), _j('2')], total: 2));
      return JustificacionesListaCubit(repo);
    },
    act: (c) => c.cargar(),
    expect: () => [
      const JustificacionesListaState(carga: CargaLista.cargando),
      JustificacionesListaState(
        carga: CargaLista.lista,
        items: [_j('1'), _j('2')],
        total: 2,
      ),
    ],
  );

  blocTest<JustificacionesListaCubit, JustificacionesListaState>(
    'cargar con filtro envía el estado al backend',
    build: () {
      when(() => repo.listar(estado: 'APROBADA', pagina: 1, limite: 20))
          .thenAnswer((_) async => PaginaJustificaciones(
              items: [_j('3', estado: 'APROBADA')], total: 1));
      return JustificacionesListaCubit(repo);
    },
    act: (c) => c.cargar(estado: EstadoJustificacion.aprobada),
    expect: () => [
      const JustificacionesListaState(
        carga: CargaLista.cargando,
        filtro: EstadoJustificacion.aprobada,
      ),
      JustificacionesListaState(
        carga: CargaLista.lista,
        items: [_j('3', estado: 'APROBADA')],
        total: 1,
        filtro: EstadoJustificacion.aprobada,
      ),
    ],
  );

  blocTest<JustificacionesListaCubit, JustificacionesListaState>(
    'error inicial muestra el mensaje del backend',
    build: () {
      when(() => repo.listar(
                estado: any(named: 'estado'),
                pagina: any(named: 'pagina'),
                limite: any(named: 'limite'),
              ))
          .thenThrow(const JustificacionException(
              mensaje:
                  'No se pudo conectar al servidor. Verifica tu conexión.'));
      return JustificacionesListaCubit(repo);
    },
    act: (c) => c.cargar(),
    expect: () => [
      const JustificacionesListaState(carga: CargaLista.cargando),
      const JustificacionesListaState(
        carga: CargaLista.error,
        error: 'No se pudo conectar al servidor. Verifica tu conexión.',
      ),
    ],
  );

  blocTest<JustificacionesListaCubit, JustificacionesListaState>(
    'refrescar con error conserva la lista visible',
    build: () {
      when(() => repo.listar(
            estado: any(named: 'estado'),
            pagina: any(named: 'pagina'),
            limite: any(named: 'limite'),
          )).thenThrow(const JustificacionException(mensaje: 'Sin red'));
      return JustificacionesListaCubit(repo);
    },
    seed: () => JustificacionesListaState(
      carga: CargaLista.lista,
      items: [_j('1')],
      total: 1,
    ),
    act: (c) => c.refrescar(),
    expect: () => [
      JustificacionesListaState(
        carga: CargaLista.lista,
        items: [_j('1')],
        total: 1,
        error: 'Sin red',
      ),
    ],
  );

  blocTest<JustificacionesListaCubit, JustificacionesListaState>(
    'cargarMas pide la página siguiente y acumula',
    build: () {
      when(() => repo.listar(estado: null, pagina: 2, limite: 20)).thenAnswer(
          (_) async => PaginaJustificaciones(items: [_j('21')], total: 21));
      return JustificacionesListaCubit(repo);
    },
    seed: () => JustificacionesListaState(
      carga: CargaLista.lista,
      items: List.generate(20, (i) => _j('$i')),
      total: 21,
    ),
    act: (c) => c.cargarMas(),
    skip: 1,
    expect: () => [
      JustificacionesListaState(
        carga: CargaLista.lista,
        items: [...List.generate(20, (i) => _j('$i')), _j('21')],
        total: 21,
      ),
    ],
  );

  blocTest<JustificacionDetalleCubit, JustificacionDetalleState>(
    'detalle se actualiza con GET /justificaciones/{id}',
    build: () {
      when(() => repo.obtener('1'))
          .thenAnswer((_) async => _j('1', estado: 'EN_REVISION'));
      return JustificacionDetalleCubit(repo, _j('1'));
    },
    act: (c) => c.cargar(),
    expect: () => [
      JustificacionDetalleState(_j('1'), cargando: true),
      JustificacionDetalleState(_j('1', estado: 'EN_REVISION')),
    ],
  );
}
