// marcaje_grupal_widgets_test.dart — Pantallas del docente (US-MAR-13/14) y aviso al
// estudiante cuando la ventana no está abierta.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';
import 'package:siaa_mobile/features/marcaje/presentation/screens/lista_manual_screen.dart';
import 'package:siaa_mobile/features/marcaje/presentation/screens/marcaje_grupal_screen.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/sesion_card.dart';

import 'fakes_grupal.dart';

SesionActivaModel _sesionEstudiante(String estado, {int minutos = 0}) {
  final ahora = DateTime.now().toUtc();
  return SesionActivaModel.fromDetalleJson({
    'sesion': {
      'id': 's1',
      'asignatura': 'Física',
      'grupo': 'B2',
      'espacio': {'codigo': 'A-101', 'nombre': 'Laboratorio'},
      'inicioProgramado': ahora.add(const Duration(hours: 1)).toIso8601String(),
      'finProgramado': ahora.add(const Duration(hours: 2)).toIso8601String(),
    },
    'ventana': {
      'estado': estado,
      'abreEn': ahora.add(const Duration(minutes: 30)).toIso8601String(),
      'cierraEn': ahora.add(const Duration(minutes: 45)).toIso8601String(),
      'minutosParaAbrir': minutos,
    },
  });
}

void main() {
  testWidgets('el docente elige duración, abre y cierra el marcaje',
      (tester) async {
    final remote = GrupalRemoteFake();
    await tester.pumpWidget(MaterialApp(
      home: MarcajeGrupalScreen(
        grupal: remote,
        cargarSesion: () async => sesionDocente(),
      ),
    ));
    await tester.pump();
    expect(find.text('Cálculo I'), findsOneWidget);
    expect(find.text('Abrir marcaje (5 min)'), findsOneWidget);

    await tester.tap(find.text('10 min'));
    await tester.pump();
    await tester.tap(find.text('Abrir marcaje (10 min)'));
    await tester.pump();
    expect(remote.duracionPedida, 10);
    expect(find.textContaining('Cierra en'), findsOneWidget);
    expect(find.textContaining('pueden marcar hasta las'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Cerrar marcaje ahora'));
    await tester.pump();
    expect(remote.cierres, 1);
    expect(find.text('Abrir marcaje (10 min)'), findsOneWidget);
  });

  testWidgets('muestra el mensaje del servidor si no se puede abrir',
      (tester) async {
    final remote = GrupalRemoteFake()
      ..errorAbrir = errorApi(409, 'La clase ya terminó.');
    await tester.pumpWidget(MaterialApp(
      home: MarcajeGrupalScreen(
        grupal: remote,
        cargarSesion: () async => sesionDocente(),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('Abrir marcaje (5 min)'));
    await tester.pump();
    expect(find.text('La clase ya terminó.'), findsOneWidget);
  });

  testWidgets('sin clase en curso lo explica', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MarcajeGrupalScreen(
        grupal: GrupalRemoteFake(),
        cargarSesion: () async => null,
      ),
    ));
    await tester.pump();
    expect(find.text('No tienes una clase en curso en este momento.'),
        findsOneWidget);
  });

  testWidgets('lista manual: bloqueados fijos, motivo obligatorio y resumen',
      (tester) async {
    final remote = GrupalRemoteFake()..estudiantes = estudiantesGrupo;
    await tester.pumpWidget(MaterialApp(
      home: ListaManualScreen(sesionId: 'ses-1', remote: remote),
    ));
    await tester.pump();
    expect(find.text('Laura Pérez'), findsOneWidget);
    expect(find.text('Ya marcó con la app'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(find.byType(Switch), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('1 de 1 presentes por marcar'), findsOneWidget);

    await tester.tap(find.text('Guardar lista'));
    await tester.pump();
    expect(
        find.text('Cuéntanos por qué tomas la lista a mano.'), findsOneWidget);
    expect(remote.motivoEnviado, isNull);

    await tester.enterText(
        find.byKey(const Key('motivoListaManual')), 'Sin señal en el aula');
    await tester.tap(find.text('Guardar lista'));
    await tester.pump();
    expect(remote.presentesEnviados, {'est-1': true, 'est-2': true});
    expect(find.text('Lista manual registrada y auditada'), findsOneWidget);
    expect(find.text('Conservaron su registro anterior'), findsOneWidget);
    expect(find.text('No pertenecen al grupo (no se registraron)'),
        findsOneWidget);
  });

  testWidgets('estudiante sin ventana abierta ve un aviso, no una cuenta',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SesionCard(
          sesion: _sesionEstudiante('NO_ABIERTA', minutos: 30),
          esEstudiante: true,
        ),
      ),
    ));
    expect(find.text('Tu docente aún no habilita el marcaje'), findsOneWidget);
    expect(find.textContaining('Abre en'), findsNothing);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SesionCard(
          sesion: _sesionEstudiante('CERRADA'),
          esEstudiante: true,
        ),
      ),
    ));
    expect(find.text('El marcaje para estudiantes ya cerró'), findsOneWidget);
    expect(find.text('Marcaje cerrado'), findsOneWidget);
  });
}
