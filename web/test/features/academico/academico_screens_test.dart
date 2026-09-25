// academico_screens_test.dart - Pruebas de integración de pantallas académicas en Web (EP-04)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/academico/data/models/academico_models.dart';
import 'package:siaa_web/features/academico/data/models/importacion_model.dart';
import 'package:siaa_web/features/academico/data/models/sesion_model.dart';
import 'package:siaa_web/features/academico/domain/academico_repository.dart';
import 'package:siaa_web/features/academico/presentation/bloc/academico_bloc.dart';
import 'package:siaa_web/features/academico/presentation/bloc/academico_event.dart';
import 'package:siaa_web/features/academico/presentation/bloc/importacion_bloc.dart';
import 'package:siaa_web/features/academico/presentation/bloc/sesiones_bloc.dart';
import 'package:siaa_web/features/academico/presentation/screens/asignaciones_screen.dart';
import 'package:siaa_web/features/academico/presentation/screens/estructura_screen.dart';
import 'package:siaa_web/features/academico/presentation/screens/sesiones_screen.dart';

class StubAcademicoRepository implements AcademicoRepository {
  @override
  Future<List<PeriodoModel>> getPeriodos() async => [
        const PeriodoModel(
          id: 'per-1',
          codigo: '2026-1',
          nombre: 'Periodo 2026-1',
          fechaInicio: '2026-02-01',
          fechaFin: '2026-06-30',
          estado: 'ACTIVO',
        ),
      ];

  @override
  Future<PeriodoModel> createPeriodo({
    required String codigo,
    required String nombre,
    required String fechaInicio,
    required String fechaFin,
    required String estado,
  }) async =>
      PeriodoModel(
        id: 'p-1',
        codigo: codigo,
        nombre: nombre,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        estado: estado,
      );

  @override
  Future<List<FacultadModel>> getFacultades() async => [
        const FacultadModel(id: 'f-1', codigo: 'ING', nombre: 'Ingeniería'),
      ];
  @override
  Future<FacultadModel> createFacultad({
    required String codigo,
    required String nombre,
    String? sedeId,
  }) async =>
      FacultadModel(id: 'f-1', codigo: codigo, nombre: nombre);
  @override
  Future<void> deleteFacultad(String id) async {}

  @override
  Future<List<ProgramaModel>> getProgramas() async => [
        const ProgramaModel(
          id: 'pr-1',
          facultadId: 'f-1',
          codigo: 'ISIS',
          nombre: 'Ing. Sistemas',
        ),
      ];
  @override
  Future<ProgramaModel> createPrograma({
    required String codigo,
    required String nombre,
    required String facultadId,
  }) async =>
      ProgramaModel(id: 'pr-1', codigo: codigo, nombre: nombre, facultadId: facultadId);
  @override
  Future<void> deletePrograma(String id) async {}

  @override
  Future<List<AsignaturaModel>> getAsignaturas() async => [
        const AsignaturaModel(
          id: 'as-1',
          programaId: 'pr-1',
          codigo: 'CALC1',
          nombre: 'Cálculo Diferencial',
          creditos: 4,
        ),
      ];
  @override
  Future<AsignaturaModel> createAsignatura({
    required String codigo,
    required String nombre,
    required String programaId,
    required int creditos,
  }) async =>
      AsignaturaModel(
        id: 'as-1',
        codigo: codigo,
        nombre: nombre,
        programaId: programaId,
        creditos: creditos,
      );
  @override
  Future<void> deleteAsignatura(String id) async {}

  @override
  Future<List<GrupoModel>> getGrupos() async => [
        const GrupoModel(
          id: 'gr-1',
          numero: 'GRP-01',
          asignaturaId: 'as-1',
          periodoId: 'per-1',
          cupo: 35,
        ),
      ];
  @override
  Future<GrupoModel> createGrupo({
    required String numero,
    required String asignaturaId,
    required String periodoId,
    required int cupo,
  }) async =>
      GrupoModel(id: 'gr-1', numero: numero, asignaturaId: asignaturaId, periodoId: periodoId, cupo: cupo);
  @override
  Future<void> deleteGrupo(String id) async {}

  @override
  Future<List<AsignacionModel>> getAsignaciones() async => [
        const AsignacionModel(
          id: 'asig-1',
          periodoId: 'per-1',
          docenteNombre: 'Ing. Carlos Mendoza',
          grupoId: 'gr-1',
          asignaturaId: 'as-1',
          diaSemana: 1,
          horaInicio: '08:00',
          horaFin: '10:00',
          modalidad: 'PRESENCIAL',
          estado: 'ACTIVA',
        ),
      ];
  @override
  Future<AsignacionModel> createAsignacion(Map<String, dynamic> body) async =>
      const AsignacionModel(
        id: 'asig-2',
        periodoId: 'per-1',
        docenteNombre: 'Dra. Ana Vega',
        grupoId: 'gr-1',
        asignaturaId: 'as-1',
        diaSemana: 2,
        horaInicio: '10:00',
        horaFin: '12:00',
        modalidad: 'PRESENCIAL',
        estado: 'ACTIVA',
      );
  @override
  Future<void> deleteAsignacion(String id) async {}

  @override
  Future<List<ExcepcionModel>> getExcepciones() async => [];
  @override
  Future<ExcepcionModel> createExcepcion({
    required String nombre,
    required String tipo,
    required String ambito,
    required String fechaInicio,
    required String fechaFin,
    String? ambitoId,
  }) async =>
      ExcepcionModel(
        id: 'ex-1',
        nombre: nombre,
        tipo: tipo,
        ambito: ambito,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );
  @override
  Future<void> deleteExcepcion(String id) async {}

  @override
  Future<List<SesionModel>> getSesiones({
    String? periodoId,
    String? docenteId,
    String? espacioId,
    String? fecha,
    String? estado,
  }) async =>
      [
        const SesionModel(
          id: 'ses-1',
          periodoId: 'per-1',
          asignacionId: 'asig-1',
          asignaturaId: 'as-1',
          grupoId: 'gr-1',
          docenteIds: ['doc-1'],
          espacioId: 'Aula 201',
          fecha: '2026-09-25',
          horaInicio: '08:00',
          horaFin: '10:00',
          inicioProgramado: '2026-09-25T08:00:00Z',
          finProgramado: '2026-09-25T10:00:00Z',
          estado: 'PROGRAMADA',
        ),
      ];

  @override
  Future<void> cancelarSesion({required String sesionId, required String motivo}) async {}

  @override
  Future<SesionModel> reasignarAulaSesion({
    required String sesionId,
    required String nuevoEspacioId,
    String? motivo,
  }) async =>
      SesionModel(
        id: sesionId,
        periodoId: 'per-1',
        asignacionId: 'asig-1',
        asignaturaId: 'as-1',
        grupoId: 'gr-1',
        docenteIds: const ['doc-1'],
        espacioId: nuevoEspacioId,
        fecha: '2026-09-25',
        horaInicio: '08:00',
        horaFin: '10:00',
        inicioProgramado: '2026-09-25T08:00:00Z',
        finProgramado: '2026-09-25T10:00:00Z',
        estado: 'PROGRAMADA',
      );

  @override
  Future<SesionModel> asignarDocenteReemplazo({
    required String sesionId,
    required String docenteId,
    String? motivo,
  }) async =>
      SesionModel(
        id: sesionId,
        periodoId: 'per-1',
        asignacionId: 'asig-1',
        asignaturaId: 'as-1',
        grupoId: 'gr-1',
        docenteIds: [docenteId],
        espacioId: 'Aula 201',
        fecha: '2026-09-25',
        horaInicio: '08:00',
        horaFin: '10:00',
        inicioProgramado: '2026-09-25T08:00:00Z',
        finProgramado: '2026-09-25T10:00:00Z',
        estado: 'PROGRAMADA',
      );

  @override
  Future<PreviewImportacionModel> previewImportarCsv({
    required List<int> bytes,
    required String filename,
  }) async =>
      const PreviewImportacionModel(totalFilas: 0, filasValidas: 0, filasConError: 0, filas: []);

  @override
  Future<void> confirmarImportarCsv({required List<Map<String, dynamic>> filas}) async {}
}

Widget wrapScreen(Widget screen) {
  final repo = StubAcademicoRepository();
  return MultiBlocProvider(
    providers: [
      BlocProvider<AcademicoBloc>(
        create: (_) => AcademicoBloc(repository: repo)..add(const LoadAcademicoDataEvent()),
      ),
      BlocProvider<SesionesBloc>(
        create: (_) => SesionesBloc(repository: repo)..add(const LoadSesionesEvent()),
      ),
      BlocProvider<ImportacionBloc>(
        create: (_) => ImportacionBloc(repository: repo),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(body: screen),
    ),
  );
}

void main() {
  group('EstructuraScreen (US-ACA-01)', () {
    testWidgets('renderiza pestañas jerárquicas y botón registrar', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapScreen(const EstructuraScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Facultades (1)'), findsOneWidget);
      expect(find.text('Programas (1)'), findsOneWidget);
      expect(find.text('Asignaturas (1)'), findsOneWidget);
      expect(find.text('Grupos (1)'), findsOneWidget);
      expect(find.text('Registrar Nuevo'), findsOneWidget);
    });
  });

  group('AsignacionesScreen (US-ACA-03, US-ACA-07)', () {
    testWidgets('renderiza botones de nueva asignación y carga masiva', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapScreen(const AsignacionesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Asignaciones Horarias y Aulas'), findsOneWidget);
      expect(find.text('Nueva Asignación'), findsOneWidget);
      expect(find.text('Carga Masiva CSV'), findsOneWidget);
    });
  });

  group('SesionesScreen (US-ACA-05, US-ACA-06, US-ACA-09)', () {
    testWidgets('renderiza pantalla de sesiones con filtros y acciones', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapScreen(const SesionesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sesiones de Clase Materializadas'), findsOneWidget);
      expect(find.text('Todos los estados'), findsWidgets);
    });
  });
}
