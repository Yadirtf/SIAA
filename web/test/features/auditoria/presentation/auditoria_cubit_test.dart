import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/core/models/pagina.dart';
import 'package:siaa_web/core/network/api_exception.dart';
import 'package:siaa_web/core/network/archivo_binario.dart';
import 'package:siaa_web/features/auditoria/data/models/entrada_auditoria_model.dart';
import 'package:siaa_web/features/auditoria/data/models/filtro_auditoria_model.dart';
import 'package:siaa_web/features/auditoria/domain/auditoria_repository.dart';
import 'package:siaa_web/features/auditoria/presentation/bloc/auditoria_cubit.dart';
import 'package:siaa_web/features/auditoria/presentation/bloc/auditoria_state.dart';

class _FakeAuditoriaRepository implements AuditoriaRepository {
  List<EntradaAuditoriaModel> entradas = [];
  ApiException? error;
  FiltroAuditoriaModel? ultimoFiltro;
  final List<String> exportaciones = [];

  @override
  Future<Pagina<EntradaAuditoriaModel>> consultar(
    FiltroAuditoriaModel f,
  ) async {
    ultimoFiltro = f;
    if (error != null) throw error!;
    return Pagina(
      items: entradas,
      total: 120,
      pagina: f.pagina,
      limite: f.limite,
    );
  }

  @override
  Future<ArchivoBinario> exportar(
    FiltroAuditoriaModel f,
    String formato,
  ) async {
    ultimoFiltro = f;
    exportaciones.add(formato);
    if (error != null) throw error!;
    return ArchivoBinario(bytes: Uint8List(0), mime: 'application/pdf');
  }
}

void main() {
  late _FakeAuditoriaRepository repo;
  late List<String> guardados;

  AuditoriaCubit crear() => AuditoriaCubit(
    repository: repo,
    guardar: (_, n) => guardados.add(n),
    ahora: () => DateTime(2026, 9, 29, 9, 0),
  );

  setUp(() {
    repo = _FakeAuditoriaRepository()
      ..entradas = [
        const EntradaAuditoriaModel(
          id: 'a1',
          entidad: 'usuario',
          entidadId: 'u1',
          accion: 'usuario.crear',
          actorId: 'admin',
        ),
      ];
    guardados = [];
  });

  test('carga con filtros y pagina', () async {
    final cubit = crear();
    await cubit.cargar(const FiltroAuditoriaModel(accion: 'usuario.'));
    expect(cubit.state.status, AuditoriaStatus.cargado);
    expect(cubit.state.pagina!.items.single.accion, 'usuario.crear');
    expect(cubit.state.pagina!.hayMas, isTrue);

    await cubit.irAPagina(2);
    expect(repo.ultimoFiltro!.pagina, 2);
    expect(repo.ultimoFiltro!.accion, 'usuario.');
    await cubit.close();
  });

  test('error del backend deja estado de error', () async {
    repo.error = const AuthException(message: 'Prohibido', statusCode: 403);
    final cubit = crear();
    await cubit.recargar();
    expect(cubit.state.status, AuditoriaStatus.error);
    expect(cubit.state.error, 'Prohibido');
    await cubit.close();
  });

  test('exportar usa el filtro vigente y entrega el archivo', () async {
    final cubit = crear();
    await cubit.cargar(const FiltroAuditoriaModel(entidad: 'usuario'));
    final estados = <AuditoriaState>[];
    final sub = cubit.stream.listen(estados.add);
    await cubit.exportar('pdf');
    expect(repo.exportaciones, ['pdf']);
    expect(repo.ultimoFiltro!.entidad, 'usuario');
    expect(guardados, ['auditoria_20260929_0900.pdf']);
    expect(estados.first.exportando, 'pdf');
    expect(cubit.state.exportando, isNull);
    expect(cubit.state.mensajeExito, contains('PDF'));
    expect(cubit.state.status, AuditoriaStatus.cargado);
    await sub.cancel();
    await cubit.close();
  });
}
