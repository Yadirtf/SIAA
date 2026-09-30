// rol_slug.dart — Traducción entre los nombres de rol del backend y los slugs de la
// matriz de navegación (RF-ROL-001). El backend usa DOCENTE, ADMIN_INSTITUCIONAL, etc.

const _slugPorRolBackend = {
  'SUPERADMIN': 'superadmin',
  'ADMIN_INSTITUCIONAL': 'admin',
  'ADMIN': 'admin',
  'COORDINADOR': 'coordinador',
  'DOCENTE': 'docente',
  'ESTUDIANTE': 'estudiante',
  'MONITOR': 'monitor',
  'AUDITOR': 'auditor',
};

const _etiquetaPorSlug = {
  'superadmin': 'Superadministrador',
  'admin': 'Administrador',
  'coordinador': 'Coordinador',
  'docente': 'Docente',
  'estudiante': 'Estudiante',
  'monitor': 'Monitor / Auxiliar',
  'auditor': 'Auditor',
};

/// Slug de navegación para un rol del backend ("ADMIN_INSTITUCIONAL" → "admin").
/// Un slug ya normalizado se devuelve igual.
String rolSlugDe(String rol) {
  final r = rol.trim();
  return _slugPorRolBackend[r.toUpperCase()] ?? r.toLowerCase();
}

/// Nombre del rol que espera el backend (POST /auth/contexto) para un rol o slug.
String rolBackendDe(String rolOSlug, {List<String> disponibles = const []}) {
  final slug = rolSlugDe(rolOSlug);
  for (final r in disponibles) {
    if (rolSlugDe(r) == slug) return r;
  }
  if (slug == 'admin') return 'ADMIN_INSTITUCIONAL';
  return slug.toUpperCase();
}

/// Etiqueta legible de un rol del backend o slug ("DOCENTE" → "Docente").
String etiquetaRol(String rol) => _etiquetaPorSlug[rolSlugDe(rol)] ?? rol;
