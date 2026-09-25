import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/dispositivos/domain/dispositivos_repository.dart';
import 'package:siaa_web/features/dispositivos/domain/models/dispositivo_model.dart';
import 'package:siaa_web/features/dispositivos/presentation/bloc/dispositivos_bloc.dart';
import 'package:siaa_web/features/dispositivos/presentation/bloc/dispositivos_event.dart';
import 'package:siaa_web/features/dispositivos/presentation/bloc/dispositivos_state.dart';

class MockDispositivosRepository implements DispositivosRepository {
  List<DispositivoModel> dispositivos = [];
  bool failNext = false;
  String? lastAprobadoId;
  String? lastRevocadoId;
  String? lastRevocadoMotivo;

  @override
  Future<List<DispositivoModel>> obtenerDispositivosUsuario(
    String usuarioId,
  ) async {
    if (failNext) throw Exception('Error al conectar con el servidor');
    return dispositivos;
  }

  @override
  Future<void> aprobarDispositivo(String dispositivoId) async {
    if (failNext) throw Exception('No se pudo aprobar');
    lastAprobadoId = dispositivoId;
    dispositivos = dispositivos.map((d) {
      if (d.id == dispositivoId) {
        return DispositivoModel(
          id: d.id,
          usuarioId: d.usuarioId,
          instalacionId: d.instalacionId,
          modelo: d.modelo,
          so: d.so,
          versionApp: d.versionApp,
          confiable: true,
          pendienteAprobacion: false,
        );
      }
      return d;
    }).toList();
  }

  @override
  Future<void> revocarDispositivo(
    String dispositivoId, {
    String? motivo,
  }) async {
    if (failNext) throw Exception('No se pudo revocar');
    lastRevocadoId = dispositivoId;
    lastRevocadoMotivo = motivo;
    dispositivos = dispositivos.map((d) {
      if (d.id == dispositivoId) {
        return DispositivoModel(
          id: d.id,
          usuarioId: d.usuarioId,
          instalacionId: d.instalacionId,
          modelo: d.modelo,
          so: d.so,
          versionApp: d.versionApp,
          confiable: false,
          pendienteAprobacion: false,
          revocadoEn: DateTime.now(),
        );
      }
      return d;
    }).toList();
  }
}

void main() {
  late MockDispositivosRepository mockRepo;
  late DispositivosBloc bloc;

  setUp(() {
    mockRepo = MockDispositivosRepository();
    bloc = DispositivosBloc(repository: mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  group('DispositivosBloc (US-AUT-03)', () {
    test('estado inicial es DispositivosInitial', () {
      expect(bloc.state, isA<DispositivosInitial>());
    });

    test('CargarDispositivosEvent emite Loading y luego Loaded', () async {
      mockRepo.dispositivos = const [
        DispositivoModel(
          id: 'dev-1',
          usuarioId: 'usr-1',
          instalacionId: 'inst-1',
          modelo: 'Pixel 8',
          so: 'Android 14',
          versionApp: '1.0.0',
          confiable: true,
          pendienteAprobacion: false,
        ),
      ];

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DispositivosLoading>(),
          isA<DispositivosLoaded>()
              .having((s) => s.total, 'total', 1)
              .having((s) => s.aprobados, 'aprobados', 1),
        ]),
      );

      bloc.add(const CargarDispositivosEvent('usr-1'));
    });

    test('CargarDispositivosEvent emite DispositivosFailure cuando falla la conexión', () async {
      mockRepo.failNext = true;

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DispositivosLoading>(),
          isA<DispositivosFailure>().having(
            (s) => s.error,
            'error',
            contains('Error al conectar'),
          ),
        ]),
      );

      bloc.add(const CargarDispositivosEvent('usr-1'));
    });

    test(
      'AprobarDispositivoEvent aprueba el dispositivo y emite mensaje de éxito',
      () async {
        mockRepo.dispositivos = const [
          DispositivoModel(
            id: 'dev-pend',
            usuarioId: 'usr-1',
            instalacionId: 'inst-2',
            modelo: 'iPhone 15',
            so: 'iOS 17',
            versionApp: '1.0.0',
            confiable: false,
            pendienteAprobacion: true,
          ),
        ];

        // Inicializar cargando
        bloc.add(const CargarDispositivosEvent('usr-1'));
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(
          const AprobarDispositivoEvent(
            dispositivoId: 'dev-pend',
            usuarioId: 'usr-1',
          ),
        );

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<DispositivosLoaded>().having(
              (s) => s.isProcessing,
              'isProcessing',
              isTrue,
            ),
            isA<DispositivosLoaded>()
                .having((s) => s.aprobados, 'aprobados', 1)
                .having(
                  (s) => s.actionSuccessMessage,
                  'msg',
                  contains('aprobado exitosamente'),
                ),
          ]),
        );
      },
    );

    test(
      'RevocarDispositivoEvent revoca el dispositivo con motivo opcional',
      () async {
        mockRepo.dispositivos = const [
          DispositivoModel(
            id: 'dev-active',
            usuarioId: 'usr-1',
            instalacionId: 'inst-3',
            modelo: 'Galaxy S24',
            so: 'Android 14',
            versionApp: '1.0.0',
            confiable: true,
            pendienteAprobacion: false,
          ),
        ];

        bloc.add(const CargarDispositivosEvent('usr-1'));
        await Future.delayed(const Duration(milliseconds: 50));

        bloc.add(
          const RevocarDispositivoEvent(
            dispositivoId: 'dev-active',
            usuarioId: 'usr-1',
            motivo: 'Extravío del equipo',
          ),
        );

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<DispositivosLoaded>().having(
              (s) => s.isProcessing,
              'isProcessing',
              isTrue,
            ),
            isA<DispositivosLoaded>()
                .having((s) => s.revocados, 'revocados', 1)
                .having(
                  (s) => s.actionSuccessMessage,
                  'msg',
                  contains('revocado exitosamente'),
                ),
          ]),
        );
      },
    );
  });
}
