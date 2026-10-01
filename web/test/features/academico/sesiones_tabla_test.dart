import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/academico/data/models/sesion_model.dart';
import 'package:siaa_web/features/academico/presentation/bloc/academico_bloc.dart';
import 'package:siaa_web/features/academico/presentation/bloc/sesiones_bloc.dart';
import 'package:siaa_web/features/academico/presentation/helpers/filtro_sesiones.dart';
import 'package:siaa_web/features/academico/presentation/screens/sesiones_screen.dart';

import 'academico_dialogs_test.dart' show FakeAcademicoRepository;

SesionModel _sesion(
  int n, {
  String docente = 'Ana Pérez',
  String docenteId = 'doc-1',
  String bloque = 'Bloque 1',
  String bloqueId = 'b-1',
  String sede = 'Sede Central',
  String sedeId = 's-1',
  String asignatura = 'Cálculo I',
  String estado = 'PROGRAMADA',
}) => SesionModel(
  id: 'ses-$n',
  periodoId: 'per-1',
  asignacionId: 'asg-1',
  asignaturaId: 'as-1',
  grupoId: 'g-1',
  docenteIds: [docenteId],
  espacioId: 'esp-$bloqueId',
  fecha: '2026-09-${(n % 28 + 1).toString().padLeft(2, '0')}',
  horaInicio: '${(6 + n % 12).toString().padLeft(2, '0')}:00',
  horaFin: '${(7 + n % 12).toString().padLeft(2, '0')}:00',
  inicioProgramado: '',
  finProgramado: '',
  estado: estado,
  asignaturaNombre: asignatura,
  grupoNumero: '0${n % 3 + 1}',
  espacioCodigo: 'A-$n',
  docentesNombres: [docente],
  sedeId: sedeId,
  sedeNombre: sede,
  bloqueId: bloqueId,
  bloqueNombre: bloque,
);

class _RepoSesiones extends FakeAcademicoRepository {
  final List<SesionModel> sesiones;
  final consultas = <(String?, String?, String?)>[];

  _RepoSesiones(this.sesiones);

  @override
  Future<List<SesionModel>> getSesiones({
    String? periodoId,
    String? docenteId,
    String? espacioId,
    String? fecha,
    String? estado,
    String? desde,
    String? hasta,
  }) async {
    consultas.add((periodoId, desde, hasta));
    return sesiones;
  }
}

void main() {
  group('filtros de sesiones', () {
    final sesiones = [
      _sesion(1),
      _sesion(2, docente: 'Bruno Díaz', docenteId: 'doc-2'),
      _sesion(3, bloque: 'Bloque 2', bloqueId: 'b-2', asignatura: 'Física'),
      _sesion(4, sede: 'Sede Norte', sedeId: 's-2', bloqueId: 'b-9'),
    ];

    test('combina sede, bloque, docente y búsqueda sin tildes', () {
      expect(const FiltroSesiones(sedeId: 's-2').aplicar(sesiones).length, 1);
      expect(
        const FiltroSesiones(bloqueId: 'b-2').aplicar(sesiones).single.id,
        'ses-3',
      );
      expect(
        const FiltroSesiones(docenteId: 'doc-2').aplicar(sesiones).single.id,
        'ses-2',
      );
      expect(
        const FiltroSesiones(texto: 'fisica').aplicar(sesiones).single.id,
        'ses-3',
      );
      expect(
        const FiltroSesiones(texto: 'DIAZ').aplicar(sesiones).single.id,
        'ses-2',
      );
      expect(
        const FiltroSesiones(texto: 'sede norte').aplicar(sesiones).single.id,
        'ses-4',
      );
    });

    test('las opciones de bloque se acotan a la sede elegida', () {
      final todas = OpcionesSesiones.desde(sesiones, const FiltroSesiones());
      expect(todas.sedes.values, ['Sede Central', 'Sede Norte']);
      expect(todas.docentes.values, ['Ana Pérez', 'Bruno Díaz']);
      final norte = OpcionesSesiones.desde(
        sesiones,
        const FiltroSesiones(sedeId: 's-2'),
      );
      expect(norte.bloques.keys, ['b-9']);
    });

    test('ordena por docente y luego por fecha', () {
      final orden = ordenarSesiones(sesiones, ColumnaSesion.docente, false);
      expect(orden.first.id, 'ses-2');
    });

    test('la semana va de lunes a domingo y las fechas se leen en español', () {
      final semana = semanaDe(DateTime(2026, 10, 1));
      expect(fechaIso(semana.start), '2026-09-28');
      expect(fechaIso(semana.end), '2026-10-04');
      expect(fechaSesion('2026-10-01'), 'jue 1 oct');
    });
  });

  group('SesionesScreen como tabla', () {
    late _RepoSesiones repo;

    Future<void> abrir(WidgetTester tester, List<SesionModel> sesiones) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      repo = _RepoSesiones(sesiones);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => AcademicoBloc(repository: repo)),
            BlocProvider(create: (_) => SesionesBloc(repository: repo)),
          ],
          child: const MaterialApp(home: Scaffold(body: SesionesScreen())),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('consulta la semana actual y pagina de 25 en 25', (
      tester,
    ) async {
      await abrir(tester, [for (var i = 0; i < 30; i++) _sesion(i)]);

      final semana = semanaDe(DateTime.now());
      expect(repo.consultas.single, (
        null,
        fechaIso(semana.start),
        fechaIso(semana.end),
      ));
      expect(find.text('Mostrando 1-25 de 30 sesiones'), findsOneWidget);
      expect(find.text('Bloque 1 · Sede Central'), findsNWidgets(25));

      await tester.tap(find.byTooltip('Página siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Mostrando 26-30 de 30 sesiones'), findsOneWidget);
    });

    testWidgets('filtra por docente y muestra la hora con a. m./p. m.', (
      tester,
    ) async {
      await abrir(tester, [
        _sesion(1),
        _sesion(7, docente: 'Bruno Díaz', docenteId: 'doc-2'),
      ]);
      expect(find.text('7:00 a. m. - 8:00 a. m.'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(DropdownButtonFormField<String?>, 'Docente'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bruno Díaz').last);
      await tester.pumpAndSettle();

      expect(find.text('Mostrando 1-1 de 1 sesiones'), findsOneWidget);
      expect(find.text('1:00 p. m. - 2:00 p. m.'), findsOneWidget);
      expect(find.text('Limpiar filtros'), findsOneWidget);
    });

    testWidgets('la semana siguiente vuelve a consultar el servidor', (
      tester,
    ) async {
      await abrir(tester, const []);
      expect(
        find.text('No hay sesiones en este rango de fechas'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Semana siguiente'));
      await tester.pumpAndSettle();

      final siguiente = semanaDe(DateTime.now().add(const Duration(days: 7)));
      expect(repo.consultas.last.$2, fechaIso(siguiente.start));
      expect(find.text('Esta semana'), findsOneWidget);
    });
  });
}
