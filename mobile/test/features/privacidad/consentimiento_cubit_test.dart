// consentimiento_cubit_test.dart — Flujo del aviso y decisión explícita (US-LEG-01, CA-011)
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:siaa_mobile/features/privacidad/data/consentimiento_gate.dart';
import 'package:siaa_mobile/features/privacidad/data/privacidad_remote_datasource.dart';
import 'package:siaa_mobile/features/privacidad/domain/models/estado_consentimiento.dart';
import 'package:siaa_mobile/features/privacidad/domain/models/politica_privacidad.dart';
import 'package:siaa_mobile/features/privacidad/presentation/cubit/consentimiento_cubit.dart';
import 'package:siaa_mobile/features/privacidad/presentation/cubit/consentimiento_state.dart';

class MockRemote extends Mock implements PrivacidadRemoteDataSource {}

const politica = PoliticaPrivacidad(
  version: '1.0',
  contenido: '# Aviso',
  contacto: 'privacidad@uni.edu.co',
);

const pendiente =
    EstadoConsentimiento(versionVigente: '1.0', requiereAceptacion: true);
const aceptado = EstadoConsentimiento(
  versionVigente: '1.0',
  requiereAceptacion: false,
  decision: 'ACEPTADO',
  versionDecidida: '1.0',
);
const rechazado = EstadoConsentimiento(
  versionVigente: '1.0',
  requiereAceptacion: true,
  decision: 'RECHAZADO',
  versionDecidida: '1.0',
);

void main() {
  late MockRemote remote;
  late ConsentimientoGate gate;
  late ConsentimientoCubit cubit;

  setUp(() {
    remote = MockRemote();
    gate = ConsentimientoGate(
      leerVersion: () async => null,
      guardarVersion: (_) async {},
    );
    cubit = ConsentimientoCubit(
      remote: remote,
      gate: gate,
      instalacionId: () async => 'inst-1',
    );
    when(() => remote.obtenerPolitica()).thenAnswer((_) async => politica);
  });

  tearDown(() => cubit.close());

  test('pendiente: debe preguntar y carga el aviso con su contacto', () async {
    when(() => remote.obtenerConsentimiento())
        .thenAnswer((_) async => pendiente);
    await cubit.verificar();
    expect(cubit.state.debePreguntar, isTrue);
    expect(cubit.state.contacto, 'privacidad@uni.edu.co');
    expect(gate.estado, EstadoGateConsentimiento.pendiente);
  });

  test('aceptado: no pregunta ni pide el aviso; habilita ubicación', () async {
    when(() => remote.obtenerConsentimiento())
        .thenAnswer((_) async => aceptado);
    await cubit.verificar();
    expect(cubit.state.debePreguntar, isFalse);
    expect(gate.permiteUbicacion, isTrue);
    verifyNever(() => remote.obtenerPolitica());
  });

  test('Acepto envía POST con versión y dispositivo', () async {
    when(() => remote.obtenerConsentimiento())
        .thenAnswer((_) async => pendiente);
    when(() => remote.registrarDecision(
          version: '1.0',
          acepta: true,
          dispositivoId: 'inst-1',
        )).thenAnswer((_) async => aceptado);
    await cubit.verificar();
    expect(await cubit.decidir(acepta: true), isTrue);
    expect(cubit.state.otorgado, isTrue);
    expect(gate.permiteUbicacion, isTrue);
  });

  test('No acepto deja el marcaje deshabilitado sin volver a preguntar',
      () async {
    when(() => remote.obtenerConsentimiento())
        .thenAnswer((_) async => pendiente);
    when(() => remote.registrarDecision(
          version: '1.0',
          acepta: false,
          dispositivoId: 'inst-1',
        )).thenAnswer((_) async => rechazado);
    await cubit.verificar();
    expect(await cubit.decidir(acepta: false), isTrue);
    expect(cubit.state.rechazado, isTrue);
    expect(cubit.state.debePreguntar, isFalse);
    expect(gate.estado, EstadoGateConsentimiento.rechazado);
  });

  test('nueva versión publicada (409) recarga aviso y consentimiento',
      () async {
    const v2 = PoliticaPrivacidad(version: '2.0', contenido: 'nuevo');
    const pendienteV2 = EstadoConsentimiento(
      versionVigente: '2.0',
      requiereAceptacion: true,
      decision: 'ACEPTADO',
      versionDecidida: '1.0',
    );
    when(() => remote.obtenerConsentimiento())
        .thenAnswer((_) async => pendiente);
    await cubit.verificar();
    when(() => remote.registrarDecision(
          version: any(named: 'version'),
          acepta: any(named: 'acepta'),
          dispositivoId: any(named: 'dispositivoId'),
        )).thenThrow(const VersionPoliticaDesactualizadaException());
    when(() => remote.obtenerPolitica()).thenAnswer((_) async => v2);
    when(() => remote.obtenerConsentimiento())
        .thenAnswer((_) async => pendienteV2);

    expect(await cubit.decidir(acepta: true), isFalse);
    expect(cubit.state.politica?.version, '2.0');
    expect(cubit.state.debePreguntar, isTrue);
    expect(gate.permiteUbicacion, isFalse);
  });

  test('requerirDeNuevo (403) revoca y reconsulta', () async {
    when(() => remote.obtenerConsentimiento())
        .thenAnswer((_) async => aceptado);
    await cubit.verificar();
    when(() => remote.obtenerConsentimiento())
        .thenAnswer((_) async => pendiente);
    await cubit.requerirDeNuevo();
    expect(cubit.state.debePreguntar, isTrue);
    expect(gate.estado, EstadoGateConsentimiento.pendiente);
  });

  test('error de red conserva el estado local del gate', () async {
    await gate.aplicar(aceptado);
    when(() => remote.obtenerConsentimiento()).thenThrow(Exception('red'));
    await cubit.verificar();
    expect(cubit.state.fase, FaseConsentimiento.error);
    expect(gate.permiteUbicacion, isTrue);
  });
}
