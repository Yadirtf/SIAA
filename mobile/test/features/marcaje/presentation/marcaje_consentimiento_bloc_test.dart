// marcaje_consentimiento_bloc_test.dart — Marcaje deshabilitado sin consentimiento (US-LEG-01 AC-05)
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/marcaje/data/repositories/marcaje_repository.dart';
import 'package:siaa_mobile/features/marcaje/data/services/location_service.dart';
import 'package:siaa_mobile/features/marcaje/domain/models/sesion_activa_model.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_bloc.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_event.dart';
import 'package:siaa_mobile/features/marcaje/presentation/bloc/marcaje_state.dart';
import 'package:siaa_mobile/features/privacidad/data/consentimiento_requerido.dart';

class MockMarcajeRepository extends Mock implements MarcajeRepository {}

void main() {
  late MockMarcajeRepository repo;
  final ubicacion = LocationResult(
    latitud: 4.6,
    longitud: -74.0,
    precisionMetros: 5,
    timestamp: DateTime.now(),
    isMocked: false,
  );
  final sesion = SesionActivaModel(
    id: 'ses-1',
    asignatura: 'Redes',
    grupo: 'G1',
    espacio: const EspacioInfo(id: 'e', codigo: 'A-1', nombre: 'Aula 1'),
    inicioProgramado: DateTime(2026, 9, 25, 8),
    finProgramado: DateTime(2026, 9, 25, 10),
    modalidad: 'PRESENCIAL',
    ventana: VentanaInfo(
      abreEn: DateTime(2026, 9, 25, 7, 45),
      cierraEn: DateTime(2026, 9, 25, 8, 15),
      estado: 'ABIERTA',
    ),
    tieneMarcajeEntrada: false,
  );

  setUpAll(() => registerFallbackValue(ubicacion));
  setUp(() => repo = MockMarcajeRepository());

  blocTest<MarcajeBloc, MarcajeState>(
    'sin consentimiento carga la sesión pero no captura GPS',
    build: () {
      when(() => repo.obtenerSesionActiva()).thenAnswer((_) async => sesion);
      when(() => repo.obtenerColaOffline()).thenAnswer((_) async => []);
      return MarcajeBloc(repository: repo, consentimientoOtorgado: () => false);
    },
    act: (b) => b.add(const CargarSesionActivaEvent()),
    wait: const Duration(milliseconds: 50),
    verify: (b) {
      expect(b.state.consentimientoRequerido, isTrue);
      expect(b.state.puedeMarcar, isFalse);
      verifyNever(() => repo.capturarUbicacion());
    },
  );

  blocTest<MarcajeBloc, MarcajeState>(
    '403 CONSENTIMIENTO_REQUERIDO en línea pide el aviso y no encola',
    build: () {
      when(() => repo.realizarMarcaje(
            sesionId: any(named: 'sesionId'),
            tipo: any(named: 'tipo'),
            location: any(named: 'location'),
            verificacion: any(named: 'verificacion'),
            exigirAttestation: any(named: 'exigirAttestation'),
          )).thenThrow(const ConsentimientoRequeridoException('Acepte'));
      return MarcajeBloc(repository: repo, consentimientoOtorgado: () => true);
    },
    seed: () => MarcajeState(
      sesionActiva: sesion,
      location: ubicacion,
      semaforo: SemaforoMarcaje.listo,
    ),
    act: (b) => b.add(const RealizarMarcajeEvent()),
    expect: () => [
      isA<MarcajeState>().having((s) => s.isSubmitting, 'enviando', true),
      isA<MarcajeState>()
          .having((s) => s.isSubmitting, 'enviando', false)
          .having((s) => s.consentimientoRequerido, 'requerido', true)
          .having((s) => s.rechazosPorConsentimiento, 'rechazos', 1)
          .having((s) => s.error, 'error', 'Acepte'),
    ],
    verify: (_) => verifyNever(() => repo.obtenerColaOffline()),
  );
}
