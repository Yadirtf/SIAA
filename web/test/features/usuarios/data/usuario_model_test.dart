import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_web/features/usuarios/data/models/ambito_model.dart';
import 'package:siaa_web/features/usuarios/data/models/importacion_usuarios_model.dart';
import 'package:siaa_web/features/usuarios/data/models/rol_asignado_model.dart';
import 'package:siaa_web/features/usuarios/data/models/usuario_model.dart';
import 'package:siaa_web/features/usuarios/data/models/usuario_requests.dart';

void main() {
  group('UsuarioModel.fromJson (US-ROL-01..05)', () {
    test('deserializa el UsuarioDTO completo del backend', () {
      final json = {
        'id': 'usr-1',
        'correo': 'ana@uni.edu.co',
        'nombre': 'Ana',
        'apellido': 'Pérez',
        'documento': '1020304050',
        'activo': true,
        'bloqueado': false,
        'totpActivado': true,
        'roles': ['DOCENTE', 'COORDINADOR'],
        'rolesDetalle': [
          {'nombre': 'DOCENTE'},
          {
            'nombre': 'COORDINADOR',
            'vigenciaInicio': '2026-01-01T00:00:00Z',
            'vigenciaFin': '2026-12-31T00:00:00Z',
          },
        ],
        'ambitos': [
          {'tipo': 'SEDE', 'id': 'sede-1'},
          {'tipo': 'FACULTAD', 'id': 'fac-2'},
        ],
        'creadoEn': '2026-03-01T10:00:00Z',
      };

      final u = UsuarioModel.fromJson(json);

      expect(u.id, 'usr-1');
      expect(u.nombreCompleto, 'Ana Pérez');
      expect(u.documento, '1020304050');
      expect(u.totpActivado, isTrue);
      expect(u.roles, ['DOCENTE', 'COORDINADOR']);
      expect(u.rolesDetalle[1].vigenciaFin, DateTime.utc(2026, 12, 31));
      expect(u.ambitos, const [
        AmbitoModel(tipo: 'SEDE', id: 'sede-1'),
        AmbitoModel(tipo: 'FACULTAD', id: 'fac-2'),
      ]);
      expect(u.estadoTexto, 'Activo');
      expect(u.creadoEn, DateTime.utc(2026, 3, 1, 10));
    });

    test('tolera campos opcionales ausentes y prioriza el bloqueo', () {
      final u = UsuarioModel.fromJson({
        'id': 'usr-2',
        'correo': 'b@uni.edu.co',
        'nombre': 'Beto',
        'apellido': 'Gil',
        'activo': true,
        'bloqueado': true,
        'roles': ['ESTUDIANTE'],
      });

      expect(u.documento, isNull);
      expect(u.ambitos, isEmpty);
      expect(u.rolesDetalle, const [RolAsignadoModel(nombre: 'ESTUDIANTE')]);
      expect(u.estadoTexto, 'Bloqueado');
      expect(
        UsuarioModel.fromJson({'id': 'x', 'activo': false}).estadoTexto,
        'Inactivo',
      );
    });
  });

  group('Peticiones y resultado de importación', () {
    test('CrearUsuarioRequest omite password y documento vacíos', () {
      const req = CrearUsuarioRequest(
        correo: 'c@uni.edu.co',
        nombre: 'Carla',
        apellido: 'Ruiz',
        documento: '',
        password: '',
        roles: ['DOCENTE'],
        ambitos: [AmbitoModel(tipo: 'BLOQUE', id: 'b-1')],
      );

      final json = req.toJson();

      expect(json.containsKey('password'), isFalse);
      expect(json.containsKey('documento'), isFalse);
      expect(json['roles'], [
        {'nombre': 'DOCENTE'},
      ]);
      expect(json['ambitos'], [
        {'tipo': 'BLOQUE', 'id': 'b-1'},
      ]);
    });

    test('ImportacionUsuariosModel deserializa filas válidas y con error', () {
      final r = ImportacionUsuariosModel.fromJson({
        'confirmado': false,
        'total': 2,
        'validas': 1,
        'creados': 0,
        'filas': [
          {'fila': 2, 'correo': 'a@uni.edu.co', 'nombre': 'A', 'valida': true},
          {
            'fila': 3,
            'correo': 'a@uni.edu.co',
            'nombre': 'A2',
            'valida': false,
            'error': 'correo duplicado',
          },
        ],
      });

      expect(r.conError, 1);
      expect(r.filas.first.valida, isTrue);
      expect(r.filas.last.error, 'correo duplicado');
      expect(r.filas.last.creado, isFalse);
    });
  });
}
