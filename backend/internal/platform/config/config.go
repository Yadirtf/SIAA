// Package config centraliza la configuración del servicio.
// Se carga desde variables de entorno. El servicio NO arranca si falta una variable obligatoria.
// T-PLT-01.2
package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Config contiene toda la configuración del servicio.
type Config struct {
	// Servidor
	Port    string
	Env     string // development | production | test
	Version string
	Commit  string

	// MongoDB
	MongoURI string
	MongoDB  string

	// JWT
	JWTSecret        string
	JWTAccessMinutes int
	JWTRefreshDays   int
	JWTIssuer        string

	// Seguridad
	BcryptCost         int
	RateLimitPerMinute int
	// AuthRateLimitPerMinute limita /auth por IP (US-AUT-02 AC-03); por defecto 20.
	AuthRateLimitPerMinute int
	// ImportacionUmbralErroresPct: % de filas con error que aún permite aplicar una carga (US-ACA-07 AC-03).
	ImportacionUmbralErroresPct float64
	FailedLoginMax              int
	FailedLoginWindowMin        int
	LockoutDurationMin          int
	AllowedEmailDomains         []string
	CORSAllowedOrigins          []string

	// Correo
	SMTPHost string
	SMTPPort int
	SMTPUser string
	SMTPPass string
	SMTPFrom string

	// Recuperación de contraseña
	RecoveryTokenMinutes int
	RecoveryURL          string

	// Superadministrador de arranque (solo se crea si no existe)
	AdminInicialCorreo   string
	AdminInicialPassword string
	PasswordMinLength    int

	// Justificaciones (EP-07): plazo en días hábiles y secreto de cifrado de los soportes
	// (si se omite se deriva de JWT_SECRET).
	JustificacionPlazoDias int
	AdjuntosClave          string

	// Play Integrity: paquete de la app Android y JSON de la cuenta de servicio con permiso
	// para descifrar tokens. Sin ambos, ningún marcaje tiene attestation válida.
	PlayIntegrityPaquete      string
	PlayIntegrityCredenciales string

	// Notificaciones (EP-10) y privacidad (Ley 1581)
	FCMProyecto          string
	FCMCredenciales      string
	NotifSilencioInicio  string
	NotifSilencioFin     string
	NotifRecordatorioMin int
	NotifCierreMin       int
	// NotifRevisionHoras es el plazo tras el que se recuerda al revisor una justificación (US-JUS-04).
	NotifRevisionHoras int
	InstitucionNombre  string
	PrivacidadContacto string

	// Parámetros GPS por defecto — SRS §3.5
	DefaultHolguraEntradaAntesMin   int
	DefaultHolguraEntradaDespuesMin int
	DefaultUmbralTardanzaMin        int
	DefaultPrecisionGPSMaxMetros    float64
	DefaultBufferPerimetralMetros   float64
}

// Load carga la configuración desde el entorno.
// Falla con error descriptivo si falta cualquier variable obligatoria.
func Load() (*Config, error) {
	cfg := &Config{}
	var errs []string

	// Servidor
	cfg.Port = getEnv("PORT", "8080")
	cfg.Env = getEnv("APP_ENV", "development")
	cfg.Version = getEnv("APP_VERSION", "0.0.1-dev")
	cfg.Commit = getEnv("APP_COMMIT", "local")

	// MongoDB — obligatorio
	cfg.MongoURI = requireEnv("MONGO_URI", &errs)
	cfg.MongoDB = getEnv("MONGO_DB", "siaa")

	// JWT — obligatorio
	cfg.JWTSecret = requireEnv("JWT_SECRET", &errs)
	cfg.JWTIssuer = getEnv("JWT_ISSUER", "siaa")
	cfg.JWTAccessMinutes = getEnvInt("JWT_ACCESS_MINUTES", 15)
	cfg.JWTRefreshDays = getEnvInt("JWT_REFRESH_DAYS", 30)

	// Seguridad
	cfg.BcryptCost = getEnvInt("BCRYPT_COST", 12)
	cfg.RateLimitPerMinute = getEnvInt("RATE_LIMIT_PER_MINUTE", 120)
	cfg.AuthRateLimitPerMinute = getEnvInt("AUTH_RATE_LIMIT_PER_MINUTE", 20)
	cfg.ImportacionUmbralErroresPct = float64(getEnvInt("IMPORTACION_UMBRAL_ERRORES_PCT", 5))
	cfg.FailedLoginMax = getEnvInt("FAILED_LOGIN_MAX", 5)
	cfg.FailedLoginWindowMin = getEnvInt("FAILED_LOGIN_WINDOW_MIN", 15)
	cfg.LockoutDurationMin = getEnvInt("LOCKOUT_DURATION_MIN", 15)

	domains := getEnv("ALLOWED_EMAIL_DOMAINS", "")
	if domains != "" {
		cfg.AllowedEmailDomains = strings.Split(domains, ",")
	}

	corsOrigins := getEnv("CORS_ALLOWED_ORIGINS", "")
	if corsOrigins != "" {
		cfg.CORSAllowedOrigins = strings.Split(corsOrigins, ",")
	} else if cfg.Env != "production" {
		cfg.CORSAllowedOrigins = []string{"*"}
	} else {
		cfg.CORSAllowedOrigins = []string{"https://*.siaa.edu.co"}
	}

	// Correo
	cfg.SMTPHost = getEnv("SMTP_HOST", "")
	cfg.SMTPPort = getEnvInt("SMTP_PORT", 587)
	cfg.SMTPUser = getEnv("SMTP_USER", "")
	cfg.SMTPPass = getEnv("SMTP_PASS", "")
	cfg.SMTPFrom = getEnv("SMTP_FROM", "noreply@siaa.edu.co")

	// Recuperación
	cfg.RecoveryTokenMinutes = getEnvInt("RECOVERY_TOKEN_MINUTES", 30)
	cfg.RecoveryURL = getEnv("RECOVERY_URL", "")
	cfg.AdminInicialCorreo = getEnv("ADMIN_INICIAL_CORREO", "")
	cfg.AdminInicialPassword = getEnv("ADMIN_INICIAL_PASSWORD", "")
	cfg.PasswordMinLength = getEnvInt("PASSWORD_MIN_LENGTH", 12)
	cfg.JustificacionPlazoDias = getEnvInt("JUSTIFICACION_PLAZO_DIAS", 5)
	cfg.AdjuntosClave = getEnv("ADJUNTOS_CLAVE", "")
	cfg.PlayIntegrityPaquete = getEnv("PLAY_INTEGRITY_PACKAGE", "")
	cfg.PlayIntegrityCredenciales = getEnv("PLAY_INTEGRITY_CREDENTIALS", "")
	cfg.FCMProyecto = getEnv("FCM_PROJECT_ID", "")
	cfg.FCMCredenciales = getEnv("FCM_CREDENTIALS", "")
	cfg.NotifSilencioInicio = getEnv("NOTIF_SILENCIO_INICIO", "22:00")
	cfg.NotifSilencioFin = getEnv("NOTIF_SILENCIO_FIN", "06:00")
	cfg.NotifRecordatorioMin = getEnvInt("NOTIF_RECORDATORIO_MIN", 15)
	cfg.NotifCierreMin = getEnvInt("NOTIF_CIERRE_MIN", 5)
	cfg.NotifRevisionHoras = getEnvInt("NOTIF_REVISION_JUSTIFICACION_HORAS", 48)
	cfg.InstitucionNombre = getEnv("INSTITUCION_NOMBRE", "")
	cfg.PrivacidadContacto = getEnv("PRIVACIDAD_CONTACTO", "")

	// Parámetros GPS por defecto
	cfg.DefaultHolguraEntradaAntesMin = getEnvInt("DEFAULT_HOLGURA_ENTRADA_ANTES", 15)
	cfg.DefaultHolguraEntradaDespuesMin = getEnvInt("DEFAULT_HOLGURA_ENTRADA_DESPUES", 15)
	cfg.DefaultUmbralTardanzaMin = getEnvInt("DEFAULT_UMBRAL_TARDANZA", 10)
	cfg.DefaultPrecisionGPSMaxMetros = getEnvFloat("DEFAULT_PRECISION_GPS_MAX", 35.0)
	cfg.DefaultBufferPerimetralMetros = getEnvFloat("DEFAULT_BUFFER_PERIMETRAL", 10.0)

	if len(errs) > 0 {
		return nil, fmt.Errorf("variables de entorno obligatorias faltantes: %s", strings.Join(errs, ", "))
	}
	return cfg, nil
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func requireEnv(key string, errs *[]string) string {
	v := os.Getenv(key)
	if v == "" {
		*errs = append(*errs, key)
	}
	return v
}

func getEnvInt(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return fallback
}

func getEnvFloat(key string, fallback float64) float64 {
	if v := os.Getenv(key); v != "" {
		if f, err := strconv.ParseFloat(v, 64); err == nil {
			return f
		}
	}
	return fallback
}
