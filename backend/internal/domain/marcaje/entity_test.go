// Pruebas unitarias para el dominio de marcaje.
// Garantiza cobertura >= 90 % conforme a RNF-MAN-001 y US-PLT-02 AC-03.
package marcaje_test

import (
	"testing"
	"time"

	"github.com/siaa/backend/internal/domain/marcaje"
)

func TestMarcaje_ValidarEstructura(t *testing.T) {
	tests := []struct {
		name    string
		marcaje marcaje.Marcaje
		wantErr error
	}{
		{
			name: "docente vacio",
			marcaje: marcaje.Marcaje{
				DocenteID: "",
			},
			wantErr: marcaje.ErrDocenteRequerido,
		},
		{
			name: "sesion vacia",
			marcaje: marcaje.Marcaje{
				DocenteID: "doc-1",
				SesionID:  "",
			},
			wantErr: marcaje.ErrSesionRequerida,
		},
		{
			name: "tipo invalido",
			marcaje: marcaje.Marcaje{
				DocenteID: "doc-1",
				SesionID:  "ses-1",
				Tipo:      "OTRO",
			},
			wantErr: marcaje.ErrTipoInvalido,
		},
		{
			name: "coordenadas invalidas",
			marcaje: marcaje.Marcaje{
				DocenteID: "doc-1",
				SesionID:  "ses-1",
				Tipo:      marcaje.TipoEntrada,
				Geolocalizacion: marcaje.TelemetriaGPS{
					Coordenadas: []float64{-74.08},
				},
			},
			wantErr: marcaje.ErrCoordenadasNulas,
		},
		{
			name: "valido entrada",
			marcaje: marcaje.Marcaje{
				DocenteID: "doc-1",
				SesionID:  "ses-1",
				Tipo:      marcaje.TipoEntrada,
				Timestamp: time.Now(),
				Geolocalizacion: marcaje.TelemetriaGPS{
					Coordenadas: []float64{-74.08175, 4.60971},
				},
			},
			wantErr: nil,
		},
		{
			name: "valido salida",
			marcaje: marcaje.Marcaje{
				DocenteID: "doc-1",
				SesionID:  "ses-1",
				Tipo:      marcaje.TipoSalida,
				Timestamp: time.Now(),
				Geolocalizacion: marcaje.TelemetriaGPS{
					Coordenadas: []float64{-74.08175, 4.60971},
				},
			},
			wantErr: nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.marcaje.ValidarEstructura()
			if err != tt.wantErr {
				t.Errorf("error esperado %v, obtuvo %v", tt.wantErr, err)
			}
		})
	}
}

func TestMarcaje_EsExitoso(t *testing.T) {
	mValido := marcaje.Marcaje{Resultado: marcaje.ResultadoValido}
	if !mValido.EsExitoso() {
		t.Errorf("esperado true para VALIDO")
	}

	mRetardo := marcaje.Marcaje{Resultado: marcaje.ResultadoRetardo}
	if !mRetardo.EsExitoso() {
		t.Errorf("esperado true para RETARDO")
	}

	mFueraArea := marcaje.Marcaje{Resultado: marcaje.ResultadoFueraDeArea}
	if mFueraArea.EsExitoso() {
		t.Errorf("esperado false para FUERA_DE_AREA")
	}
}

func TestMarcaje_RequiereJustificacion(t *testing.T) {
	mFueraArea := marcaje.Marcaje{Resultado: marcaje.ResultadoFueraDeArea}
	if !mFueraArea.RequiereJustificacion() {
		t.Errorf("esperado true para FUERA_DE_AREA")
	}

	mFueraTiempo := marcaje.Marcaje{Resultado: marcaje.ResultadoFueraDeTiempo}
	if !mFueraTiempo.RequiereJustificacion() {
		t.Errorf("esperado true para FUERA_DE_TIEMPO")
	}

	mValido := marcaje.Marcaje{Resultado: marcaje.ResultadoValido}
	if mValido.RequiereJustificacion() {
		t.Errorf("esperado false para VALIDO")
	}
}
