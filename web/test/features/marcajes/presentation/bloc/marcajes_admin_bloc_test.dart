// marcajes_admin_bloc_test.dart — Pruebas del MarcajesAdminBloc
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/marcajes/domain/models/marcaje_admin_model.dart';
import 'package:siaa_web/features/marcajes/domain/repositories/marcajes_admin_repository.dart';
import 'package:siaa_web/features/marcajes/presentation/bloc/marcajes_admin_bloc.dart';
import 'package:siaa_web/features/marcajes/presentation/bloc/marcajes_admin_event.dart';
import 'package:siaa_web/features/marcajes/presentation/bloc/marcajes_admin_state.dart';

class MockMarcajesAdminRepository implements MarcajesAdminRepository {
  List<MarcajeAdminModel> marcajes = [];
  bool failNext = false;
  String? lastAjustadoId;
  String? lastAjustadoMotivo;

  @override
  Future<MarcajeAdminPageModel> listarMarcajes({
    FiltrosMarcajeAdmin filtros = const FiltrosMarcajeAdmin(),
    int pagina = 1,
    int limite = 20,
  }) async {
    if (failNext) throw Exception('Error de red al listar');
    return MarcajeAdminPageModel(
      items: marcajes,
      total: marcajes.length,
      pagina: pagina,
      limite: limite,
    );
  }

  @override
  Future<MarcajeAdminModel> ajustarMarcaje({
    required String marcajeId,
    required String accion,
    String? nuevoResultado,
    required bool anulado,
    required String motivo,
  }) async {
    if (failNext) throw Exception('Error al ajustar');
    lastAjustadoId = marcajeId;
    lastAjustadoMotivo = motivo;

    return MarcajeAdminModel(
      id: marcajeId,
      sesionId: 'ses-1',
      usuarioId: 'usr-1',
      tipo: 'ENTRADA',
      resultado: nuevoResultado ?? 'ACEPTADO',
      origen: 'MANUAL',
      anulado: anulado,
      motivoAjuste: motivo,
      timestampServidor: DateTime.now(),
      timestampDispositivo: DateTime.now(),
    );
  }

  @override
  Future<MarcajeAdminModel> crearMarcajeManual({
    required String sesionId,
    required String usuarioId,
    required String tipo,
    required String resultado,
    required String motivo,
  }) async {
    if (failNext) throw Exception('Error al crear manual');
    return MarcajeAdminModel(
      id: 'mar-manual-new',
      sesionId: sesionId,
      usuarioId: usuarioId,
      tipo: tipo,
      resultado: resultado,
      origen: 'MANUAL_DOCENTE',
      motivoAjuste: motivo,
      timestampServidor: DateTime.now(),
      timestampDispositivo: DateTime.now(),
    );
  }
}

void main() {
  late MockMarcajesAdminRepository repository;
  late MarcajesAdminBloc bloc;

  setUp(() {
    repository = MockMarcajesAdminRepository();
    bloc = MarcajesAdminBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  test('estado inicial es MarcajesAdminInitial', () {
    expect(bloc.state, isA<MarcajesAdminInitial>());
  });

  test('CargarMarcajesAdminEvent emite Loading y luego Loaded', () async {
    repository.marcajes = [
      MarcajeAdminModel(
        id: 'm-1',
        sesionId: 's-1',
        usuarioId: 'u-1',
        tipo: 'ENTRADA',
        resultado: 'ACEPTADO',
        origen: 'MOVIL_ONLINE',
        timestampServidor: DateTime.now(),
        timestampDispositivo: DateTime.now(),
      ),
    ];

    final expected = [
      isA<MarcajesAdminLoading>(),
      isA<MarcajesAdminLoaded>().having((s) => s.page.total, 'total', 1),
    ];

    expectLater(bloc.stream, emitsInOrder(expected));

    bloc.add(const CargarMarcajesAdminEvent());
  });

  test('AjustarMarcajeEvent emite Failure si motivo tiene menos de 20 caracteres', () async {
    final expected = [
      isA<MarcajesAdminFailure>().having(
        (s) => s.error,
        'error',
        contains('al menos 20 caracteres'),
      ),
    ];

    expectLater(bloc.stream, emitsInOrder(expected));

    bloc.add(const AjustarMarcajeEvent(
      marcajeId: 'm-1',
      accion: 'ANULAR',
      anulado: true,
      motivo: 'Muy corto', // Menor a 20 chars
    ));
  });

  test('AjustarMarcajeEvent emite Loading, ActionSuccess y recarga lista con motivo válido', () async {
    final expected = [
      isA<MarcajesAdminLoading>(),
      isA<MarcajesAdminActionSuccess>().having(
        (s) => s.mensaje,
        'mensaje',
        contains('éxito en auditoría'),
      ),
      isA<MarcajesAdminLoading>(),
      isA<MarcajesAdminLoaded>(),
    ];

    expectLater(bloc.stream, emitsInOrder(expected));

    bloc.add(const AjustarMarcajeEvent(
      marcajeId: 'm-1',
      accion: 'AJUSTAR',
      nuevoResultado: 'ACEPTADO',
      anulado: false,
      motivo: 'Corrección aprobada por resolución de decanatura académica.', // >= 20 chars
    ));
  });

  test('CrearMarcajeManualEvent emite Failure si motivo tiene menos de 20 caracteres', () async {
    final expected = [
      isA<MarcajesAdminFailure>().having(
        (s) => s.error,
        'error',
        contains('al menos 20 caracteres'),
      ),
    ];

    expectLater(bloc.stream, emitsInOrder(expected));

    bloc.add(const CrearMarcajeManualEvent(
      sesionId: 'ses-1',
      usuarioId: 'usr-1',
      tipo: 'ENTRADA',
      resultado: 'ACEPTADO',
      motivo: 'Falla wifi',
    ));
  });
}
