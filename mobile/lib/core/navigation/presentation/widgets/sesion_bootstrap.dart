// sesion_bootstrap.dart — Tareas al entrar al shell autenticado (US-LEG-01, US-NOT-01)
// Orden: 1) consentimiento (aviso a pantalla completa antes de cualquier permiso de
// ubicación); 2) destinos de notificaciones pendientes; 3) bandeja; 4) registro push.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/notificaciones/data/push_registro_service.dart';
import '../../../../features/notificaciones/presentation/cubit/bandeja_cubit.dart';
import '../../../../features/notificaciones/presentation/notificacion_navegador.dart';
import '../../../../features/privacidad/presentation/cubit/consentimiento_cubit.dart';
import '../../../../features/privacidad/presentation/cubit/consentimiento_state.dart';
import '../../../../features/privacidad/presentation/screens/aviso_privacidad_screen.dart';
import '../bloc/nav_bloc.dart';
import '../bloc/nav_event.dart';

class SesionBootstrap extends StatefulWidget {
  final Widget child;

  const SesionBootstrap({super.key, required this.child});

  @override
  State<SesionBootstrap> createState() => _SesionBootstrapState();
}

class _SesionBootstrapState extends State<SesionBootstrap> {
  late final NotificacionNavegador _navegador;

  @override
  void initState() {
    super.initState();
    _navegador = context.read<NotificacionNavegador>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  Future<void> _iniciar() async {
    final consentimiento = context.read<ConsentimientoCubit>();
    final push = context.read<PushRegistroService>();
    final bandeja = context.read<BandejaCubit>();
    final nav = context.read<NavBloc>();

    await consentimiento.verificar();
    if (!mounted) return;
    if (consentimiento.state.debePreguntar) {
      // El listener muestra el aviso; se espera la decisión explícita.
      await _mostrarAviso();
      if (consentimiento.state.debePreguntar) {
        await consentimiento.stream.firstWhere((s) => !s.debePreguntar);
      }
    }
    if (!mounted) return;

    _navegador.adjuntar(
        (d) => nav.add(NavRutaSolicitada(d.rutaShell, sesionId: d.sesionId)));
    bandeja.cargar();
    await push.registrar();
  }

  Future<void> _mostrarAviso() async {
    if (!mounted || AvisoPrivacidadScreen.visible) return;
    await AvisoPrivacidadScreen.mostrar(context);
    _navegador.intentar();
  }

  @override
  void dispose() {
    _navegador.desadjuntar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConsentimientoCubit, ConsentimientoState>(
      // Tras cada verificación que exige decisión (nueva versión, 403 del servidor).
      listenWhen: (a, b) =>
          b.fase == FaseConsentimiento.listo &&
          b.debePreguntar &&
          (a.fase != b.fase || a.consentimiento != b.consentimiento),
      listener: (context, state) => _mostrarAviso(),
      child: widget.child,
    );
  }
}
