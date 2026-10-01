import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/widgets/selector_busqueda.dart';
import 'package:siaa_web/features/academico/data/models/academico_models.dart';
import 'package:siaa_web/features/academico/presentation/bloc/academico_bloc.dart';
import 'package:siaa_web/features/academico/presentation/dialogs/asignacion_dialog.dart';
import 'package:siaa_web/features/geo/data/buscador_espacios.dart';
import 'package:siaa_web/features/usuarios/data/buscador_usuarios.dart';

import 'academico_dialogs_test.dart' show FakeAcademicoRepository;
import 'fake_catalogos.dart';

class _RepoQueCaptura extends FakeAcademicoRepository {
  final cuerpos = <Map<String, dynamic>>[];

  /// Si se define, el "servidor" rechaza el guardado con este error.
  Object? rechazo;

  @override
  Future<AsignacionModel> createAsignacion(Map<String, dynamic> body) {
    cuerpos.add(body);
    if (rechazo != null) return Future.error(rechazo!);
    return super.createAsignacion(body);
  }
}

const _choqueDocente = ApiException(
  statusCode: 409,
  message:
      'Ana Pérez ya tiene clase el miércoles de 6:30 p. m. a 7:30 p. m. '
      '(Cálculo I, grupo 01, aula A-101 · Aula 101).',
  details: {
    'codigo': 'CONFLICTO_HORARIO',
    'contexto': {
      'tipo': 'COLISION_DOCENTE',
      'docente': 'Ana Pérez',
      'asignatura': 'Cálculo I',
      'grupo': '01',
      'aula': 'A-101 · Aula 101',
      'dia': 'miércoles',
      'horaInicio': '6:30 p. m.',
      'horaFin': '7:30 p. m.',
    },
  },
);

const _periodos = [
  PeriodoModel(
    id: 'per-1',
    codigo: '2026-1',
    nombre: 'Primer semestre',
    fechaInicio: '2026-02-01',
    fechaFin: '2026-06-30',
    estado: 'ACTIVO',
    sedeId: 'sede-norte',
  ),
  PeriodoModel(
    id: 'per-2',
    codigo: '2026-2',
    nombre: 'Segundo semestre',
    fechaInicio: '2026-08-01',
    fechaFin: '2026-12-15',
    estado: 'PLANEACION',
  ),
];

const _asignaturas = [
  AsignaturaModel(
    id: 'as-1',
    codigo: 'CAL1',
    nombre: 'Cálculo I',
    programaId: 'pr-1',
    creditos: 4,
  ),
  AsignaturaModel(
    id: 'as-2',
    codigo: 'FIS1',
    nombre: 'Física I',
    programaId: 'pr-1',
    creditos: 3,
  ),
];

const _grupos = [
  GrupoModel(
    id: 'g-1',
    numero: '01',
    asignaturaId: 'as-1',
    periodoId: 'per-1',
    cupo: 30,
  ),
  GrupoModel(
    id: 'g-2',
    numero: '07',
    asignaturaId: 'as-2',
    periodoId: 'per-2',
    cupo: 30,
  ),
];

Finder _selector(String etiqueta) => find.byWidgetPredicate(
  (w) => w is SelectorBusqueda && w.etiqueta == etiqueta,
);

void main() {
  late _RepoQueCaptura repo;
  late FakeBuscadorUsuarios usuarios;
  late FakeBuscadorEspacios espacios;

  setUp(() {
    repo = _RepoQueCaptura();
    usuarios = FakeBuscadorUsuarios([
      docente('doc-1', 'Ana', 'Pérez'),
      docente('doc-2', 'Bruno', 'Díaz'),
    ]);
    espacios = FakeBuscadorEspacios([
      aula('esp-1', 'sede-norte', 'A-101', 'Aula 101'),
      aula('esp-9', 'sede-sur', 'S-900', 'Aula Sur'),
    ]);
  });

  Future<void> abrir(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<BuscadorUsuarios>.value(value: usuarios),
          RepositoryProvider<BuscadorEspacios>.value(value: espacios),
        ],
        child: BlocProvider(
          create: (_) => AcademicoBloc(repository: repo),
          child: MaterialApp(
            home: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showDialog(
                  context: ctx,
                  builder: (_) => BlocProvider.value(
                    value: ctx.read<AcademicoBloc>(),
                    child: const AsignacionDialog(
                      periodos: _periodos,
                      grupos: _grupos,
                      asignaturas: _asignaturas,
                    ),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> elegir(
    WidgetTester tester,
    String etiqueta,
    String opcion,
  ) async {
    await tester.tap(_selector(etiqueta));
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion).last);
    await tester.pumpAndSettle();
  }

  Future<void> elegirHora(
    WidgetTester tester,
    String campo,
    String hora, {
    bool pm = false,
  }) async {
    await tester.tap(find.widgetWithText(InputDecorator, campo));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final campos = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(campos.at(0), hora.split(':')[0]);
    await tester.enterText(campos.at(1), hora.split(':')[1]);
    if (pm) await tester.tap(find.text('PM'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('no pide ids ni nombre del docente escritos a mano', (
    tester,
  ) async {
    await abrir(tester);
    expect(find.textContaining('ID'), findsNothing);
    expect(find.text('Nombre del Docente *'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    // Solo los grupos del periodo elegido, con asignatura y número.
    expect(find.text('Cálculo I · Grupo 01'), findsOneWidget);
    expect(find.text('Física I · Grupo 07'), findsNothing);
  });

  testWidgets('envía docentes y aula elegidos sin docenteNombre', (
    tester,
  ) async {
    await abrir(tester);
    await elegir(tester, 'Docente principal *', 'Ana Pérez');
    await elegir(tester, 'Co-docente (opcional, US-ACA-08)', 'Bruno Díaz');
    await elegir(tester, 'Aula *', 'A-101 · Aula 101');

    // Solo aulas de la sede del periodo.
    expect(espacios.sedesPedidas, ['sede-norte']);
    expect(usuarios.consultas.every((c) => c.rol == 'DOCENTE'), isTrue);

    await tester.tap(find.text('Guardar Asignación'));
    await tester.pumpAndSettle();

    final cuerpo = repo.cuerpos.single;
    expect(cuerpo['periodoId'], 'per-1');
    expect(cuerpo['grupoId'], 'g-1');
    expect(cuerpo['asignaturaId'], 'as-1');
    expect(cuerpo['docenteIds'], ['doc-1', 'doc-2']);
    expect(cuerpo['espacioId'], 'esp-1');
    expect(cuerpo.containsKey('docenteNombre'), isFalse);
    expect(cuerpo.containsKey('espacioNombre'), isFalse);
    expect(cuerpo['franja'], {
      'diaSemana': 1,
      'horaInicio': '08:00',
      'horaFin': '10:00',
      'zonaHoraria': 'America/Bogota',
    });
  });

  testWidgets('exige docente y aula, y rechaza co-docente repetido', (
    tester,
  ) async {
    await abrir(tester);
    await tester.tap(find.text('Guardar Asignación'));
    await tester.pumpAndSettle();
    expect(find.text('Requerido'), findsNWidgets(2));

    await elegir(tester, 'Docente principal *', 'Ana Pérez');
    await elegir(tester, 'Co-docente (opcional, US-ACA-08)', 'Ana Pérez');
    await elegir(tester, 'Aula *', 'A-101 · Aula 101');
    await tester.tap(find.text('Guardar Asignación'));
    await tester.pumpAndSettle();

    expect(
      find.text('Debe ser distinto del docente principal'),
      findsOneWidget,
    );
    expect(repo.cuerpos, isEmpty);
  });

  testWidgets('modalidad virtual oculta el aula y no la envía', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Presencial'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Virtual').last);
    await tester.pumpAndSettle();
    expect(_selector('Aula *'), findsNothing);

    await elegir(tester, 'Docente principal *', 'Bruno Díaz');
    await tester.tap(find.text('Guardar Asignación'));
    await tester.pumpAndSettle();

    final cuerpo = repo.cuerpos.single;
    expect(cuerpo['modalidad'], 'VIRTUAL');
    expect(cuerpo.containsKey('espacioId'), isFalse);
    expect(cuerpo['docenteIds'], ['doc-2']);
  });

  testWidgets('valida que la hora de fin sea posterior a la de inicio', (
    tester,
  ) async {
    await abrir(tester);
    await elegir(tester, 'Docente principal *', 'Ana Pérez');
    await elegir(tester, 'Aula *', 'A-101 · Aula 101');
    await elegirHora(tester, 'Fin', '07:30');
    expect(find.text('7:30 a. m.'), findsOneWidget);

    await tester.tap(find.text('Guardar Asignación'));
    await tester.pumpAndSettle();
    expect(
      find.text('La hora de fin debe ser posterior a la de inicio'),
      findsOneWidget,
    );
    expect(repo.cuerpos, isEmpty);

    await elegirHora(tester, 'Fin', '11:15');
    await tester.tap(find.text('Guardar Asignación'));
    await tester.pumpAndSettle();
    expect((repo.cuerpos.single['franja'] as Map)['horaFin'], '11:15');
  });

  testWidgets('6:30 p. m. se envía como 18:30 (24 h, hora de Bogotá)', (
    tester,
  ) async {
    await abrir(tester);
    await elegir(tester, 'Docente principal *', 'Ana Pérez');
    await elegir(tester, 'Aula *', 'A-101 · Aula 101');
    await elegirHora(tester, 'Fin', '07:30', pm: true);
    await elegirHora(tester, 'Inicio', '06:30', pm: true);
    expect(find.text('6:30 p. m.'), findsOneWidget);
    expect(find.text('7:30 p. m.'), findsOneWidget);

    await tester.tap(find.text('Guardar Asignación'));
    await tester.pumpAndSettle();
    final franja = repo.cuerpos.single['franja'] as Map;
    expect(franja['horaInicio'], '18:30');
    expect(franja['horaFin'], '19:30');
  });

  testWidgets('cambiar de periodo filtra grupos y reinicia el aula', (
    tester,
  ) async {
    await abrir(tester);
    await elegir(tester, 'Aula *', 'A-101 · Aula 101');
    await tester.tap(find.text('2026-1 - Primer semestre'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2026-2 - Segundo semestre').last);
    await tester.pumpAndSettle();

    expect(find.text('Física I · Grupo 07'), findsOneWidget);
    expect(find.text('A-101 · Aula 101'), findsNothing);

    // Periodo sin sede: se listan todas las aulas visibles.
    await tester.tap(_selector('Aula *'));
    await tester.pumpAndSettle();
    expect(espacios.sedesPedidas.last, isNull);
    expect(find.text('S-900 · Aula Sur'), findsOneWidget);
  });

  testWidgets(
    'un cruce de horario se explica en un modal y no cierra el formulario',
    (tester) async {
      repo.rechazo = _choqueDocente;
      await abrir(tester);
      await elegir(tester, 'Docente principal *', 'Ana Pérez');
      await elegir(tester, 'Aula *', 'A-101 · Aula 101');
      await tester.tap(find.text('Guardar Asignación'));
      await tester.pumpAndSettle();

      expect(find.text('El docente ya tiene clase a esa hora'), findsOneWidget);
      expect(find.text('Clase que ya ocupa ese horario'), findsOneWidget);
      expect(find.text('Miércoles, 6:30 p. m. a 7:30 p. m.'), findsOneWidget);
      expect(find.textContaining('doc-1'), findsNothing);

      await tester.tap(find.text('Revisar el formulario'));
      await tester.pumpAndSettle();

      // El formulario sigue abierto con lo elegido, listo para corregir.
      expect(find.text('Guardar Asignación'), findsOneWidget);
      expect(find.text('Ana Pérez'), findsOneWidget);
      expect(find.text('El docente ya tiene clase a esa hora'), findsNothing);
    },
  );
}
