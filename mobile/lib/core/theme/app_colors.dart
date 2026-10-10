// Paleta de colores SIAA — T-PLT-03.2. SRS §9.3: colores semánticos reservados a estados de asistencia.
import 'package:flutter/material.dart';

class SIAAColors {
  SIAAColors._();

  // ─── Primario (azul institucional) ─────────────────────────
  static const primary50 = Color(0xFFE8F0FE);
  static const primary100 = Color(0xFFC5D8FD);
  static const primary200 = Color(0xFF9DBBFB);
  static const primary300 = Color(0xFF759EFA);
  static const primary400 = Color(0xFF5686F9);
  static const primary500 = Color(0xFF2563EB); // Primary brand
  static const primary600 = Color(0xFF1D55D3);
  static const primary700 = Color(0xFF1445B5);
  static const primary800 = Color(0xFF0C3696);
  static const primary900 = Color(0xFF052070);

  // ─── Neutros ────────────────────────────────────────────────
  static const neutral50 = Color(0xFFF8FAFC);
  static const neutral100 = Color(0xFFF1F5F9);
  static const neutral200 = Color(0xFFE2E8F0);
  static const neutral300 = Color(0xFFCBD5E1);
  static const neutral400 = Color(0xFF94A3B8);
  static const neutral500 = Color(0xFF64748B);
  static const neutral600 = Color(0xFF475569);
  static const neutral700 = Color(0xFF334155);
  static const neutral800 = Color(0xFF1E293B);
  static const neutral900 = Color(0xFF0F172A);

  // ─── Semánticos de asistencia — SRS §9.3 ───────────────────
  // REGLA: Estos colores NO se usan para nada que no sea estado de asistencia.
  static const asistenciaPresente = Color(0xFF16A34A); // Verde — Presente
  static const asistenciaTardanza = Color(0xFFD97706); // Ámbar — Tardanza
  static const asistenciaAusente = Color(0xFFDC2626); // Rojo  — Ausente
  static const asistenciaJustificada = Color(0xFF0284C7); // Azul — Justificada

  // ─── Semáforo GPS — SRS §9.1 ────────────────────────────────
  static const gpsExcelente = Color(0xFF16A34A); // ≤ 10m
  static const gpsAceptable = Color(0xFFD97706); // 10-25m
  static const gpsInsuficiente = Color(0xFFDC2626); // > 25m
  static const gpsBuscando = Color(0xFF64748B); // Buscando señal

  // ─── Superficie y fondo ─────────────────────────────────────
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E293B);
  static const backgroundLight = Color(0xFFF8FAFC);
  static const backgroundDark = Color(0xFF0F172A);

  // ─── Acento ─────────────────────────────────────────────────
  static const accent = Color(0xFF7C3AED); // Violeta
}
