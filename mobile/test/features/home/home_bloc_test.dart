import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/geo_editor/data/espacio_repository.dart';
import 'package:siaa_mobile/features/home/presentation/bloc/home_bloc.dart';
import 'package:siaa_mobile/features/home/presentation/bloc/home_event.dart';

// Mock simple en memoria para pruebas del BLoC
class MockEspacioRepository extends EspacioRepository {
  final List<SedeModel> sedesMock;
  final List<BloqueModel> bloquesMock;
  final List<EspacioModel> espaciosMock;

  MockEspacioRepository({
    this.sedesMock = const [],
    this.bloquesMock = const [],
    this.espaciosMock = const [],
  });

  @override
  Future<List<SedeModel>> obtenerSedes() async => sedesMock;

  @override
  Future<List<BloqueModel>> obtenerBloques({String? sedeId}) async =>
      bloquesMock;

  @override
  Future<List<EspacioModel>> obtenerEspacios({
    String? sedeId,
    String? bloqueId,
    String? tipo,
    String? estado,
  }) async =>
      espaciosMock;
}

void main() {
  group('HomeBloc (Pruebas Unitarias de Lógica de Negocio)', () {
    test(
        'CargarSedesRequested: carga sedes, selecciona primera y encadena carga de bloques',
        () async {
      const sede =
          SedeModel(id: 'sede-1', codigo: 'SEDE-01', nombre: 'Principal');
      const bloque = BloqueModel(
          id: 'blq-1',
          sedeId: 'sede-1',
          codigo: 'B-1',
          nombre: 'Bloque 1',
          pisos: [1, 2]);
      const espacio = EspacioModel(
        id: 'esp-1',
        sedeId: 'sede-1',
        codigo: 'A-101',
        nombre: 'Aula 101',
        capacidad: 30,
        tipo: 'AULA',
        estado: 'ACTIVO',
        nivelValidacion: 'AULA',
        bufferMetros: 10,
        areaMetrosCuadrados: 50,
        tieneGeometria: false,
      );

      final repo = MockEspacioRepository(
        sedesMock: [sede],
        bloquesMock: [bloque],
        espaciosMock: [espacio],
      );

      final bloc = HomeBloc(repository: repo);
      addTearDown(bloc.close);

      bloc.add(const CargarSedesRequested());
      await Future.delayed(Duration.zero);
      await Future.delayed(Duration.zero);

      expect(bloc.state.sedes.length, equals(1));
      expect(bloc.state.sedeSeleccionada, equals(sede));
      expect(bloc.state.bloques.length, equals(1));
      expect(bloc.state.bloqueSeleccionado, equals(bloque));
      expect(bloc.state.espacios.length, equals(1));
    });

    test(
        'LimpiarMensajesHomeRequested: resetea error, exito y ultimoEspacioCreado',
        () async {
      final bloc = HomeBloc();
      addTearDown(bloc.close);

      bloc.add(const LimpiarMensajesHomeRequested());
      await Future.delayed(Duration.zero);

      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.successMessage, isNull);
      expect(bloc.state.ultimoEspacioCreado, isNull);
    });
  });
}
