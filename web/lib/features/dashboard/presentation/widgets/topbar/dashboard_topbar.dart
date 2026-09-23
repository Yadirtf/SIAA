import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:siaa_web/core/theme/app_theme.dart';
import 'package:siaa_web/features/auth/presentation/bloc/auth_bloc.dart';

class DashboardTopbar extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;

  const DashboardTopbar({
    super.key,
    required this.title,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                tooltip: 'Refrescar datos',
                onPressed: onRefresh,
              ),
            ],
          ),
          BlocBuilder<WebAuthBloc, WebAuthState>(
            builder: (context, state) {
              String nombre = 'Administrador';
              String correo = 'admin@siaa.edu.co';
              if (state is WebAuthAuthenticated) {
                nombre = '${state.usuario.nombre} ${state.usuario.apellido}';
                correo = state.usuario.correo;
              }

              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: SIAAColors.primary100,
                    child: Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : 'A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: SIAAColors.primary700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        correo,
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(Icons.logout, size: 20, color: Colors.black54),
                    tooltip: 'Cerrar sesión',
                    onPressed: () =>
                        context.read<WebAuthBloc>().add(const WebAuthLogoutRequested()),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
