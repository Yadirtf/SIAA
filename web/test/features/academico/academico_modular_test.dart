import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/academico/data/academico_models.dart';
import 'package:siaa_web/features/academico/presentation/widgets/views/asignaciones_list_view.dart';
import 'package:siaa_web/features/academico/presentation/widgets/views/estructura_breadcrumbs.dart';
import 'package:siaa_web/features/academico/presentation/widgets/views/estructura_header.dart';

void main() {
  group('Piezas del Rompecabezas Web Académico (Sprint 4)', () {
    testWidgets('EstructuraHeader: renderiza título y selector con nivel activo', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EstructuraHeader(
              activeLevel: 0,
              onCrearElemento: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Estructura Académica'), findsOneWidget);
      expect(find.text('Nueva Facultad'), findsOneWidget);
    });

    testWidgets('EstructuraBreadcrumbs: renderiza jerarquía y chips de navegación', (tester) async {
      final facultad = FacultadModel(id: 'f1', codigo: 'ING', nombre: 'Ingeniería');
      final programa = ProgramaModel(id: 'p1', codigo: 'SIS', nombre: 'Sistemas', facultadId: 'f1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EstructuraBreadcrumbs(
              activeLevel: 2,
              selectedFacultad: facultad,
              selectedPrograma: programa,
              selectedAsignatura: null,
              onSelectLevel: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('1. Facultades'), findsOneWidget);
      expect(find.text('2. Ingeniería'), findsOneWidget);
      expect(find.text('3. Sistemas'), findsOneWidget);
    });

    testWidgets('AsignacionesListView: renderiza asignación docente y modalidad', (tester) async {
      final asignaciones = [
        AsignacionModel(
          id: 'asig-1',
          periodoId: 'per-1',
          docenteIds: const ['doc-1'],
          docenteNombre: 'Profesor Juan Pérez',
          grupoId: 'grp-1',
          asignaturaId: 'asig-1',
          facultadId: 'fac-1',
          espacioId: 'aula-101',
          espacioNombre: 'Aula 101',
          franja: const FranjaModel(
            diaSemana: 1,
            horaInicio: '08:00',
            horaFin: '10:00',
            zonaHoraria: 'America/Bogota',
          ),
          modalidad: 'PRESENCIAL',
          exentaGeoespacial: false,
          estado: 'ACTIVA',
          fechaInicio: '2026-08-01',
          fechaFin: '2026-12-15',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AsignacionesListView(
              asignaciones: asignaciones,
            ),
          ),
        ),
      );

      expect(find.textContaining('Profesor Juan Pérez'), findsOneWidget);
      expect(find.textContaining('Aula 101'), findsOneWidget);
      expect(find.textContaining('08:00 - 10:00'), findsOneWidget);
      expect(find.text('PRESENCIAL'), findsOneWidget);
    });
  });
}
