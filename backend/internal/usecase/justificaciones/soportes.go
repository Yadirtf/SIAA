package justificaciones

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/http"
	"path/filepath"
	"strings"

	"go.mongodb.org/mongo-driver/bson/primitive"

	"github.com/siaa/backend/internal/domain/justificacion"
	"github.com/siaa/backend/internal/domain/shared"
)

// Límites de los soportes (RF-JUS-001: imagen o PDF).
const (
	MaxBytesSoporte = 10 << 20
	MaxSoportes     = 3
)

var mimesPermitidos = map[string]bool{
	"image/jpeg":      true,
	"image/png":       true,
	"application/pdf": true,
}

// Archivo es un soporte recibido del cliente.
type Archivo struct {
	Nombre    string
	Contenido []byte
}

// validarSoportes comprueba cantidad, tamaño y tipo real (por contenido, no por extensión).
func validarSoportes(archivos []Archivo) ([]justificacion.Adjunto, error) {
	if len(archivos) == 0 {
		return nil, shared.NewValidationError(justificacion.ErrSinSoporte.Error())
	}
	if len(archivos) > MaxSoportes {
		return nil, shared.NewValidationError(fmt.Sprintf("se admiten máximo %d soportes", MaxSoportes))
	}
	adjuntos := make([]justificacion.Adjunto, 0, len(archivos))
	for _, a := range archivos {
		if len(a.Contenido) == 0 || len(a.Contenido) > MaxBytesSoporte {
			return nil, shared.NewValidationError(fmt.Sprintf("el soporte %q debe pesar entre 1 byte y 10 MB", a.Nombre))
		}
		mime := strings.SplitN(http.DetectContentType(a.Contenido), ";", 2)[0]
		if !mimesPermitidos[mime] {
			return nil, shared.NewValidationError(fmt.Sprintf("el soporte %q debe ser JPG, PNG o PDF", a.Nombre))
		}
		suma := sha256.Sum256(a.Contenido)
		adjuntos = append(adjuntos, justificacion.Adjunto{
			ID:     primitive.NewObjectID().Hex(),
			Nombre: nombreSeguro(a.Nombre),
			Mime:   mime,
			Tamano: int64(len(a.Contenido)),
			SHA256: hex.EncodeToString(suma[:]),
		})
	}
	return adjuntos, nil
}

// nombreSeguro descarta rutas y caracteres de control del nombre original.
func nombreSeguro(nombre string) string {
	nombre = filepath.Base(strings.ReplaceAll(nombre, "\\", "/"))
	nombre = strings.Map(func(r rune) rune {
		if r < 32 || r == '"' {
			return -1
		}
		return r
	}, nombre)
	if nombre == "" || nombre == "." || nombre == "/" {
		return "soporte"
	}
	return nombre
}

// SoporteDescargado es el contenido descifrado de un soporte con sus metadatos.
type SoporteDescargado struct {
	Adjunto   justificacion.Adjunto
	Contenido []byte
}

// ObtenerSoporte devuelve el soporte si la justificación es visible para el actor.
func (s *Service) ObtenerSoporte(ctx context.Context, actor Actor, id, adjuntoID string) (*SoporteDescargado, error) {
	j, err := s.Obtener(ctx, actor, id)
	if err != nil {
		return nil, err
	}
	for _, a := range j.Adjuntos {
		if a.ID != adjuntoID {
			continue
		}
		contenido, err := s.adjuntos.Obtener(ctx, a.ID)
		if err != nil {
			return nil, err
		}
		if contenido == nil {
			break
		}
		return &SoporteDescargado{Adjunto: a, Contenido: contenido}, nil
	}
	return nil, shared.NewNotFoundError("soporte", adjuntoID)
}
