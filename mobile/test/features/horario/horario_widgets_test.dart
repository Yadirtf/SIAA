// horario_widgets_test.dart - Pruebas unitarias y de widgets para Mi Horario (US-ACA-01..09)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/horario/data/models/sesion_horario_model.dart';
import 'package:siaa_mobile/features/horario/domain/repositories/horario_repository.dart';
import 'package:siaa_mobile/features/horario/presentation/bloc/horario_bloc.dart';
import 'package:siaa_mobile/features/horario/presentation/bloc/horario_event.dart';
import 'package:siaa_mobile/features/horario/presentation/bloc/horario_state.dart';
import 'package:siaa_mobile/features/horario/presentation/widgets/dias_selector.dart';
import 'package:siaa_mobile/features/horario/presentation/widgets/horario_card.dart';

class MockHorarioRepository implements HorarioRepository {
  final List<SesionHorarioModel> sesionesRetorno;
  MockHorarioRepository(this.sesionesRetorno);

  @override
  Future<List<SesionHorarioModel>> obtenerHorario({String? docenteId, DateTime? fecha}) async {
    return sesionesRetorno;
  }
}

void main() {
  group('SesionHorarioModel', () {
    test('deserializa correctamente desde JSON', () {
      final json = {
        'id': 'ses-101',
        'asignatura': 'Programación II',
        'grupo': 'G2',
        'espacioCodigo': 'Lab 204',
        'fecha': '2026-09-25T08:00:00Z',
        'horaInicio': '08:00',
        'horaFin': '10:00',
        'estado': 'PROGRAMADA',
        'docenteIds': ['doc-1'],
      };

      final model = SesionHorarioModel.fromJson(json);
      expect(model.id, equals('ses-101'));
      expect(model.asignatura, equals('Programación II'));
      expect(model.grupo, equals('G2'));
      expect(model.espacio, equals('Lab 204'));
      expect(model.horaInicio, equals('08:00'));
      expect(model.horaFin, equals('10:00'));
      expect(model.esProgramada, isTrue);
      expect(model.esCancelada, isFalse);
    });

    test('reconoce sesión cancelada con motivo', () {
      final json = {
        'id': 'ses-102',
        'asignatura': 'Cálculo I',
        'grupo': 'G1',
        'espacioId': 'Aula 101',
        'inicioProgramado': '2026-09-25T10:00:00Z',
        'finProgramado': '2026-09-25T12:00:00Z',
        'estado': 'CANCELADA',
        'motivoCancelacion': 'Día festivo nacional',
      };

      final model = SesionHorarioModel.fromJson(json);
      expect(model.esCancelada, isTrue);
      expect(model.motivoCancelacion, equals('Día festivo nacional'));
    });
  });

  group('HorarioCard Widget', () {
    testWidgets('renderiza datos de la clase programada', (tester) async {
      final sesion = SesionHorarioModel(
        id: 's-1',
        asignatura: 'Bases de Datos',
        grupo: 'A',
        espacio: 'Aula 301',
        fecha: DateTime(2026, 9, 25),
        horaInicio: '08:00',
        horaFin: '10:00',
        estado: 'PROGRAMADA',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorarioCard(sesion: sesion),
          ),
        ),
      );

      expect(find.text('Bases de Datos'), findsOneWidget);
      expect(find.text('08:00 - 10:00'), findsOneWidget);
      expect(find.text('Grupo A'), findsOneWidget);
      expect(find.text('Aula 301'), findsOneWidget);
      expect(find.text('PROGRAMADA'), findsOneWidget);
    });

    testWidgets('renderiza sesión cancelada y su motivo', (tester) async {
      final sesion = SesionHorarioModel(
        id: 's-2',
        asignatura: 'Física I',
        grupo: 'B',
        espacio: 'Aula 102',
        fecha: DateTime(2026, 9, 25),
        horaInicio: '14:00',
        horaFin: '16:00',
        estado: 'CANCELADA',
        motivoCancelacion: 'Reparación de red eléctrica',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorarioCard(sesion: sesion),
          ),
        ),
      );

      expect(find.text('Física I'), findsOneWidget);
      expect(find.text('CANCELADA'), findsOneWidget);
      expect(find.text('Motivo: Reparación de red eléctrica'), findsOneWidget);
    });
  });

  group('DiasSelector Widget', () {
    testWidgets('renderiza días de la semana y responde a selección', (tester) async {
      DateTime seleccionado = DateTime(2026, 9, 25); // Viernes
      DateTime? clickeado;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiasSelector(
              fechaSeleccionada: seleccionado,
              onDiaSeleccionado: (d) => clickeado = d,
            ),
          ),
        ),
      );

      expect(find.text('Lun'), findsOneWidget);
      expect(find.text('Mar'), findsOneWidget);
      expect(find.text('Vie'), findsOneWidget);

      await tester.tap(find.text('Lun'));
      await tester.pump();

      expect(clickeado, isNotNull);
      expect(clickeado!.weekday, equals(DateTime.monday));
    });
  });

  group('HorarioBloc', () {
    test('emite HorarioLoading y luego HorarioLoaded al cargar horario', () async {
      final dummy = [
        SesionHorarioModel(
          id: 's-1',
          asignatura: 'Arquitectura',
          grupo: 'G1',
          espacio: 'Lab 1',
          fecha: DateTime.now(),
          horaInicio: '07:00',
          horaFin: '09:00',
          estado: 'PROGRAMADA',
        )
      ];

      final repo = MockHorarioRepository(dummy);
      final bloc = HorarioBloc(repository: repo);

      expect(bloc.state, isA<HorarioInitial>());

      bloc.add(const CargarHorarioEvent());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<HorarioLoading>(),
          isA<HorarioLoaded>().having((s) => s.sesiones.length, 'sesiones', 1),
        ]),
      );

      await bloc.close();
    });
  });
}
