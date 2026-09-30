// notificacion_navegacion_test.dart — Navegación al tocar una notificación (US-MAR-12)
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siaa_mobile/core/navigation/presentation/bloc/nav_bloc.dart';
import 'package:siaa_mobile/core/navigation/presentation/bloc/nav_event.dart';
import 'package:siaa_mobile/core/navigation/presentation/bloc/nav_state.dart';
import 'package:siaa_mobile/features/notificaciones/domain/models/destino_notificacion.dart';
import 'package:siaa_mobile/features/notificaciones/presentation/notificacion_navegador.dart';

void main() {
  group('NotificacionNavegador', () {
    test('guarda el destino hasta que el shell se adjunta', () {
      var cierres = 0;
      final abiertos = <DestinoNotificacion>[];
      final nav = NotificacionNavegador(
        cerrarRutasSuperiores: () => cierres++,
        bloqueado: () => false,
      );
      const d = DestinoNotificacion(PantallaNotificacion.horario);

      nav.solicitar(d);
      expect(abiertos, isEmpty);
      expect(nav.pendiente, d);

      nav.adjuntar(abiertos.add);
      expect(abiertos, [d]);
      expect(cierres, 1);
      expect(nav.pendiente, isNull);
    });

    test('no navega mientras el aviso de privacidad está en pantalla', () {
      var bloqueado = true;
      final abiertos = <DestinoNotificacion>[];
      final nav = NotificacionNavegador(
        cerrarRutasSuperiores: () {},
        bloqueado: () => bloqueado,
      )..adjuntar(abiertos.add);

      nav.solicitar(const DestinoNotificacion(PantallaNotificacion.marcaje));
      expect(abiertos, isEmpty);

      bloqueado = false;
      nav.intentar();
      expect(abiertos, hasLength(1));
    });
  });

  group('NavRutaSolicitada', () {
    const docente = NavInicializado(
      rolesUsuario: ['docente'],
      permisosUsuario: [
        'marcaje:crear',
        'marcaje:leer',
        'justificacion:crear',
        'horario:leer'
      ],
    );

    blocTest<NavBloc, NavState>(
      'marcaje abre la pestaña Inicio con la sesión objetivo',
      build: NavBloc.new,
      act: (b) => b
        ..add(docente)
        ..add(const NavTabCambiado(2))
        ..add(const NavRutaSolicitada('/shell/inicio', sesionId: 'ses-9')),
      skip: 2,
      expect: () => [
        isA<NavState>()
            .having((s) => s.tabIndex, 'tab', 0)
            .having((s) => s.sesionIdObjetivo, 'sesion', 'ses-9'),
      ],
    );

    blocTest<NavBloc, NavState>(
      'justificaciones y horario abren su pestaña',
      build: NavBloc.new,
      act: (b) => b
        ..add(docente)
        ..add(const NavRutaSolicitada('/shell/justificaciones'))
        ..add(const NavRutaSolicitada('/shell/horario')),
      skip: 1,
      expect: () => [
        isA<NavState>().having((s) => s.tabIndex, 'tab', 3),
        isA<NavState>().having((s) => s.tabIndex, 'tab', 1),
      ],
    );

    blocTest<NavBloc, NavState>(
      'una ruta no permitida para el rol se ignora',
      build: NavBloc.new,
      act: (b) => b
        ..add(docente)
        ..add(const NavRutaSolicitada('/shell/editor-gps')),
      skip: 1,
      expect: () => [],
    );
  });
}
