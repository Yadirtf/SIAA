import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../models/nav_item.dart';

class DashboardHomeScreen extends StatelessWidget {
  final ValueChanged<NavSection> onNavigate;

  const DashboardHomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroBanner(),
          const SizedBox(height: 28),
          Text('Módulos de Gestión', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          _buildModuleGrid(context),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentCyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'SIAA PLATFORM v1.0',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentCyan,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Bienvenido al Sistema de Asignación Académica',
                  style: AppTextStyles.h1.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gestión integral de infraestructura geoespacial, periodos lectivos, mallas curriculares y asignación de aulas.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_rounded,
              color: Colors.white70,
              size: 56,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    final modules = [
      _ModuleCard(
        title: 'Sedes y Campi',
        description: 'Administración de sedes universitarias y ubicaciones.',
        icon: Icons.domain_rounded,
        color: AppColors.primaryAccent,
        onTap: () => onNavigate(NavSection.sedes),
      ),
      _ModuleCard(
        title: 'Bloques y Edificios',
        description: 'Gestión de bloques físicos y niveles/pisos.',
        icon: Icons.apartment_rounded,
        color: AppColors.accentCyan,
        onTap: () => onNavigate(NavSection.bloques),
      ),
      _ModuleCard(
        title: 'Espacios y Aulas',
        description: 'Aulas, laboratorios y recintos con soporte GIS y capacidad.',
        icon: Icons.meeting_room_outlined,
        color: AppColors.accentEmerald,
        onTap: () => onNavigate(NavSection.espacios),
      ),
      _ModuleCard(
        title: 'Control Solapamientos',
        description: 'Validación topológica geoespacial y prevención de colisiones.',
        icon: Icons.layers_outlined,
        color: AppColors.accentAmber,
        onTap: () => onNavigate(NavSection.solapamientos),
      ),
      _ModuleCard(
        title: 'Periodos Académicos',
        description: 'Ciclos lectivos, fechas operativas y estados de planeación.',
        icon: Icons.calendar_month_outlined,
        color: AppColors.primaryLight,
        onTap: () => onNavigate(NavSection.periodos),
      ),
      _ModuleCard(
        title: 'Estructura Curricular',
        description: 'Facultades, programas, asignaturas y grupos semestrales.',
        icon: Icons.account_tree_outlined,
        color: const Color(0xFF6366F1), // Indigo
        onTap: () => onNavigate(NavSection.estructura),
      ),
      _ModuleCard(
        title: 'Asignaciones Horarias',
        description: 'Vinculación de grupos, docentes, franjas y espacios físicos.',
        icon: Icons.schedule_rounded,
        color: const Color(0xFF8B5CF6), // Violet
        onTap: () => onNavigate(NavSection.asignaciones),
      ),
      _ModuleCard(
        title: 'Calendario y Excepciones',
        description: 'Feriados, recesos académicos y jornadas institucionales.',
        icon: Icons.event_busy_outlined,
        color: AppColors.accentRose,
        onTap: () => onNavigate(NavSection.excepciones),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 640) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 960) {
          crossAxisCount = 2;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 150,
          ),
          itemCount: modules.length,
          itemBuilder: (context, index) => modules[index],
        );
      },
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                ],
              ),
              const Spacer(),
              Text(title, style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
