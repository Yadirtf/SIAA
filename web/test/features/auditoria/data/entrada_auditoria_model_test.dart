import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/auditoria/data/models/entrada_auditoria_model.dart';
import 'package:siaa_web/features/auditoria/data/models/filtro_auditoria_model.dart';

void main() {
  test('fromJson conserva valores JSON arbitrarios', () {
    final e = EntradaAuditoriaModel.fromJson({
      'id': 'a1',
      'entidad': 'justificacion',
      'entidadId': 'j1',
      'accion': 'justificacion.aprobar',
      'actorId': 'u1',
      'actorNombre': 'Carlos Ruiz',
      'rolActivo': 'COORDINADOR',
      'ipOrigen': '10.0.0.1',
      'valorAnterior': {'estado': 'RADICADA'},
      'valorNuevo': {
        'estado': 'APROBADA',
        'tags': [1, 2],
      },
      'creadoEn': '2026-09-29T12:00:00Z',
    });
    expect(e.actor, 'Carlos Ruiz');
    expect(e.rolActivo, 'COORDINADOR');
    expect(e.correlationId, isNull);
    expect((e.valorNuevo as Map)['estado'], 'APROBADA');
    expect(
      EntradaAuditoriaModel.jsonLegible(e.valorAnterior),
      '{\n  "estado": "RADICADA"\n}',
    );
    expect(EntradaAuditoriaModel.jsonLegible(null), isNull);
  });

  test('sin actorNombre muestra el id del actor', () {
    final e = EntradaAuditoriaModel.fromJson({'id': 'a2', 'actorId': 'u9'});
    expect(e.actor, 'u9');
  });

  test('toQuery omite vacíos y la exportación no pagina', () {
    const f = FiltroAuditoriaModel(entidad: 'usuario', accion: ' usuario. ');
    expect(f.toQuery(), {
      'entidad': 'usuario',
      'accion': 'usuario.',
      'pagina': '1',
      'limite': '50',
    });
    expect(f.toQuery(paginado: false), {
      'entidad': 'usuario',
      'accion': 'usuario.',
    });
  });
}
