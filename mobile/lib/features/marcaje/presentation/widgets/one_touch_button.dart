// one_touch_button.dart — Botón de marcaje de un solo toque con protección de doble tap (US-MAR-01, US-MAR-05)
import 'package:flutter/material.dart';

class OneTouchButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isSubmitting;
  final bool isEnabled;
  final String label;
  final IconData icon;

  const OneTouchButton({
    super.key,
    required this.onPressed,
    this.isSubmitting = false,
    this.isEnabled = true,
    this.label = 'MARCAR ASISTENCIA',
    this.icon = Icons.touch_app_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final canPress = isEnabled && !isSubmitting && onPressed != null;

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: canPress
              ? const RadialGradient(
                  colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                )
              : RadialGradient(
                  colors: [Colors.grey.shade400, Colors.grey.shade600],
                ),
          boxShadow: canPress
              ? [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: canPress ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSubmitting)
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3.5,
                      ),
                    )
                  else ...[
                    Icon(icon, size: 54, color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
