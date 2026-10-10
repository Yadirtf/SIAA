// main.dart - Punto de entrada y bootstrap de la app movil SIAA
// T-PLT-03.1, T-PLT-03.8, T-PLT-03.9
// US-LEG-01: consentimiento antes de cualquier permiso de ubicacion.
// US-NOT-01: push opcional (solo si hay dart-defines de Firebase).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/navigation/config/app_navigator_keys.dart';
import 'core/navigation/config/app_routes.dart';
import 'core/navigation/presentation/bloc/nav_bloc.dart';
import 'core/network/jitter_service.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/geo_editor/data/cartografia_sync_service.dart';
import 'features/marcaje/data/repositories/marcaje_repository.dart';
import 'features/marcaje/data/services/marcaje_sync_trigger.dart';
import 'features/notificaciones/data/fcm_push_proveedor.dart';
import 'features/notificaciones/data/push_proveedor.dart';
import 'features/notificaciones/data/push_registro_service.dart';
import 'features/notificaciones/presentation/cubit/bandeja_cubit.dart';
import 'features/notificaciones/presentation/notificacion_navegador.dart';
import 'features/notificaciones/presentation/push_mensajes_listener.dart';
import 'features/privacidad/data/consentimiento_gate.dart';
import 'features/privacidad/presentation/cubit/consentimiento_cubit.dart';
import 'shared/widgets/error_fallback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientacion solo vertical en movil
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Estilo de barra de sistema
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  ErrorWidget.builder = (errorDetails) => ErrorFallback(
        message: errorDetails.exceptionAsString(),
      );

  // Aceptacion guardada: permite marcar offline hasta que el servidor confirme.
  await ConsentimientoGate.instance.restaurar();

  final push = await FcmPushProveedor.inicializar();
  final navegador = NotificacionNavegador();
  final bandeja = BandejaCubit();

  runApp(SIAAApp(push: push, navegador: navegador, bandeja: bandeja));

  if (push != null) {
    PushMensajesListener(
      push: push,
      navegador: navegador,
      onMensaje: bandeja.cargar,
    ).iniciar();
  }

  // Cola offline de marcajes: sincroniza al volver la red o la app (US-MAR-11).
  final marcajeRepository = MarcajeRepository();
  MarcajeSyncTrigger(
    sincronizar: marcajeRepository.sincronizarMarcajesOffline,
    haySesion: () async =>
        ConsentimientoGate.instance.permiteSincronizar &&
        await SecureStorage.getAccessToken() != null,
    esperarJitter: JitterService().waitJitter,
  ).iniciar();

  // Capturas de cartografía guardadas sin conexión (US-GEO-10 AC-02): se envían al
  // recuperar la red y se informa el resultado; el detalle queda en Editor GPS.
  final cartografia = CartografiaSyncService();
  cartografia.resultados.listen((r) => AppNavigatorKeys.messenger.currentState
      ?.showSnackBar(SnackBar(content: Text(r.resumen))));
  MarcajeSyncTrigger(
    sincronizar: cartografia.sincronizar,
    haySesion: () async => await SecureStorage.getAccessToken() != null,
    esperarJitter: JitterService().waitJitter,
  ).iniciar();
}

class SIAAApp extends StatelessWidget {
  /// Proveedor push; null cuando Firebase no esta configurado.
  final PushProveedor? push;
  final NotificacionNavegador? navegador;
  final BandejaCubit? bandeja;

  const SIAAApp({super.key, this.push, this.navegador, this.bandeja});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => AuthRepository()),
        RepositoryProvider(create: (_) => PushRegistroService(push: push)),
        RepositoryProvider(create: (_) => navegador ?? NotificacionNavegador()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ConsentimientoCubit()),
          BlocProvider(create: (_) => bandeja ?? BandejaCubit()),
          BlocProvider(
            create: (ctx) => AuthBloc(
              repository: ctx.read<AuthRepository>(),
              antesDeCerrarSesion: () async {
                final pushRegistro = ctx.read<PushRegistroService>();
                final bandejaCubit = ctx.read<BandejaCubit>();
                final consentimiento = ctx.read<ConsentimientoCubit>();
                await pushRegistro.desregistrar();
                await ConsentimientoGate.instance.reiniciar();
                bandejaCubit.reiniciar();
                consentimiento.reiniciar();
              },
            )..add(AuthSessionChecked()),
          ),
          // NavBloc: se inicializa via NavInicializado al autenticar.
          // Consume los permisos resueltos por el backend (RF-ROL-003).
          BlocProvider(create: (_) => NavBloc()),
        ],
        child: MaterialApp(
          title: 'SIAA',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppNavigatorKeys.navigator,
          scaffoldMessengerKey: AppNavigatorKeys.messenger,

          // Temas - T-PLT-03.3
          theme: SIAATheme.light,
          darkTheme: SIAATheme.dark,
          themeMode: ThemeMode.system, // RNF-USA-004

          // Internacionalizacion - T-PLT-03.8
          locale: const Locale('es', 'CO'),
          supportedLocales: const [Locale('es', 'CO')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Navegacion centralizada en AppRoutes
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
        ),
      ),
    );
  }
}
