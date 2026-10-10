// marcaje_salida_test.dart — Botón, BLoC y permanencia del marcaje de salida (US-MAR-15)
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/marcaje/data/repositories/marcaje_repository.dart';
import 'package:siaa_mobile/features/marcaje/data/services/location_service.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_result_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_bloc.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_event.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_state.dart';
import 'package:siaa_mobile/features/marcaje/presentation/helpers/accion_marcaje.dart';
import 'package:siaa_mobile/features/marcaje/presentation/widgets/marcaje_accion_panel.dart';

class _MockRepo extends Mock implements MarcajeRepository {}

final _loc = LocationResult(
  latitud: 4.6,
  longitud: -74.06,
  precisionMetros: 8,
  timestamp: DateTime(2026, 9, 25, 9),
  isMocked: false,
);

SesionActivaModel _sesion({
  String tipo = 'ENTRADA',
  bool entrada = true,
  bool salida = false,
  String? modo = 'OPCIONAL',
  int? permanencia,
}) =>
    SesionActivaModel(
      id: 'ses-1',
      asignatura: 'Redes',
      grupo: 'G1',
      espacio: const EspacioInfo(id: 'e', codigo: 'A-1', nombre: 'Aula 1'),
      inicioProgramado: DateTime(2026, 9, 25, 7),
      finProgramado: DateTime(2026, 9, 25, 9),
      modalidad: 'PRESENCIAL',
      ventana: VentanaInfo(
        abreEn: DateTime(2026, 9, 25, 8, 45),
        cierraEn: DateTime(2026, 9, 25, 9, 15),
        estado: 'ABIERTA',
        tipo: tipo,
      ),
      tieneMarcajeEntrada: entrada,
      tieneMarcajeSalida: salida,
      modoMarcajeSalida: modo,
      permanenciaSalidaMin: permanencia,
    );

Future<void> _pump(WidgetTester tester, MarcajeState state,
    {ValueChanged<String>? onMarcar}) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: MarcajeAccionPanel(state: state, onMarcar: onMarcar ?? (_) {}),
      ),
    ),
  ));
}

void main() {
  setUpAll(() => registerFallbackValue(_loc));

  group('AccionMarcaje y formato de permanencia', () {
    test('la etiqueta depende de la ventana, no solo de la entrada', () {
      expect(AccionMarcaje.de(_sesion(entrada: false)).label, 'MARCAR ENTRADA');
      expect(AccionMarcaje.de(_sesion()).label, 'ENTRADA REGISTRADA');
      final salida = AccionMarcaje.de(_sesion(tipo: 'SALIDA'));
      expect(salida.label, 'MARCAR SALIDA');
      expect(salida.tipo, 'SALIDA');
      expect(AccionMarcaje.de(_sesion(tipo: 'SALIDA', salida: true)).label,
          'SALIDA REGISTRADA');
      expect(
          AccionMarcaje.de(_sesion(tipo: 'SALIDA', modo: 'DESACTIVADO')).label,
          'SALIDA DESACTIVADA');
    });

    test('formatea la permanencia en horas y minutos', () {
      expect(formatearPermanencia(95), '1 h 35 min');
      expect(formatearPermanencia(40), '40 min');
      expect(formatearPermanencia(120), '2 h');
    });
  });

  group('MarcajeAccionPanel', () {
    testWidgets('en ventana de entrada ya marcada el botón queda deshabilitado',
        (tester) async {
      var toques = 0;
      await _pump(
        tester,
        MarcajeState(sesionActiva: _sesion(), semaforo: SemaforoMarcaje.listo),
        onMarcar: (_) => toques++,
      );
      expect(find.text('ENTRADA REGISTRADA'), findsOneWidget);
      expect(find.text('MARCAR SALIDA'), findsNothing);
      await tester.tap(find.text('ENTRADA REGISTRADA'));
      expect(toques, 0);
    });

    testWidgets('en ventana de salida envía tipo SALIDA', (tester) async {
      String? tipo;
      await _pump(
        tester,
        MarcajeState(
            sesionActiva: _sesion(tipo: 'SALIDA'),
            semaforo: SemaforoMarcaje.listo),
        onMarcar: (t) => tipo = t,
      );
      await tester.tap(find.text('MARCAR SALIDA'));
      expect(tipo, 'SALIDA');
    });

    testWidgets('muestra la permanencia de la salida aceptada', (tester) async {
      await _pump(
        tester,
        MarcajeState(
          sesionActiva: _sesion(tipo: 'SALIDA'),
          semaforo: SemaforoMarcaje.registrado,
          ultimoResultado: const MarcajeResultModel(
              resultado: 'VALIDO', mensaje: 'ok', permanenciaMin: 95),
        ),
      );
      expect(find.text('Permanencia: 1 h 35 min'), findsOneWidget);
    });

    testWidgets('con salida desactivada no ofrece marcar salida (AC-03)',
        (tester) async {
      await _pump(
        tester,
        MarcajeState(
            sesionActiva: _sesion(tipo: 'SALIDA', modo: 'DESACTIVADO'),
            semaforo: SemaforoMarcaje.listo),
      );
      expect(find.text('MARCAR SALIDA'), findsNothing);
      expect(find.text('SALIDA DESACTIVADA'), findsOneWidget);
    });
  });

  group('MarcajeBloc en ventana de salida', () {
    late _MockRepo repo;
    setUp(() {
      repo = _MockRepo();
      when(() => repo.obtenerColaOffline()).thenAnswer((_) async => []);
      when(() => repo.capturarUbicacion()).thenAnswer((_) async => _loc);
    });

    blocTest<MarcajeBloc, MarcajeState>(
      'con entrada registrada y ventana de salida abierta captura GPS',
      build: () {
        when(() => repo.obtenerSesionActiva())
            .thenAnswer((_) async => _sesion(tipo: 'SALIDA'));
        return MarcajeBloc(
            repository: repo, consentimientoOtorgado: () => true);
      },
      act: (b) => b.add(const CargarSesionActivaEvent()),
      skip: 3,
      expect: () => [
        isA<MarcajeState>()
            .having((s) => s.semaforo, 'semaforo', SemaforoMarcaje.listo)
            .having((s) => s.puedeMarcar, 'puedeMarcar', true),
      ],
    );

    blocTest<MarcajeBloc, MarcajeState>(
      'en ventana de entrada ya marcada no captura GPS ni permite marcar',
      build: () {
        when(() => repo.obtenerSesionActiva())
            .thenAnswer((_) async => _sesion());
        return MarcajeBloc(
            repository: repo, consentimientoOtorgado: () => true);
      },
      act: (b) => b.add(const CargarSesionActivaEvent()),
      expect: () => [
        isA<MarcajeState>().having((s) => s.isLoading, 'loading', true),
        isA<MarcajeState>()
            .having((s) => s.semaforo, 'semaforo', SemaforoMarcaje.registrado)
            .having((s) => s.puedeMarcar, 'puedeMarcar', false),
      ],
      verify: (_) => verifyNever(() => repo.capturarUbicacion()),
    );

    blocTest<MarcajeBloc, MarcajeState>(
      'salida aceptada sin permanencia recarga la sesión para obtenerla',
      build: () {
        when(() => repo.realizarMarcaje(
                  sesionId: any(named: 'sesionId'),
                  tipo: any(named: 'tipo'),
                  location: any(named: 'location'),
                  verificacion: any(named: 'verificacion'),
                  exigirAttestation: any(named: 'exigirAttestation'),
                ))
            .thenAnswer((_) async =>
                const MarcajeResultModel(resultado: 'VALIDO', mensaje: 'ok'));
        when(() => repo.obtenerSesionActiva()).thenAnswer((_) async =>
            _sesion(tipo: 'SALIDA', salida: true, permanencia: 95));
        return MarcajeBloc(
            repository: repo, consentimientoOtorgado: () => true);
      },
      seed: () => MarcajeState(
        sesionActiva: _sesion(tipo: 'SALIDA'),
        location: _loc,
        semaforo: SemaforoMarcaje.listo,
      ),
      act: (b) => b.add(const RealizarMarcajeEvent(tipo: 'SALIDA')),
      verify: (b) {
        verify(() => repo.realizarMarcaje(
              sesionId: 'ses-1',
              tipo: 'SALIDA',
              location: any(named: 'location'),
              verificacion: any(named: 'verificacion'),
              exigirAttestation: any(named: 'exigirAttestation'),
            )).called(1);
        expect(MarcajeAccionPanel.permanenciaDe(b.state), 95);
        expect(b.state.puedeMarcar, isFalse);
      },
    );
  });
}
