// academico_dialogs_test.dart - Pruebas de diálogos y formularios académicos en Web (EP-04)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/academico/data/models/academico_models.dart';
import 'package:siaa_web/features/academico/data/models/importacion_model.dart';
import 'package:siaa_web/features/academico/data/models/sesion_model.dart';
import 'package:siaa_web/features/academico/domain/academico_repository.dart';
import 'package:siaa_web/features/academico/presentation/bloc/academico_bloc.dart';
import 'package:siaa_web/features/academico/presentation/bloc/sesiones_bloc.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/asignatura_dialog.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/facultad_dialog.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/grupo_dialog.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/programa_dialog.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/sesion_ops_dialogs.dart';

class FakeAcademicoRepository implements AcademicoRepository {
  @override
  Future<List<PeriodoModel>> getPeriodos() async => [];
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
  Future<List<FacultadModel>> getFacultades() async => [];
  @override
  Future<FacultadModel> createFacultad({
    required String codigo,
    required String nombre,
    String? sedeId,
  }) async =>
      FacultadModel(id: 'fac-1', codigo: codigo, nombre: nombre);
  @override
  Future<void> deleteFacultad(String id) async {}

  @override
  Future<List<ProgramaModel>> getProgramas() async => [];
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
  Future<List<AsignaturaModel>> getAsignaturas() async => [];
  @override
  Future<AsignaturaModel> createAsignatura({
    required String codigo,
    required String nombre,
    required String programaId,
    required int creditos,
  }) async =>
      AsignaturaModel(id: 'as-1', codigo: codigo, nombre: nombre, programaId: programaId, creditos: creditos);
  @override
  Future<void> deleteAsignatura(String id) async {}

  @override
  Future<List<GrupoModel>> getGrupos() async => [];
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
  Future<List<AsignacionModel>> getAsignaciones() async => [];
  @override
  Future<AsignacionModel> createAsignacion(Map<String, dynamic> body) async =>
      const AsignacionModel(
        id: 'asig-1',
        periodoId: 'per-1',
        docenteNombre: 'Profesor X',
        grupoId: 'grp-1',
        asignaturaId: 'asig-1',
        diaSemana: 1,
        horaInicio: '08:00',
        horaFin: '10:00',
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
      [];

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
        asignaturaId: 'asig-1',
        grupoId: 'grp-1',
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
        asignaturaId: 'asig-1',
        grupoId: 'grp-1',
        docenteIds: [docenteId],
        espacioId: 'esp-1',
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

Widget wrapWithBlocs(Widget child) {
  final repo = FakeAcademicoRepository();
  return MultiBlocProvider(
    providers: [
      BlocProvider<AcademicoBloc>(create: (_) => AcademicoBloc(repository: repo)),
      BlocProvider<SesionesBloc>(create: (_) => SesionesBloc(repository: repo)),
    ],
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Modelos Académicos (EP-04)', () {
    test('SesionModel deserializa correctamente', () {
      final json = {
        'id': 'ses-1',
        'periodoId': 'per-2026-1',
        'asignacionId': 'asig-calc',
        'asignaturaId': 'asig-calc',
        'grupoId': 'grp-1',
        'docenteIds': ['doc-1', 'doc-2'],
        'espacioId': 'esp-101',
        'fecha': '2026-09-25',
        'horaInicio': '08:00',
        'horaFin': '10:00',
        'inicioProgramado': '2026-09-25T08:00:00Z',
        'finProgramado': '2026-09-25T10:00:00Z',
        'estado': 'PROGRAMADA',
      };

      final sesion = SesionModel.fromJson(json);
      expect(sesion.id, equals('ses-1'));
      expect(sesion.docenteIds.length, equals(2));
      expect(sesion.esCancelada, isFalse);
    });

    test('PreviewImportacionModel calcula resumen correctamente', () {
      final json = {
        'totalFilas': 3,
        'filasValidas': 2,
        'filasConError': 1,
        'filas': [
          {
            'numeroFila': 1,
            'valida': true,
            'periodoCodigo': '2026-1',
            'asignaturaCodigo': 'CALC1',
            'grupoCodigo': 'G1',
            'docenteDocumento': 'doc-1',
            'aulaCodigo': 'A101',
            'diaSemana': 1,
            'horaInicio': '08:00',
            'horaFin': '10:00',
          },
          {
            'numeroFila': 2,
            'valida': false,
            'errores': ['Docente no encontrado'],
          }
        ]
      };

      final preview = PreviewImportacionModel.fromJson(json);
      expect(preview.totalFilas, equals(3));
      expect(preview.filasValidas, equals(2));
      expect(preview.filasConError, equals(1));
      expect(preview.filas.length, equals(2));
      expect(preview.filas[1].valida, isFalse);
      expect(preview.filas[1].errores.first, equals('Docente no encontrado'));
    });
  });

  group('FacultadDialog (US-ACA-01)', () {
    testWidgets('valida campos obligatorios', (tester) async {
      await tester.pumpWidget(
        wrapWithBlocs(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => BlocProvider.value(
                  value: ctx.read<AcademicoBloc>(),
                  child: const FacultadDialog(),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva Facultad'), findsOneWidget);

      await tester.tap(find.text('Crear Facultad'));
      await tester.pumpAndSettle();

      expect(find.text('El código es obligatorio'), findsOneWidget);
      expect(find.text('El nombre es obligatorio'), findsOneWidget);
    });
  });

  group('ProgramaDialog (US-ACA-01)', () {
    testWidgets('requiere selección de facultad y datos', (tester) async {
      final facultades = [
        const FacultadModel(id: 'fac-1', codigo: 'ING', nombre: 'Ingeniería'),
      ];

      await tester.pumpWidget(
        wrapWithBlocs(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => BlocProvider.value(
                  value: ctx.read<AcademicoBloc>(),
                  child: ProgramaDialog(facultades: facultades),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Programa Académico'), findsOneWidget);

      await tester.tap(find.text('Crear Programa'));
      await tester.pumpAndSettle();

      expect(find.text('El código es obligatorio'), findsOneWidget);
    });
  });

  group('AsignaturaDialog (US-ACA-01)', () {
    testWidgets('renderiza formulario de asignatura', (tester) async {
      final programas = [
        const ProgramaModel(
          id: 'prog-1',
          facultadId: 'fac-1',
          codigo: 'ISIS',
          nombre: 'Ing. Sistemas',
        ),
      ];

      await tester.pumpWidget(
        wrapWithBlocs(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => BlocProvider.value(
                  value: ctx.read<AcademicoBloc>(),
                  child: AsignaturaDialog(programas: programas),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva Asignatura'), findsOneWidget);
      expect(find.text('Créditos Académicos'), findsOneWidget);
    });
  });

  group('GrupoDialog (US-ACA-01)', () {
    testWidgets('renderiza formulario de grupo y cupo', (tester) async {
      final asignaturas = [
        const AsignaturaModel(
          id: 'asig-1',
          programaId: 'prog-1',
          codigo: 'PROG1',
          nombre: 'Programación I',
          creditos: 3,
        ),
      ];
      final periodos = [
        const PeriodoModel(
          id: 'per-1',
          codigo: '2026-1',
          nombre: '2026-1',
          fechaInicio: '2026-02-01',
          fechaFin: '2026-06-30',
          estado: 'ACTIVO',
        ),
      ];

      await tester.pumpWidget(
        wrapWithBlocs(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => BlocProvider.value(
                  value: ctx.read<AcademicoBloc>(),
                  child: GrupoDialog(
                    asignaturas: asignaturas,
                    periodos: periodos,
                  ),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo Grupo'), findsOneWidget);
      expect(find.text('Cupo Máximo de Estudiantes'), findsOneWidget);
    });
  });

  group('Sesion Operations Dialogs (US-ACA-06, US-ACA-09)', () {
    testWidgets('CancelarSesionDialog valida campos', (tester) async {
      await tester.pumpWidget(
        wrapWithBlocs(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => BlocProvider.value(
                  value: ctx.read<SesionesBloc>(),
                  child: const CancelarSesionDialog(
                    sesionId: 'ses-1',
                  ),
                ),
              ),
              child: const Text('Abrir Cancelar'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Cancelar Sesión de Clase (US-ACA-06)'), findsOneWidget);
      expect(find.text('Confirmar Cancelación'), findsOneWidget);
    });

    testWidgets('ReasignarAulaDialog renderiza campos de aula', (tester) async {
      await tester.pumpWidget(
        wrapWithBlocs(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => BlocProvider.value(
                  value: ctx.read<SesionesBloc>(),
                  child: const ReasignarAulaDialog(
                    sesionId: 'ses-1',
                    aulaActual: 'Aula 101',
                  ),
                ),
              ),
              child: const Text('Abrir Reasignar'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Reasignar'));
      await tester.pumpAndSettle();

      expect(find.text('Reasignar Aula (US-ACA-06)'), findsOneWidget);
      expect(find.text('Aula actual: Aula 101'), findsOneWidget);
    });

    testWidgets('DocenteReemplazoDialog renderiza selector de reemplazo', (tester) async {
      await tester.pumpWidget(
        wrapWithBlocs(
          Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showDialog(
                context: ctx,
                builder: (_) => BlocProvider.value(
                  value: ctx.read<SesionesBloc>(),
                  child: const DocenteReemplazoDialog(
                    sesionId: 'ses-1',
                    docenteActual: 'Dr. López',
                  ),
                ),
              ),
              child: const Text('Abrir Reemplazo'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Abrir Reemplazo'));
      await tester.pumpAndSettle();

      expect(find.text('Docente Suplente (US-ACA-09)'), findsOneWidget);
      expect(find.text('Titular actual: Dr. López'), findsOneWidget);
    });
  });
}
