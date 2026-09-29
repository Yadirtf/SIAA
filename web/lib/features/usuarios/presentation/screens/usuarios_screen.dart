import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/usuario_model.dart';
import '../bloc/catalogo_usuarios_cubit.dart';
import '../bloc/usuarios_bloc.dart';
import '../bloc/usuarios_event.dart';
import '../bloc/usuarios_state.dart';
import '../dialogs/ambitos_usuario_dialog.dart';
import '../dialogs/importar_usuarios_dialog.dart';
import '../dialogs/motivo_usuario_dialog.dart';
import '../dialogs/roles_usuario_dialog.dart';
import '../dialogs/usuario_form_dialog.dart';
import '../widgets/usuario_acciones_menu.dart';
import '../widgets/usuarios_filtros_bar.dart';
import '../widgets/usuarios_header.dart';
import '../widgets/usuarios_paginacion.dart';
import '../widgets/usuarios_table.dart';

/// Administración de usuarios: listado, alta, edición, roles, ámbitos,
/// activación e importación masiva.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<UsuariosBloc>();
    bloc.add(CargarUsuariosEvent(bloc.state.filtro));
    context.read<CatalogoUsuariosCubit>().cargar();
  }

  void _onAccion(UsuarioModel u, UsuarioAccion accion) {
    final bloc = context.read<UsuariosBloc>();
    switch (accion) {
      case UsuarioAccion.editar:
        UsuarioFormDialog.show(context, usuario: u);
      case UsuarioAccion.roles:
        RolesUsuarioDialog.show(context, u);
      case UsuarioAccion.ambitos:
        AmbitosUsuarioDialog.show(context, u);
      case UsuarioAccion.activar:
        bloc.add(ActivarUsuarioEvent(u.id));
      case UsuarioAccion.desbloquear:
        bloc.add(DesbloquearUsuarioEvent(u.id));
      case UsuarioAccion.desactivar:
        MotivoUsuarioDialog.show(
          context,
          titulo: 'Desactivar a ${u.nombreCompleto}',
          descripcion:
              'El usuario no podrá iniciar sesión y sus sesiones activas se '
              'cerrarán. Podrá reactivarlo más adelante.',
          textoConfirmar: 'Desactivar',
          icono: Icons.person_off_outlined,
          onMotivo: (m) => bloc.add(DesactivarUsuarioEvent(u.id, m)),
        );
      case UsuarioAccion.cerrarSesiones:
        MotivoUsuarioDialog.show(
          context,
          titulo: 'Cerrar sesiones de ${u.nombreCompleto}',
          descripcion:
              'Se revocarán todas las sesiones activas del usuario en web y '
              'móvil; deberá iniciar sesión de nuevo.',
          textoConfirmar: 'Cerrar sesiones',
          icono: Icons.logout_rounded,
          onMotivo: (m) => bloc.add(RevocarSesionesUsuarioEvent(u.id, m)),
        );
    }
  }

  void _snack(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsuariosBloc, UsuariosState>(
      listenWhen: (a, b) =>
          (b.mensajeExito != null && a.mensajeExito != b.mensajeExito) ||
          (b.mensajeError != null && a.mensajeError != b.mensajeError),
      listener: (context, state) {
        if (state.mensajeExito != null) {
          _snack(state.mensajeExito!, AppColors.statusSuccessText);
        } else if (state.mensajeError != null) {
          _snack(state.mensajeError!, AppColors.statusDangerText);
        }
      },
      builder: (context, state) {
        final bloc = context.read<UsuariosBloc>();
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UsuariosHeader(
                onNuevo: () => UsuarioFormDialog.show(context),
                onImportar: () => ImportarUsuariosDialog.show(context),
              ),
              const SizedBox(height: 20),
              UsuariosFiltrosBar(
                filtro: state.filtro,
                onFiltrar: (f) => bloc.add(CargarUsuariosEvent(f)),
                onRecargar: () => bloc.add(const RecargarUsuariosEvent()),
              ),
              const SizedBox(height: 16),
              if (state.procesando) const LinearProgressIndicator(),
              const SizedBox(height: 4),
              _contenido(state),
            ],
          ),
        );
      },
    );
  }

  Widget _contenido(UsuariosState state) {
    switch (state.status) {
      case UsuariosStatus.inicial:
      case UsuariosStatus.cargando:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: AppColors.primaryAccent),
          ),
        );
      case UsuariosStatus.error:
        return _aviso(
          icono: Icons.error_outline_rounded,
          color: AppColors.accentRose,
          titulo: 'Error al consultar usuarios',
          detalle: state.errorCarga ?? '',
          accion: ElevatedButton.icon(
            onPressed: () =>
                context.read<UsuariosBloc>().add(const RecargarUsuariosEvent()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        );
      case UsuariosStatus.cargado:
        final pagina = state.pagina!;
        if (pagina.usuarios.isEmpty && pagina.pagina == 1) {
          return _aviso(
            icono: Icons.person_search_rounded,
            color: AppColors.textMuted,
            titulo: 'No se encontraron usuarios',
            detalle: 'Ajuste la búsqueda o los filtros, o cree un usuario.',
          );
        }
        return Column(
          children: [
            UsuariosTable(
              usuarios: pagina.usuarios,
              procesando: state.procesando,
              onAccion: _onAccion,
            ),
            const SizedBox(height: 8),
            UsuariosPaginacion(
              pagina: pagina,
              onPagina: (p) => context.read<UsuariosBloc>().add(
                CargarUsuariosEvent(state.filtro.copyWith(pagina: p)),
              ),
            ),
          ],
        );
    }
  }

  Widget _aviso({
    required IconData icono,
    required Color color,
    required String titulo,
    required String detalle,
    Widget? accion,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 48),
          const SizedBox(height: 12),
          Text(titulo, style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            detalle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (accion != null) ...[const SizedBox(height: 16), accion],
        ],
      ),
    );
  }
}
