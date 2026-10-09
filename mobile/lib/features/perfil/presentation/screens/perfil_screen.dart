// perfil_screen.dart — Perfil (§9.1): datos, roles, dispositivo vinculado, privacidad y
// cierre de sesión. Disponible para todos los roles.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/config/rol_slug.dart';
import '../../../../core/navigation/presentation/bloc/nav_bloc.dart';
import '../../../../core/navigation/presentation/bloc/nav_event.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../home/presentation/widgets/dialogs/confirmar_logout_dialog.dart';
import '../../data/asistencia_remote_datasource.dart';
import '../../data/perfil_remote_datasource.dart';
import '../../domain/perfil_model.dart';
import '../cubit/perfil_cubit.dart';
import '../widgets/dispositivo_tile.dart';
import '../widgets/mi_asistencia_section.dart';

class PerfilScreen extends StatelessWidget {
  final PerfilRemoteDataSource? remote;
  final Future<String> Function()? instalacionId;
  final AsistenciaRemoteDataSource? asistenciaRemote;

  const PerfilScreen({
    super.key,
    this.remote,
    this.instalacionId,
    this.asistenciaRemote,
  });

  static PerfilModel _desdeSesion(AuthState s) => s is AuthAuthenticated
      ? PerfilModel(
          id: s.usuarioId,
          nombre: s.nombre,
          correo: s.correo,
          roles: s.roles,
          completo: false,
        )
      : const PerfilModel(id: '', nombre: '', completo: false);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => PerfilCubit(
        desdeSesion: _desdeSesion(ctx.read<AuthBloc>().state),
        instalacionId: instalacionId ?? SecureStorage.getOrCreateInstalacionId,
        remote: remote,
      )..cargar(),
      child: BlocBuilder<PerfilCubit, PerfilState>(
        builder: (context, state) => _contenido(context, state),
      ),
    );
  }

  Widget _contenido(BuildContext context, PerfilState state) {
    final p = state.perfil;
    final gris = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return RefreshIndicator(
      onRefresh: context.read<PerfilCubit>().cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.cargando) const LinearProgressIndicator(),
          Row(children: [
            CircleAvatar(
              radius: 28,
              child: Text(p.nombreCompleto[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nombreCompleto,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    if (p.correo.isNotEmpty)
                      Text(p.correo, style: TextStyle(color: gris)),
                  ]),
            ),
          ]),
          if (state.aviso != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(state.aviso!,
                  style: TextStyle(fontSize: 12, color: gris)),
            ),
          _seccion('Datos de la cuenta'),
          if (p.documento.isNotEmpty) _dato('Documento', p.documento),
          _dato('Verificación en dos pasos',
              p.totpActivado ? 'Activada' : 'No activada'),
          Wrap(spacing: 8, runSpacing: 4, children: [
            for (final r in p.roles) Chip(label: Text(etiquetaRol(r))),
          ]),
          if (p.roles.any((r) => rolSlugDe(r) == 'estudiante'))
            MiAsistenciaSection(remote: asistenciaRemote),
          _seccion('Dispositivos vinculados'),
          if (p.dispositivos.isEmpty)
            Text(p.completo ? 'Sin dispositivos registrados' : 'No disponible',
                style: TextStyle(color: gris))
          else
            for (final d in p.dispositivos)
              DispositivoTile(
                dispositivo: d,
                esActual: d.instalacionId.isNotEmpty &&
                    d.instalacionId == state.instalacionActual,
              ),
          const Divider(height: 32),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacidad y datos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context
                .read<NavBloc>()
                .add(const NavDrawerItemSelected('/shell/privacidad')),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_shared_outlined),
            title: const Text('Mis datos y derechos'),
            subtitle: const Text('Copia, rectificación y supresión'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context
                .read<NavBloc>()
                .add(const NavDrawerItemSelected('/shell/derechos')),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style:
                OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
            onPressed: () => ConfirmarLogoutDialog.mostrar(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _seccion(String t) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(t,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      );

  Widget _dato(String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text(etiqueta)),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      );
}
