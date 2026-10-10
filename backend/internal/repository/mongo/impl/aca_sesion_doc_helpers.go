package impl

import (
	"time"

	"github.com/siaa/backend/internal/domain/academico"
	"github.com/siaa/backend/internal/domain/geo"
)

// ventanaEstDoc persiste la ventana de marcaje estudiantil de la sesión (US-MAR-13).
type ventanaEstDoc struct {
	Abierta   bool      `bson:"abierta"`
	AbiertaEn time.Time `bson:"abiertaEn"`
	CierraEn  time.Time `bson:"cierraEn"`
}

func ventanaEstDeDominio(v *academico.VentanaEstudiantil) *ventanaEstDoc {
	if v == nil {
		return nil
	}
	return &ventanaEstDoc{Abierta: v.Abierta, AbiertaEn: v.AbiertaEn, CierraEn: v.CierraEn}
}

func (d *ventanaEstDoc) dominio() *academico.VentanaEstudiantil {
	if d == nil {
		return nil
	}
	return &academico.VentanaEstudiantil{Abierta: d.Abierta, AbiertaEn: d.AbiertaEn, CierraEn: d.CierraEn}
}

// poligonoDeDoc reconstruye un polígono guardado como GeoJSON (nil si no es válido).
func poligonoDeDoc(doc *geoJSONPolygonDoc) *geo.GeoPolygon {
	if doc == nil || len(doc.Coordinates) == 0 {
		return nil
	}
	verts := make([]geo.GeoPoint, 0, len(doc.Coordinates[0]))
	for _, c := range doc.Coordinates[0] {
		if pt, err := geo.NewGeoPoint(c[0], c[1]); err == nil {
			verts = append(verts, pt)
		}
	}
	poly, err := geo.NewGeoPolygon(verts)
	if err != nil {
		return nil
	}
	return &poly
}

// ranuraDoc guarda la fecha y hora generadas de una sesión reprogramada (US-ACA-06).
type ranuraDoc struct {
	Fecha      string `bson:"fecha"`
	HoraInicio string `bson:"horaInicio"`
}

func ranuraDeDominio(r *academico.RanuraOriginal) *ranuraDoc {
	if r == nil {
		return nil
	}
	return &ranuraDoc{Fecha: r.Fecha, HoraInicio: r.HoraInicio}
}

func (d *ranuraDoc) dominio() *academico.RanuraOriginal {
	if d == nil {
		return nil
	}
	return &academico.RanuraOriginal{Fecha: d.Fecha, HoraInicio: d.HoraInicio}
}
