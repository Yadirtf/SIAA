package shared

import "github.com/google/uuid"

// NewID genera un identificador único de aplicación.
// Se usa UUID v4. No expone el implementación al dominio.
func NewID() string {
	return uuid.New().String()
}

// NewInstallationID genera un UUID estable para identificar una instalación de app.
// Equivalente al "identificador de instalación" del SRS (no IMEI, no ad ID).
func NewInstallationID() string {
	return uuid.New().String()
}
