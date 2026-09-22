// HomeScreen — Pantalla principal del aplicativo móvil SIAA
// Conecta la sesión autenticada con las funciones de cartografía (US-GEO-02, US-GEO-03)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../geo_editor/presentation/bloc/geo_editor_bloc.dart';
import '../../../geo_editor/presentation/screens/geo_editor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _codigoEspacioController = TextEditingController(text: 'AULA-101');
  final _nombreEspacioController = TextEditingController(text: 'Aula Magistral 101');

  @override
  void dispose() {
    _codigoEspacioController.dispose();
    _nombreEspacioController.dispose();
    super.dispose();
  }

  void _abrirGeoEditor() {
    final codigo = _codigoEspacioController.text.trim().isEmpty
        ? 'AULA-101'
        : _codigoEspacioController.text.trim();
    final nombre = _nombreEspacioController.text.trim().isEmpty
        ? 'Aula Magistral 101'
        : _nombreEspacioController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<GeoEditorBloc>(
          create: (_) => GeoEditorBloc(),
          child: GeoEditorScreen(
            espacioId: 'esp-${codigo.toLowerCase()}',
            espacioCodigo: codigo,
            espacioNombre: nombre,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: SIAAColors.primary500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('SIAA Móvil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Cerrar sesión',
              onPressed: () => _confirmarCerrarSesion(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(SIAASpacing.lg),
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              String nombreUsuario = 'Usuario Institucional';
              List<String> roles = ['Docente'];

              if (authState is AuthAuthenticated) {
                nombreUsuario = authState.nombre;
                roles = authState.roles.isNotEmpty ? authState.roles : ['Docente'];
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Tarjeta de Bienvenida y Perfil ─────────────────
                  _buildUserCard(nombreUsuario, roles, isDark),
                  const SizedBox(height: SIAASpacing.lg),

                  // ─── Módulo Principal: Levantamiento Cartográfico ───
                  _buildCartografiaCard(context, isDark),
                  const SizedBox(height: SIAASpacing.lg),

                  // ─── Módulos Operativos Secundarios ─────────────────
                  _buildModulosSecundarios(isDark),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(String nombre, List<String> roles, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(SIAASpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: SIAAColors.primary500.withOpacity(0.15),
            child: Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: SIAAColors.primary600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: roles.map((r) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: SIAAColors.primary50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: SIAAColors.primary700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartografiaCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(SIAASpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
              : [const Color(0xFFEFF6FF), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SIAAColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SIAAColors.primary500,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Cartografía y Espacios',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Levantamiento perimetral y toque en mapa (US-GEO-02 / 03)',
                      style: TextStyle(fontSize: 12, color: SIAAColors.neutral500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _codigoEspacioController,
                  decoration: const InputDecoration(
                    labelText: 'Código Aula',
                    hintText: 'AULA-101',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _nombreEspacioController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Espacio',
                    hintText: 'Aula Magistral 101',
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: SIAAColors.primary500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.explore_outlined, size: 20),
              label: const Text('Iniciar Editor Cartográfico', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: _abrirGeoEditor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulosSecundarios(bool isDark) {
    return Column(
      children: [
        _buildFeatureTile(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Marcaje de Asistencia',
          subtitle: 'Validación por geocerca y token de sesión (Próximamente)',
          enabled: false,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildFeatureTile(
          icon: Icons.history_rounded,
          title: 'Historial de Asistencia',
          subtitle: 'Registros y justificaciones de clase',
          enabled: false,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SIAAColors.neutral200),
      ),
      child: Row(
        children: [
          Icon(icon, color: enabled ? SIAAColors.primary500 : SIAAColors.neutral400, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: enabled ? null : SIAAColors.neutral500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: SIAAColors.neutral400),
                ),
              ],
            ),
          ),
          if (!enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: SIAAColors.neutral100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Pronto', style: TextStyle(fontSize: 10, color: SIAAColors.neutral600)),
            ),
        ],
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dlgContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Está seguro de que desea salir del sistema SIAA?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: SIAAColors.asistenciaAusente),
            onPressed: () {
              Navigator.of(dlgContext).pop();
              context.read<AuthBloc>().add(AuthLogoutRequested());
            },
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
