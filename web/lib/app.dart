import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/academico/data/academico_remote_datasource.dart';
import 'features/academico/domain/academico_repository.dart';
import 'features/academico/presentation/bloc/academico_bloc.dart';
import 'features/auth/data/auth_remote_datasource.dart';
import 'features/auth/domain/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/dashboard/presentation/screens/dashboard_shell.dart';
import 'features/dispositivos/data/dispositivos_remote_datasource.dart';
import 'features/dispositivos/data/dispositivos_repository_impl.dart';
import 'features/dispositivos/domain/dispositivos_repository.dart';
import 'features/dispositivos/presentation/bloc/dispositivos_bloc.dart';
import 'features/geo/data/geo_remote_datasource.dart';
import 'features/geo/domain/geo_repository.dart';
import 'features/geo/presentation/bloc/geo_bloc.dart';

class SiaaApp extends StatelessWidget {
  const SiaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (_) =>
              AuthRepositoryImpl(remoteDataSource: AuthRemoteDataSource()),
        ),
        RepositoryProvider<GeoRepository>(
          create: (_) =>
              GeoRepositoryImpl(remoteDataSource: GeoRemoteDataSource()),
        ),
        RepositoryProvider<AcademicoRepository>(
          create: (_) => AcademicoRepositoryImpl(
            remoteDataSource: AcademicoRemoteDataSource(),
          ),
        ),
        RepositoryProvider<DispositivosRepository>(
          create: (_) => DispositivosRepositoryImpl(
            remoteDataSource: DispositivosRemoteDataSource(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (ctx) =>
                AuthBloc(authRepository: ctx.read<AuthRepository>())
                  ..add(const CheckAuthStatusEvent()),
          ),
          BlocProvider<GeoBloc>(
            create: (ctx) => GeoBloc(repository: ctx.read<GeoRepository>()),
          ),
          BlocProvider<AcademicoBloc>(
            create: (ctx) =>
                AcademicoBloc(repository: ctx.read<AcademicoRepository>()),
          ),
          BlocProvider<DispositivosBloc>(
            create: (ctx) => DispositivosBloc(
              repository: ctx.read<DispositivosRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'SIAA - Sistema Integral de Asignación Académica',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.runtimeType != current.runtimeType ||
          current is Authenticated ||
          current is Unauthenticated,
      builder: (context, state) {
        if (state is Authenticated) {
          return const DashboardShell();
        }
        if (state is Unauthenticated || state is AuthFailure) {
          return const LoginScreen();
        }
        return const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primaryAccent),
                SizedBox(height: 16),
                Text(
                  'Cargando SIAA...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
