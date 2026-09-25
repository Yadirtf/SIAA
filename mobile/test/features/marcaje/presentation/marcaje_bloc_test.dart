// marcaje_bloc_test.dart — Pruebas unitarias de BLoC de marcaje (US-MAR-01, US-MAR-05, US-MAR-11)
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/marcaje/data/repositories/marcaje_repository.dart';
import 'package:siaa_mobile/features/marcaje/data/services/location_service.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/marcaje_result_model.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_bloc.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_event.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_state.dart';

class MockMarcajeRepository extends Mock implements MarcajeRepository {}

void main() {
  late MockMarcajeRepository mockRepo;

  final dummyLocationOptima = LocationResult(
    latitud: 4.601,
    longitud: -74.066,
    precisionMetros: 8.5,
    timestamp: DateTime.now(),
    isMocked: false,
  );

  setUpAll(() {
    registerFallbackValue(dummyLocationOptima);
  });

  setUp(() {
    mockRepo = MockMarcajeRepository();
  });

  final dummySesion = SesionActivaModel(
    id: 'ses-1',
    asignatura: 'Bases de Datos',
    grupo: 'G1',
    espacio: const EspacioInfo(id: 'esp-1', codigo: 'LAB-201', nombre: 'Lab 201'),
    inicioProgramado: DateTime(2026, 9, 25, 8, 0),
    finProgramado: DateTime(2026, 9, 25, 10, 0),
    modalidad: 'PRESENCIAL',
    ventana: VentanaInfo(
      abreEn: DateTime(2026, 9, 25, 7, 45),
      cierraEn: DateTime(2026, 9, 25, 8, 15),
      estado: 'ABIERTA',
    ),
    tieneMarcajeEntrada: false,
  );

  blocTest<MarcajeBloc, MarcajeState>(
    'CargarSesionActivaEvent emite loading y luego sesionActiva con semáforo listo',
    build: () {
      when(() => mockRepo.obtenerSesionActiva()).thenAnswer((_) async => dummySesion);
      when(() => mockRepo.obtenerColaOffline()).thenAnswer((_) async => []);
      when(() => mockRepo.capturarUbicacion()).thenAnswer((_) async => dummyLocationOptima);
      return MarcajeBloc(repository: mockRepo);
    },
    act: (bloc) => bloc.add(const CargarSesionActivaEvent()),
    expect: () => [
      const MarcajeState(isLoading: true),
      isA<MarcajeState>()
          .having((s) => s.sesionActiva?.id, 'sesion id', 'ses-1')
          .having((s) => s.semaforo, 'semaforo', SemaforoMarcaje.buscandoGps),
      isA<MarcajeState>()
          .having((s) => s.isCapturingGps, 'isCapturing', true)
          .having((s) => s.semaforo, 'semaforo', SemaforoMarcaje.buscandoGps),
      isA<MarcajeState>()
          .having((s) => s.location?.precisionMetros, 'precision', 8.5)
          .having((s) => s.semaforo, 'semaforo', SemaforoMarcaje.listo),
    ],
  );

  blocTest<MarcajeBloc, MarcajeState>(
    'RealizarMarcajeEvent procesa envío y actualiza semáforo a registrado ante respuesta ACEPTADO',
    build: () {
      when(() => mockRepo.capturarUbicacion()).thenAnswer((_) async => dummyLocationOptima);
      when(() => mockRepo.realizarMarcaje(
            sesionId: any(named: 'sesionId'),
            tipo: any(named: 'tipo'),
            location: any(named: 'location'),
          )).thenAnswer((_) async => const MarcajeResultModel(
            marcajeId: 'mar-success',
            resultado: 'ACEPTADO',
            mensaje: 'Marcaje verificado y aceptado',
          ));
      when(() => mockRepo.obtenerColaOffline()).thenAnswer((_) async => []);
      return MarcajeBloc(repository: mockRepo);
    },
    seed: () => MarcajeState(
      sesionActiva: dummySesion,
      location: dummyLocationOptima,
      semaforo: SemaforoMarcaje.listo,
    ),
    act: (bloc) => bloc.add(const RealizarMarcajeEvent(tipo: 'ENTRADA')),
    expect: () => [
      isA<MarcajeState>().having((s) => s.isSubmitting, 'submitting', true),
      isA<MarcajeState>()
          .having((s) => s.isSubmitting, 'submitting', false)
          .having((s) => s.ultimoResultado?.esAceptado, 'esAceptado', true)
          .having((s) => s.semaforo, 'semaforo', SemaforoMarcaje.registrado),
    ],
  );

  blocTest<MarcajeBloc, MarcajeState>(
    'RealizarMarcajeEvent actualiza a fueraDeAula ante rechazo por polígono',
    build: () {
      when(() => mockRepo.capturarUbicacion()).thenAnswer((_) async => dummyLocationOptima);
      when(() => mockRepo.realizarMarcaje(
            sesionId: any(named: 'sesionId'),
            tipo: any(named: 'tipo'),
            location: any(named: 'location'),
          )).thenAnswer((_) async => const MarcajeResultModel(
            marcajeId: 'mar-rej',
            resultado: 'RECHAZADO',
            motivoRechazo: 'FUERA_DE_POLIGONO',
            distanciaMetros: 50.0,
            mensaje: 'Fuera del perímetro del aula',
          ));
      when(() => mockRepo.obtenerColaOffline()).thenAnswer((_) async => []);
      return MarcajeBloc(repository: mockRepo);
    },
    seed: () => MarcajeState(
      sesionActiva: dummySesion,
      location: dummyLocationOptima,
      semaforo: SemaforoMarcaje.listo,
    ),
    act: (bloc) => bloc.add(const RealizarMarcajeEvent(tipo: 'ENTRADA')),
    expect: () => [
      isA<MarcajeState>().having((s) => s.isSubmitting, 'submitting', true),
      isA<MarcajeState>()
          .having((s) => s.isSubmitting, 'submitting', false)
          .having((s) => s.ultimoResultado?.esRechazado, 'esRechazado', true)
          .having((s) => s.semaforo, 'semaforo', SemaforoMarcaje.fueraDeAula),
    ],
  );
}
