package impl

import (
	"go.mongodb.org/mongo-driver/bson"

	"github.com/siaa/backend/internal/repository"
)

// criteriosReporte agrega el rango de fechas, la facultad y las asignaturas del filtro.
func criteriosReporte(filter repository.SesionFilter) bson.D {
	var d bson.D
	rango := bson.M{}
	if filter.FechaDesde != "" {
		rango["$gte"] = filter.FechaDesde
	}
	if filter.FechaHasta != "" {
		rango["$lte"] = filter.FechaHasta
	}
	if len(rango) > 0 {
		d = append(d, bson.E{Key: "fecha", Value: rango})
	}
	if filter.FacultadID != "" {
		d = append(d, bson.E{Key: "facultadId", Value: filter.FacultadID})
	}
	if filter.AsignaturaIDs != nil {
		d = append(d, bson.E{Key: "asignaturaId", Value: bson.M{"$in": filter.AsignaturaIDs}})
	}
	return d
}
