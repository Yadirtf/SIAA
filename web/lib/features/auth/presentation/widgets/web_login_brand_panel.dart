import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class WebLoginBrandPanel extends StatelessWidget {
  const WebLoginBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
            Color(0xFF7C3AED),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SIAASpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: SIAASpacing.radiusMd,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: SIAASpacing.xl),

            const Text(
              'SIAA',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: SIAASpacing.sm),
            Text(
              'Consola Administrativa',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white.withOpacity(0.8),
                fontSize: 20,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: SIAASpacing.xxxl),

            // Features
            ..._buildFeatures(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatures() {
    final features = [
      (Icons.location_on_outlined, 'Validación por geolocalización GPS'),
      (Icons.map_outlined, 'Cartografía de espacios académicos'),
      (Icons.schedule_outlined, 'Gestión de horarios y sesiones'),
      (Icons.bar_chart_outlined, 'Reportes de cumplimiento docente'),
      (Icons.security_outlined, 'Auditoría completa e inmutable'),
    ];

    return features.map((f) => Padding(
      padding: const EdgeInsets.only(bottom: SIAASpacing.md),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: SIAASpacing.radiusSm,
            ),
            child: Icon(f.$1, color: Colors.white, size: 20),
          ),
          const SizedBox(width: SIAASpacing.md),
          Text(
            f.$2,
            style: TextStyle(
              fontFamily: 'Inter',
              color: Colors.white.withOpacity(0.85),
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    )).toList();
  }
}
